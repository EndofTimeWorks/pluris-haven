from collections.abc import Iterable

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from pluris_server.backup_storage import FilesystemBackupObjectStore
from pluris_server.models import BackupDeletion


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
