import asyncio
import base64
import hashlib
import hmac
import secrets
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

import jwt
from pwdlib import PasswordHash
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from pluris_server.config import Settings
from pluris_server.models import DeviceSession, RefreshToken, User

_password_hash = PasswordHash.recommended()
_password_slots = asyncio.Semaphore(4)
_dummy_hash = _password_hash.hash("pluris-haven-login-timing-placeholder")


@dataclass(frozen=True)
class IssuedTokens:
    access_token: str
    refresh_token: str
    expires_in: int


async def hash_password(password: str) -> str:
    async with _password_slots:
        return await asyncio.to_thread(_password_hash.hash, password)


async def verify_password(password: str, password_hash: str) -> bool:
    async with _password_slots:
        return await asyncio.to_thread(_password_hash.verify, password, password_hash)


async def dummy_verify_password(password: str) -> None:
    await verify_password(password, _dummy_hash)


def digest_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def normalize_friend_code(code: str) -> str:
    return "".join(character for character in code.upper() if character.isalnum())


def digest_friend_code(code: str, pepper: str) -> str:
    normalized = normalize_friend_code(code)
    return hmac.new(pepper.encode(), normalized.encode(), hashlib.sha256).hexdigest()


def new_friend_code() -> str:
    alphabet = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
    raw = "".join(secrets.choice(alphabet) for _ in range(16))
    return "-".join(raw[index : index + 4] for index in range(0, len(raw), 4))


def _new_refresh_token() -> str:
    return secrets.token_urlsafe(48)


def _rotated_refresh_token(refresh_token: str, settings: Settings) -> str:
    digest = hmac.new(
        settings.jwt_secret.encode(),
        b"pluris-haven:refresh-rotation:v1\0" + refresh_token.encode(),
        hashlib.sha384,
    ).digest()
    return base64.urlsafe_b64encode(digest).rstrip(b"=").decode()


def _create_access_token(user_id: str, session_id: str, settings: Settings) -> str:
    now = datetime.now(UTC)
    expires = now + timedelta(minutes=settings.access_token_minutes)
    payload = {
        "sub": user_id,
        "sid": session_id,
        "type": "access",
        "iat": now,
        "exp": expires,
        "jti": str(uuid.uuid4()),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm="HS256")


def decode_access_token(token: str, settings: Settings) -> dict[str, object]:
    return jwt.decode(
        token,
        settings.jwt_secret,
        algorithms=["HS256"],
        options={"require": ["sub", "sid", "type", "iat", "exp", "jti"]},
    )


async def issue_tokens(
    db: AsyncSession,
    user: User,
    device_name: str,
    settings: Settings,
) -> IssuedTokens:
    refresh_token = _new_refresh_token()
    now = datetime.now(UTC)
    session = DeviceSession(
        user_id=user.id,
        device_name=device_name.strip(),
        created_at=now,
        last_used_at=now,
        expires_at=now + timedelta(days=settings.refresh_token_days),
    )
    db.add(session)
    await db.flush()
    db.add(
        RefreshToken(
            session_id=session.id,
            token_digest=digest_token(refresh_token),
            issued_at=now,
            expires_at=session.expires_at,
        )
    )
    await db.flush()
    return IssuedTokens(
        access_token=_create_access_token(user.id, session.id, settings),
        refresh_token=refresh_token,
        expires_in=settings.access_token_minutes * 60,
    )


async def rotate_refresh_token(
    db: AsyncSession,
    refresh_token: str,
    settings: Settings,
) -> IssuedTokens | None:
    result = await db.execute(
        select(RefreshToken, DeviceSession, User)
        .join(DeviceSession, DeviceSession.id == RefreshToken.session_id)
        .join(User, User.id == DeviceSession.user_id)
        .where(RefreshToken.token_digest == digest_token(refresh_token))
        .with_for_update()
    )
    row = result.one_or_none()
    if row is None:
        return None
    token_record, session, user = row
    now = datetime.now(UTC)
    expires_at = token_record.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=UTC)
    if (
        token_record.revoked_at is not None
        or session.revoked_at is not None
        or expires_at <= now
        or user.disabled
    ):
        return None
    if token_record.used_at is not None:
        used_at = token_record.used_at
        if used_at.tzinfo is None:
            used_at = used_at.replace(tzinfo=UTC)
        replacement_token = _rotated_refresh_token(refresh_token, settings)
        replacement = await db.scalar(
            select(RefreshToken).where(
                RefreshToken.session_id == session.id,
                RefreshToken.token_digest == digest_token(replacement_token),
                RefreshToken.revoked_at.is_(None),
            )
        )
        if replacement is not None and now - used_at <= timedelta(
            seconds=settings.refresh_reuse_grace_seconds
        ):
            return IssuedTokens(
                access_token=_create_access_token(user.id, session.id, settings),
                refresh_token=replacement_token,
                expires_in=settings.access_token_minutes * 60,
            )
        session.revoked_at = now
        await db.execute(
            update(RefreshToken)
            .where(RefreshToken.session_id == session.id, RefreshToken.revoked_at.is_(None))
            .values(revoked_at=now)
        )
        await db.commit()
        return None
    new_refresh_token = _rotated_refresh_token(refresh_token, settings)
    token_record.used_at = now
    session.last_used_at = now
    session.expires_at = now + timedelta(days=settings.refresh_token_days)
    db.add(
        RefreshToken(
            session_id=session.id,
            token_digest=digest_token(new_refresh_token),
            issued_at=now,
            expires_at=session.expires_at,
        )
    )
    await db.flush()
    return IssuedTokens(
        access_token=_create_access_token(user.id, session.id, settings),
        refresh_token=new_refresh_token,
        expires_in=settings.access_token_minutes * 60,
    )
