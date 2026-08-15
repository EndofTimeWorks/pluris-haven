import hashlib
from datetime import UTC, datetime

from fastapi import APIRouter, HTTPException, Request, Response, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError

from pluris_server.backup_cleanup import queue_backup_deletions, sweep_backup_deletions
from pluris_server.backup_storage import BackupChunkConflict, BackupChunkIntegrityError
from pluris_server.dependencies import AppSettings, CurrentAuth, Db
from pluris_server.models import BackupChunk, BackupSnapshot, SecurityEventType, User
from pluris_server.schemas import (
    BackupChunkView,
    BackupSnapshotCreate,
    BackupSnapshotView,
    MessageResponse,
)
from pluris_server.security_events import record_security_event

router = APIRouter(prefix="/v1/backups", tags=["backups"])


async def _read_limited_body(request: Request, maximum_bytes: int) -> bytes:
    content_length = request.headers.get("content-length")
    if content_length is not None:
        try:
            declared_length = int(content_length)
        except ValueError as error:
            raise HTTPException(status_code=400, detail="Invalid Content-Length header") from error
        if declared_length > maximum_bytes:
            raise HTTPException(status_code=413, detail="Backup chunk exceeds the server limit")

    content = bytearray()
    async for chunk in request.stream():
        if len(content) > maximum_bytes - len(chunk):
            raise HTTPException(status_code=413, detail="Backup chunk exceeds the server limit")
        content.extend(chunk)
    return bytes(content)


async def _snapshot_view(db: Db, snapshot: BackupSnapshot) -> BackupSnapshotView:
    result = await db.execute(
        select(
            func.count(BackupChunk.id),
            func.coalesce(func.sum(BackupChunk.size), 0),
        ).where(BackupChunk.snapshot_id == snapshot.id)
    )
    uploaded_chunks, uploaded_bytes = result.one()
    return BackupSnapshotView(
        snapshot_id=snapshot.snapshot_id,
        manifest_sha256=snapshot.manifest_sha256,
        chunk_count=snapshot.chunk_count,
        uploaded_chunks=int(uploaded_chunks),
        total_bytes=snapshot.total_bytes,
        uploaded_bytes=int(uploaded_bytes),
        created_at=snapshot.created_at,
    )


async def _get_snapshot(
    snapshot_id: str,
    auth: CurrentAuth,
    db: Db,
    *,
    for_update: bool = False,
) -> BackupSnapshot:
    query = select(BackupSnapshot).where(
        BackupSnapshot.user_id == auth.user.id,
        BackupSnapshot.snapshot_id == snapshot_id,
    )
    if for_update:
        query = query.with_for_update()
    snapshot = await db.scalar(query)
    if snapshot is None:
        raise HTTPException(status_code=404, detail="Backup snapshot not found")
    return snapshot


@router.post("/snapshots", response_model=BackupSnapshotView, status_code=status.HTTP_201_CREATED)
async def create_snapshot(
    payload: BackupSnapshotCreate,
    auth: CurrentAuth,
    db: Db,
    settings: AppSettings,
) -> BackupSnapshotView:
    # Lock the user row while reserving the snapshot's declared size. This
    # keeps concurrent snapshot creation from racing past the per-user quota.
    await db.scalar(select(User).where(User.id == auth.user.id).with_for_update())
    snapshot_count, reserved_bytes = (
        await db.execute(
            select(
                func.count(BackupSnapshot.id),
                func.coalesce(func.sum(BackupSnapshot.total_bytes), 0),
            ).where(BackupSnapshot.user_id == auth.user.id)
        )
    ).one()
    if int(snapshot_count) >= settings.backup_max_snapshots_per_user:
        raise HTTPException(
            status_code=413,
            detail="Backup snapshot limit reached for this account",
        )
    if int(reserved_bytes or 0) + payload.total_bytes > settings.backup_max_total_bytes_per_user:
        raise HTTPException(
            status_code=413,
            detail="Backup storage quota exceeded for this account",
        )
    created_at = payload.created_at or datetime.now(UTC)
    if created_at.tzinfo is None:
        created_at = created_at.replace(tzinfo=UTC)
    snapshot = BackupSnapshot(
        user_id=auth.user.id,
        snapshot_id=payload.snapshot_id,
        manifest_sha256=payload.manifest_sha256,
        chunk_count=payload.chunk_count,
        total_bytes=payload.total_bytes,
        created_at=created_at.astimezone(UTC),
    )
    db.add(snapshot)
    try:
        await db.commit()
    except IntegrityError as error:
        await db.rollback()
        raise HTTPException(status_code=409, detail="Backup snapshot already exists") from error
    return await _snapshot_view(db, snapshot)


@router.get("/snapshots", response_model=list[BackupSnapshotView])
async def list_snapshots(auth: CurrentAuth, db: Db) -> list[BackupSnapshotView]:
    rows = (
        await db.execute(
            select(
                BackupSnapshot,
                func.count(BackupChunk.id),
                func.coalesce(func.sum(BackupChunk.size), 0),
            )
            .outerjoin(BackupChunk, BackupChunk.snapshot_id == BackupSnapshot.id)
            .where(BackupSnapshot.user_id == auth.user.id)
            .group_by(BackupSnapshot.id)
            .order_by(BackupSnapshot.created_at.desc())
        )
    ).all()
    return [
        BackupSnapshotView(
            snapshot_id=snapshot.snapshot_id,
            manifest_sha256=snapshot.manifest_sha256,
            chunk_count=snapshot.chunk_count,
            uploaded_chunks=int(uploaded_chunks),
            total_bytes=snapshot.total_bytes,
            uploaded_bytes=int(uploaded_bytes),
            created_at=snapshot.created_at,
        )
        for snapshot, uploaded_chunks, uploaded_bytes in rows
    ]


@router.put(
    "/snapshots/{snapshot_id}/chunks/{index}",
    response_model=BackupChunkView,
)
async def put_chunk(
    snapshot_id: str,
    index: int,
    request: Request,
    auth: CurrentAuth,
    db: Db,
    settings: AppSettings,
) -> BackupChunkView:
    snapshot = await _get_snapshot(snapshot_id, auth, db, for_update=True)
    if index < 0 or index >= snapshot.chunk_count:
        raise HTTPException(status_code=422, detail="Backup chunk index is outside the manifest")
    content = await _read_limited_body(request, settings.backup_max_chunk_bytes)
    if not content:
        raise HTTPException(status_code=400, detail="Backup chunks must not be empty")
    supplied_digest = request.headers.get("X-Content-SHA256", "").strip().lower()
    digest = hashlib.sha256(content).hexdigest()
    if supplied_digest != digest:
        raise HTTPException(status_code=400, detail="Backup chunk digest does not match content")

    existing = await db.scalar(
        select(BackupChunk).where(
            BackupChunk.snapshot_id == snapshot.id, BackupChunk.index == index
        )
    )
    if existing is not None:
        if existing.sha256 != digest or existing.size != len(content):
            raise HTTPException(status_code=409, detail="Backup chunk key already exists")
        return BackupChunkView(
            snapshot_id=snapshot.snapshot_id,
            index=index,
            sha256=existing.sha256,
            size=existing.size,
        )

    uploaded_bytes = await db.scalar(
        select(func.coalesce(func.sum(BackupChunk.size), 0)).where(
            BackupChunk.snapshot_id == snapshot.id
        )
    )
    if int(uploaded_bytes or 0) + len(content) > snapshot.total_bytes:
        raise HTTPException(status_code=413, detail="Backup chunks exceed the snapshot manifest")

    try:
        request.app.state.backup_object_store.put_chunk(
            owner_id=auth.user.id,
            snapshot_id=snapshot.snapshot_id,
            index=index,
            ciphertext=content,
            sha256=digest,
        )
    except BackupChunkConflict as error:
        raise HTTPException(status_code=409, detail="Backup chunk key already exists") from error
    except BackupChunkIntegrityError as error:
        raise HTTPException(
            status_code=400, detail="Backup chunk integrity check failed"
        ) from error

    chunk = BackupChunk(snapshot_id=snapshot.id, index=index, sha256=digest, size=len(content))
    db.add(chunk)
    try:
        await db.commit()
    except IntegrityError as error:
        await db.rollback()
        raise HTTPException(status_code=409, detail="Backup chunk key already exists") from error
    return BackupChunkView(
        snapshot_id=snapshot.snapshot_id,
        index=index,
        sha256=digest,
        size=len(content),
    )


@router.get("/snapshots/{snapshot_id}/chunks/{index}")
async def get_chunk(
    snapshot_id: str, index: int, request: Request, auth: CurrentAuth, db: Db
) -> Response:
    snapshot = await _get_snapshot(snapshot_id, auth, db)
    chunk = await db.scalar(
        select(BackupChunk).where(
            BackupChunk.snapshot_id == snapshot.id, BackupChunk.index == index
        )
    )
    if chunk is None:
        raise HTTPException(status_code=404, detail="Backup chunk not found")
    try:
        content = request.app.state.backup_object_store.read_chunk(
            owner_id=auth.user.id,
            snapshot_id=snapshot.snapshot_id,
            index=index,
        )
    except FileNotFoundError as error:
        raise HTTPException(status_code=404, detail="Backup chunk is not available") from error
    if index == 0:
        record_security_event(
            db,
            user_id=auth.user.id,
            event_type=SecurityEventType.BACKUP_RECOVERY_STARTED,
        )
        await db.commit()
    return Response(
        content=content,
        media_type="application/octet-stream",
        headers={"X-Content-SHA256": chunk.sha256},
    )


@router.delete("/snapshots/{snapshot_id}", response_model=MessageResponse)
async def delete_snapshot(
    snapshot_id: str, request: Request, auth: CurrentAuth, db: Db
) -> MessageResponse:
    snapshot = await _get_snapshot(snapshot_id, auth, db)
    storage_snapshot_id = snapshot.snapshot_id
    queue_backup_deletions(
        db,
        owner_id=auth.user.id,
        snapshot_ids=[storage_snapshot_id],
    )
    await db.delete(snapshot)
    record_security_event(
        db,
        user_id=auth.user.id,
        event_type=SecurityEventType.BACKUP_DELETED,
    )
    await db.commit()
    await sweep_backup_deletions(db, request.app.state.backup_object_store)
    return MessageResponse(detail="Backup snapshot deleted")
