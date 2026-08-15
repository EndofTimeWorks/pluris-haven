from sqlalchemy.ext.asyncio import AsyncSession

from pluris_server.models import SecurityEvent, SecurityEventType


def record_security_event(
    db: AsyncSession,
    *,
    user_id: str,
    event_type: SecurityEventType,
) -> None:
    """Append a privacy-minimised event in the caller's transaction."""
    db.add(SecurityEvent(user_id=user_id, event_type=event_type.value))
