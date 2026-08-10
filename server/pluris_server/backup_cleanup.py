from collections.abc import Iterable

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from pluris_server.backup_storage import FilesystemBackupObjectStore
from pluris_server.models import BackupDeletion


def queue_backup_deletions(db: AsyncSession, *, owner_id: str, snapshot_ids: Iterable[str]) -> None:
    for snapshot_id in snapshot_ids:
        db.add(BackupDeletion(owner_id=owner_id, snapshot_id=snapshot_id))


async def sweep_backup_deletions(
    db: AsyncSession, object_store: FilesystemBackupObjectStore
) -> int:
    """Delete queued blobs after their owning database transaction committed."""
    deletions = (await db.scalars(select(BackupDeletion))).all()
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
