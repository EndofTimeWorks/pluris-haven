from collections.abc import Iterable
from datetime import UTC, datetime, timedelta

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from pluris_server.backup_storage import FilesystemBackupObjectStore
from pluris_server.models import BackupChunk, BackupDeletion, BackupSnapshot


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
    uploaded_chunks = func.count(BackupChunk.id)
    uploaded_bytes = func.coalesce(func.sum(BackupChunk.size), 0)
    snapshots = (
        await db.scalars(
            select(BackupSnapshot)
            .outerjoin(BackupChunk, BackupChunk.snapshot_id == BackupSnapshot.id)
            .where(BackupSnapshot.created_at <= cutoff)
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
