from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from pluris_server.models import SecurityEvent, SecurityEventType

MAX_SECURITY_EVENTS_PER_USER = 500


async def record_security_event(
    db: AsyncSession,
    *,
    user_id: str,
    event_type: SecurityEventType,
) -> None:
    """Append a bounded privacy-minimised event in the caller's transaction."""
    db.add(SecurityEvent(user_id=user_id, event_type=event_type.value))
    await db.flush()

    oldest_retained_id = (
        select(SecurityEvent.id)
        .where(SecurityEvent.user_id == user_id)
        .order_by(SecurityEvent.id.desc())
        .offset(MAX_SECURITY_EVENTS_PER_USER)
        .limit(1)
        .scalar_subquery()
    )
    await db.execute(
        delete(SecurityEvent).where(
            SecurityEvent.user_id == user_id,
            SecurityEvent.id <= oldest_retained_id,
        )
    )
