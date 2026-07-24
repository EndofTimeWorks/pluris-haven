from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Annotated

import jwt
from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from pluris_server.config import Settings
from pluris_server.database import get_db
from pluris_server.models import DeviceSession, User
from pluris_server.security import decode_access_token

bearer = HTTPBearer(auto_error=False)


@dataclass(frozen=True)
class AuthContext:
    user: User
    session: DeviceSession


def settings_from_request(request: Request) -> Settings:
    return request.app.state.settings


async def get_auth_context(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)],
    db: Annotated[AsyncSession, Depends(get_db)],
    settings: Annotated[Settings, Depends(settings_from_request)],
) -> AuthContext:
    unauthorized = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if credentials is None:
        raise unauthorized
    try:
        payload = decode_access_token(credentials.credentials, settings)
    except jwt.PyJWTError as error:
        raise unauthorized from error
    if payload.get("type") != "access":
        raise unauthorized
    user_id = payload.get("sub")
    session_id = payload.get("sid")
    if not isinstance(user_id, str) or not isinstance(session_id, str):
        raise unauthorized

    result = await db.execute(
        select(User, DeviceSession)
        .join(DeviceSession, DeviceSession.user_id == User.id)
        .where(User.id == user_id, DeviceSession.id == session_id)
    )
    row = result.one_or_none()
    if row is None:
        raise unauthorized
    user, session = row
    expires_at = session.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=UTC)
    if user.disabled or session.revoked_at is not None or expires_at <= datetime.now(UTC):
        raise unauthorized
    return AuthContext(user=user, session=session)


def require_friends_enabled(settings: Annotated[Settings, Depends(settings_from_request)]) -> None:
    if not settings.friends_enabled:
        raise HTTPException(status_code=503, detail="Friend connections are not enabled")


Db = Annotated[AsyncSession, Depends(get_db)]
CurrentAuth = Annotated[AuthContext, Depends(get_auth_context)]
AppSettings = Annotated[Settings, Depends(settings_from_request)]
