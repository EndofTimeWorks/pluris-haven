from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from pluris_server.models import SecurityEvent, SecurityEventType

MAX_SECURITY_EVENTS_PER_USER = 500
MAX_BACKUP_RECOVERY_EVENTS_PER_USER = 25


async def record_security_event(
    db: AsyncSession,
    *,
    user_id: str,
    event_type: SecurityEventType,
) -> None:
    """Append a bounded privacy-minimised event in the caller's transaction."""
    db.add(SecurityEvent(user_id=user_id, event_type=event_type.value))
    await db.flush()

    # Backup chunk zero can be fetched repeatedly. Keep those entries bounded
    # separately so downloads cannot evict password, session or deletion history.
    recovery_type = SecurityEventType.BACKUP_RECOVERY_STARTED.value
    is_recovery = SecurityEvent.event_type == recovery_type
    bucket = (
        is_recovery if event_type == SecurityEventType.BACKUP_RECOVERY_STARTED else ~is_recovery
    )
    limit = (
        MAX_BACKUP_RECOVERY_EVENTS_PER_USER
        if event_type == SecurityEventType.BACKUP_RECOVERY_STARTED
        else MAX_SECURITY_EVENTS_PER_USER
    )
    oldest_retained_id = (
        select(SecurityEvent.id)
        .where(SecurityEvent.user_id == user_id, bucket)
        .order_by(SecurityEvent.id.desc())
        .offset(limit)
        .limit(1)
        .scalar_subquery()
    )
    await db.execute(
        delete(SecurityEvent).where(
            SecurityEvent.user_id == user_id,
            bucket,
            SecurityEvent.id <= oldest_retained_id,
        )
    )
