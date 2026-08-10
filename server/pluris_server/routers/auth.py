from datetime import UTC, datetime

from fastapi import APIRouter, HTTPException, Request, status
from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError

from pluris_server.backup_cleanup import queue_backup_deletions, sweep_backup_deletions
from pluris_server.dependencies import AppSettings, CurrentAuth, Db
from pluris_server.models import BackupSnapshot, DeviceSession, RefreshToken, User
from pluris_server.schemas import (
    DeleteAccountRequest,
    LoginRequest,
    MessageResponse,
    RefreshRequest,
    RegisterRequest,
    RegistrationResponse,
    SessionView,
    TokenPair,
    UserView,
)
from pluris_server.security import (
    digest_friend_code,
    digest_token,
    dummy_verify_password,
    hash_password,
    issue_tokens,
    new_friend_code,
    rotate_refresh_token,
    verify_password,
)

router = APIRouter(prefix="/v1/auth", tags=["auth"])


async def _enforce_rate_limit(
    request: Request,
    endpoint: str,
    subject: str | None = None,
    include_client: bool = True,
) -> None:
    client_host = request.client.host if request.client is not None else "unknown"
    keys = [f"auth:{endpoint}:ip:{client_host}"] if include_client else []
    if subject is not None:
        keys.append(f"auth:{endpoint}:subject:{subject}")
    retry_after = await request.app.state.auth_rate_limiter.retry_after(keys)
    if retry_after is not None:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many authentication attempts",
            headers={"Retry-After": str(retry_after)},
        )


async def _assign_friend_code(db: Db, user: User, pepper: str) -> str:
    for _ in range(10):
        code = new_friend_code()
        digest = digest_friend_code(code, pepper)
        existing = await db.scalar(select(User.id).where(User.friend_code_digest == digest))
        if existing is None:
            user.friend_code_digest = digest
            return code
    raise HTTPException(status_code=503, detail="Could not allocate a friend code")


@router.post("/register", response_model=RegistrationResponse, status_code=status.HTTP_201_CREATED)
async def register(
    request: Request, payload: RegisterRequest, db: Db, settings: AppSettings
) -> RegistrationResponse:
    email = str(payload.email).strip().casefold()
    await _enforce_rate_limit(request, "register", email)
    if not settings.registration_enabled:
        raise HTTPException(status_code=503, detail="Account registration is not enabled")
    if await db.scalar(select(User.id).where(User.email == email)) is not None:
        raise HTTPException(status_code=409, detail="An account with that email already exists")

    user = User(
        email=email,
        display_name=payload.display_name,
        password_hash=await hash_password(payload.password),
    )
    db.add(user)
    try:
        await db.flush()
        friend_code = await _assign_friend_code(db, user, settings.friend_code_pepper)
        tokens = await issue_tokens(db, user, payload.device_name, settings)
        await db.commit()
    except IntegrityError as error:
        await db.rollback()
        raise HTTPException(
            status_code=409, detail="An account with that email already exists"
        ) from error
    return RegistrationResponse(
        access_token=tokens.access_token,
        refresh_token=tokens.refresh_token,
        expires_in=tokens.expires_in,
        friend_code=friend_code,
    )


@router.post("/login", response_model=TokenPair)
async def login(
    request: Request, payload: LoginRequest, db: Db, settings: AppSettings
) -> TokenPair:
    email = str(payload.email).strip().casefold()
    await _enforce_rate_limit(request, "login", email)
    user = await db.scalar(select(User).where(User.email == email))
    if user is None:
        await dummy_verify_password(payload.password)
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if not await verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if user.disabled:
        raise HTTPException(status_code=403, detail="This account is disabled")

    tokens = await issue_tokens(db, user, payload.device_name, settings)
    await db.commit()
    return TokenPair(**tokens.__dict__)


@router.post("/refresh", response_model=TokenPair)
async def refresh(
    request: Request, payload: RefreshRequest, db: Db, settings: AppSettings
) -> TokenPair:
    await _enforce_rate_limit(
        request,
        "refresh",
        digest_token(payload.refresh_token),
        include_client=False,
    )
    tokens = await rotate_refresh_token(db, payload.refresh_token, settings)
    if tokens is None:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")
    await db.commit()
    return TokenPair(**tokens.__dict__)


@router.post("/logout", response_model=MessageResponse)
async def logout(auth: CurrentAuth, db: Db) -> MessageResponse:
    auth.session.revoked_at = datetime.now(UTC)
    await db.execute(
        update(RefreshToken)
        .where(RefreshToken.session_id == auth.session.id, RefreshToken.revoked_at.is_(None))
        .values(revoked_at=auth.session.revoked_at)
    )
    await db.commit()
    return MessageResponse(detail="Signed out")


@router.delete("/account", response_model=MessageResponse)
async def delete_account(
    request: Request,
    payload: DeleteAccountRequest,
    auth: CurrentAuth,
    db: Db,
) -> MessageResponse:
    await _enforce_rate_limit(request, "delete", auth.user.email)
    if not await verify_password(payload.password, auth.user.password_hash):
        raise HTTPException(status_code=401, detail="Current password is incorrect")

    snapshots = (
        await db.scalars(select(BackupSnapshot).where(BackupSnapshot.user_id == auth.user.id))
    ).all()
    snapshot_ids = [snapshot.snapshot_id for snapshot in snapshots]
    owner_id = auth.user.id
    queue_backup_deletions(db, owner_id=owner_id, snapshot_ids=snapshot_ids)
    await db.delete(auth.user)
    await db.commit()
    await sweep_backup_deletions(db, request.app.state.backup_object_store)
    return MessageResponse(detail="Account deleted")


@router.get("/me", response_model=UserView)
async def me(auth: CurrentAuth) -> User:
    return auth.user


@router.get("/sessions", response_model=list[SessionView])
async def sessions(auth: CurrentAuth, db: Db) -> list[SessionView]:
    rows = (
        await db.scalars(
            select(DeviceSession)
            .where(DeviceSession.user_id == auth.user.id, DeviceSession.revoked_at.is_(None))
            .order_by(DeviceSession.last_used_at.desc())
        )
    ).all()
    return [
        SessionView(
            id=row.id,
            device_name=row.device_name,
            created_at=row.created_at,
            last_used_at=row.last_used_at,
            expires_at=row.expires_at,
            current=row.id == auth.session.id,
        )
        for row in rows
    ]


@router.delete("/sessions/{session_id}", response_model=MessageResponse)
async def revoke_session(session_id: str, auth: CurrentAuth, db: Db) -> MessageResponse:
    target = await db.scalar(
        select(DeviceSession).where(
            DeviceSession.id == session_id,
            DeviceSession.user_id == auth.user.id,
            DeviceSession.revoked_at.is_(None),
        )
    )
    if target is None:
        raise HTTPException(status_code=404, detail="Session not found")
    target.revoked_at = datetime.now(UTC)
    await db.execute(
        update(RefreshToken)
        .where(RefreshToken.session_id == target.id, RefreshToken.revoked_at.is_(None))
        .values(revoked_at=target.revoked_at)
    )
    await db.commit()
    return MessageResponse(detail="Session revoked")
