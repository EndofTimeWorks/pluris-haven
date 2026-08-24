from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from pluris_server.backup_cleanup import queue_backup_deletions, sweep_backup_deletions
from pluris_server.backup_storage import FilesystemBackupObjectStore
from pluris_server.models import BackupSnapshot, SecurityEvent, SecurityEventType, User


async def sweep_deleted_accounts(
    db: AsyncSession, store: FilesystemBackupObjectStore, *, now: datetime | None = None
) -> int:
    now = now or datetime.now(UTC)
    candidates = (
        await db.scalars(
            select(User).where(User.disabled.is_(True), User.deletion_purge_after.is_not(None))
        )
    ).all()
    users = []
    for user in candidates:
        purge_after = user.deletion_purge_after
        if purge_after is not None and purge_after.tzinfo is None:
            purge_after = purge_after.replace(tzinfo=UTC)
        if purge_after is not None and purge_after <= now:
            users.append(user)
    owner_ids = []
    for user in users:
        owner_id = user.id
        owner_ids.append(owner_id)
        snapshots = (
            await db.scalars(select(BackupSnapshot).where(BackupSnapshot.user_id == owner_id))
        ).all()
        queue_backup_deletions(
            db, owner_id=owner_id, snapshot_ids=[row.snapshot_id for row in snapshots]
        )
        db.add(
            SecurityEvent(
                user_id=owner_id,
                event_type=SecurityEventType.ACCOUNT_DELETED.value,
            )
        )
        await db.delete(user)
    await db.commit()
    for owner_id in owner_ids:
        await sweep_backup_deletions(db, store, owner_id=owner_id)
    return len(users)
