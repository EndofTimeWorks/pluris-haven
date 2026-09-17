import asyncio
import hashlib
from collections.abc import Iterable
from datetime import UTC, datetime, timedelta

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from pluris_server.backup_storage import FilesystemBackupObjectStore
from pluris_server.models import BackupChunk, BackupDeletion, BackupSnapshot


async def reconcile_legacy_backup_chunks(
    db: AsyncSession,
    object_store: FilesystemBackupObjectStore,
    *,
    batch_size: int = 100,
) -> int:
    """Only mark legacy chunks durable after validating stored bytes.

    Missing and corrupt blobs deliberately remain pending for a normal retry;
    a database row alone must never make them downloadable or complete.
    """
    if batch_size < 1:
        raise ValueError("batch_size must be positive")
    rows = (
        await db.execute(
            select(BackupChunk, BackupSnapshot)
            .join(BackupSnapshot, BackupSnapshot.id == BackupChunk.snapshot_id)
            .where(BackupChunk.stored_at.is_(None))
            .order_by(
                BackupChunk.reconciliation_checked_at.asc().nullsfirst(),
                BackupChunk.id.asc(),
            )
            .limit(batch_size)
        )
    ).all()
    reconciled = 0
    checked_at = datetime.now(UTC)
    for chunk, snapshot in rows:
        chunk.reconciliation_checked_at = checked_at
        if chunk.index < 0 or chunk.index >= snapshot.chunk_count:
            continue
        try:
            valid = await asyncio.to_thread(
                _validate_stored_chunk,
                object_store,
                snapshot.user_id,
                snapshot.snapshot_id,
                chunk.index,
                chunk.size,
                chunk.sha256,
            )
        except FileNotFoundError:
            continue
        if not valid:
            continue
        chunk.stored_at = checked_at
        reconciled += 1
    if rows:
        await db.commit()
    return reconciled


def _validate_stored_chunk(
    object_store: FilesystemBackupObjectStore,
    owner_id: str,
    snapshot_id: str,
    index: int,
    expected_size: int,
    expected_sha256: str,
) -> bool:
    content = object_store.read_chunk(
        owner_id=owner_id,
        snapshot_id=snapshot_id,
        index=index,
    )
    return len(content) == expected_size and hashlib.sha256(content).hexdigest() == expected_sha256


def queue_backup_deletions(db: AsyncSession, *, owner_id: str, snapshot_ids: Iterable[str]) -> None:
    for snapshot_id in snapshot_ids:
        db.add(BackupDeletion(owner_id=owner_id, snapshot_id=snapshot_id))


async def sweep_backup_deletions(
    db: AsyncSession,
    object_store: FilesystemBackupObjectStore,
    *,
    owner_id: str | None = None,
) -> int:
    """Delete queued blobs after their owning database transaction committed."""
    statement = select(BackupDeletion)
    if owner_id is not None:
        statement = statement.where(BackupDeletion.owner_id == owner_id)
    deletions = (await db.scalars(statement)).all()
    completed = 0
    for deletion in deletions:
        try:
            object_store.delete_snapshot(
                owner_id=deletion.owner_id,
                snapshot_id=deletion.snapshot_id,
            )
        except OSError:
            continue
        await db.delete(deletion)
        completed += 1
    await db.commit()
    return completed


async def sweep_incomplete_backup_snapshots(
    db: AsyncSession,
    object_store: FilesystemBackupObjectStore,
    *,
    ttl_seconds: int,
    now: datetime | None = None,
) -> int:
    """Expire stale upload reservations that never received a complete snapshot."""
    cutoff = (now or datetime.now(UTC)) - timedelta(seconds=ttl_seconds)
    uploaded_chunks = func.count(BackupChunk.id).filter(BackupChunk.stored_at.is_not(None))
    uploaded_bytes = func.coalesce(
        func.sum(BackupChunk.size).filter(BackupChunk.stored_at.is_not(None)), 0
    )
    snapshots = (
        await db.scalars(
            select(BackupSnapshot)
            .outerjoin(BackupChunk, BackupChunk.snapshot_id == BackupSnapshot.id)
            .where(BackupSnapshot.upload_started_at <= cutoff)
            .group_by(BackupSnapshot.id)
            .having(
                or_(
                    uploaded_chunks != BackupSnapshot.chunk_count,
                    uploaded_bytes != BackupSnapshot.total_bytes,
                )
            )
        )
    ).all()
    for snapshot in snapshots:
        queue_backup_deletions(
            db,
            owner_id=snapshot.user_id,
            snapshot_ids=[snapshot.snapshot_id],
        )
        await db.delete(snapshot)
    await db.commit()
    for snapshot in snapshots:
        await sweep_backup_deletions(db, object_store, owner_id=snapshot.user_id)
    return len(snapshots)
