import logging
import secrets
from datetime import UTC, datetime, timedelta
from typing import Annotated

from fastapi import APIRouter, BackgroundTasks, HTTPException, Query, Request, status
from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError

from pluris_server.dependencies import AppSettings, CurrentAuth, Db
from pluris_server.models import (
    DeviceSession,
    PasswordResetToken,
    RefreshToken,
    SecurityEvent,
    SecurityEventType,
    User,
)
from pluris_server.observability import (
    SecurityOperation,
    SecurityReason,
    SecuritySignal,
    log_security_signal,
)
from pluris_server.schemas import (
    ChangePasswordRequest,
    DeleteAccountRequest,
    LoginRequest,
    MessageResponse,
    PasswordResetConfirmRequest,
    PasswordResetRequest,
    RefreshRequest,
    RegisterRequest,
    RegistrationResponse,
    SecurityEventView,
    SessionView,
    TokenPair,
    UserView,
)
from pluris_server.security import (
    digest_friend_code,
    digest_legacy_friend_code,
    digest_token,
    dummy_verify_password,
    hash_password,
    issue_tokens,
    new_friend_code,
    rotate_refresh_token,
    verify_password,
)
from pluris_server.security_events import record_security_event

router = APIRouter(prefix="/v1/auth", tags=["auth"])
ACCOUNT_DELETION_GRACE = timedelta(days=30)
_logger = logging.getLogger("pluris.auth")


async def _deliver_password_reset(email_sender: object, recipient: str, token: str) -> None:
    try:
        await email_sender.send_password_reset(recipient, token)
    except Exception:
        _logger.exception("Password reset email delivery failed")


def _deletion_recovery_open(user: User, now: datetime) -> bool:
    purge_after = user.deletion_purge_after
    if purge_after is not None and purge_after.tzinfo is None:
        purge_after = purge_after.replace(tzinfo=UTC)
    return user.disabled and purge_after is not None and purge_after > now


async def _enforce_rate_limit(
    request: Request,
    operation: SecurityOperation,
    subject: str | None = None,
    include_client: bool = True,
) -> None:
    client_host = request.client.host if request.client is not None else "unknown"
    keys = [f"auth:{operation.value}:ip:{client_host}"] if include_client else []
    if subject is not None:
        keys.append(f"auth:{operation.value}:subject:{subject}")
    retry_after = await request.app.state.auth_rate_limiter.retry_after(keys)
    if retry_after is not None:
        log_security_signal(
            SecuritySignal.AUTH_RATE_LIMITED,
            operation=operation,
            reason=SecurityReason.RATE_LIMIT,
        )
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many authentication attempts",
            headers={"Retry-After": str(retry_after)},
        )


async def _enforce_refresh_ip_limit(request: Request) -> None:
    client_host = request.client.host if request.client is not None else "unknown"
    retry_after = await request.app.state.refresh_ip_rate_limiter.retry_after(
        [f"auth:refresh:ip:{client_host}"]
    )
    if retry_after is not None:
        log_security_signal(
            SecuritySignal.AUTH_RATE_LIMITED,
            operation=SecurityOperation.REFRESH,
            reason=SecurityReason.RATE_LIMIT,
        )
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many authentication attempts",
            headers={"Retry-After": str(retry_after)},
        )


async def _assign_friend_code(db: Db, user: User, pepper: str) -> str:
    for _ in range(10):
        code = new_friend_code()
        digest = digest_friend_code(code, pepper)
        legacy_digest = digest_legacy_friend_code(code, pepper)
        existing = await db.scalar(
            select(User.id).where(User.friend_code_digest.in_((digest, legacy_digest)))
        )
        if existing is None:
            user.friend_code_digest = digest
            return code
    raise HTTPException(status_code=503, detail="Could not allocate a friend code")


@router.post("/register", response_model=RegistrationResponse, status_code=status.HTTP_201_CREATED)
async def register(
    request: Request, payload: RegisterRequest, db: Db, settings: AppSettings
) -> RegistrationResponse:
    if not settings.registration_enabled:
        log_security_signal(
            SecuritySignal.AUTH_REJECTED,
            operation=SecurityOperation.REGISTER,
            reason=SecurityReason.REGISTRATION_DISABLED,
        )
        raise HTTPException(status_code=503, detail="Account registration is not enabled")
    email = str(payload.email).strip().casefold()
    await _enforce_rate_limit(request, SecurityOperation.REGISTER, email)
    existing = await db.scalar(select(User).where(User.email == email))
    if existing is not None:
        log_security_signal(
            SecuritySignal.AUTH_REJECTED,
            operation=SecurityOperation.REGISTER,
            reason=SecurityReason.ACCOUNT_CONFLICT,
        )
        detail = "An account with that email already exists"
        if _deletion_recovery_open(existing, datetime.now(UTC)):
            detail = "This email is scheduled for deletion; reset its password to recover it"
        raise HTTPException(status_code=409, detail=detail)

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
        log_security_signal(
            SecuritySignal.AUTH_REJECTED,
            operation=SecurityOperation.REGISTER,
            reason=SecurityReason.ACCOUNT_CONFLICT,
        )
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
    await _enforce_rate_limit(request, SecurityOperation.LOGIN, email)
    user = await db.scalar(select(User).where(User.email == email))
    if user is None:
        await dummy_verify_password(payload.password)
        log_security_signal(
            SecuritySignal.AUTH_REJECTED,
            operation=SecurityOperation.LOGIN,
            reason=SecurityReason.INVALID_CREDENTIALS,
        )
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if not await verify_password(payload.password, user.password_hash):
        log_security_signal(
            SecuritySignal.AUTH_REJECTED,
            operation=SecurityOperation.LOGIN,
            reason=SecurityReason.INVALID_CREDENTIALS,
        )
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if user.disabled:
        log_security_signal(
            SecuritySignal.AUTH_REJECTED,
            operation=SecurityOperation.LOGIN,
            reason=SecurityReason.DISABLED_ACCOUNT,
        )
        detail = "This account is disabled"
        if _deletion_recovery_open(user, datetime.now(UTC)):
            detail = "This account is scheduled for deletion; reset its password to recover it"
        raise HTTPException(status_code=403, detail=detail)

    tokens = await issue_tokens(db, user, payload.device_name, settings)
    await db.commit()
    return TokenPair(**tokens.__dict__)


@router.post("/refresh", response_model=TokenPair)
async def refresh(
    request: Request, payload: RefreshRequest, db: Db, settings: AppSettings
) -> TokenPair:
    await _enforce_refresh_ip_limit(request)
    await _enforce_rate_limit(
        request,
        SecurityOperation.REFRESH,
        digest_token(payload.refresh_token, purpose="refresh"),
        include_client=False,
    )
    tokens = await rotate_refresh_token(
        db,
        payload.refresh_token,
        settings,
        rotation_nonce=payload.rotation_nonce,
    )
    if tokens is None:
        log_security_signal(
            SecuritySignal.AUTH_REJECTED,
            operation=SecurityOperation.REFRESH,
            reason=SecurityReason.INVALID_CREDENTIALS,
        )
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
    await record_security_event(
        db,
        user_id=auth.user.id,
        event_type=SecurityEventType.SIGNED_OUT,
    )
    await db.commit()
    return MessageResponse(detail="Signed out")


@router.post("/password", response_model=MessageResponse)
async def change_password(
    request: Request,
    payload: ChangePasswordRequest,
    auth: CurrentAuth,
    db: Db,
) -> MessageResponse:
    await _enforce_rate_limit(request, SecurityOperation.CHANGE_PASSWORD, auth.user.email)
    if not await verify_password(payload.current_password, auth.user.password_hash):
        log_security_signal(
            SecuritySignal.AUTH_REJECTED,
            operation=SecurityOperation.CHANGE_PASSWORD,
            reason=SecurityReason.WRONG_CURRENT_PASSWORD,
        )
        raise HTTPException(status_code=401, detail="Current password is incorrect")
    if await verify_password(payload.new_password, auth.user.password_hash):
        raise HTTPException(status_code=400, detail="New password must be different")

    changed_at = datetime.now(UTC)
    auth.user.password_hash = await hash_password(payload.new_password)
    other_session_ids = select(DeviceSession.id).where(
        DeviceSession.user_id == auth.user.id,
        DeviceSession.id != auth.session.id,
    )
    await db.execute(
        update(DeviceSession)
        .where(DeviceSession.id.in_(other_session_ids), DeviceSession.revoked_at.is_(None))
        .values(revoked_at=changed_at)
    )
    await db.execute(
        update(RefreshToken)
        .where(
            RefreshToken.session_id.in_(other_session_ids),
            RefreshToken.revoked_at.is_(None),
        )
        .values(revoked_at=changed_at)
    )
    await record_security_event(
        db,
        user_id=auth.user.id,
        event_type=SecurityEventType.PASSWORD_CHANGED,
    )
    await db.commit()
    return MessageResponse(detail="Password changed")


@router.post("/password/reset-request", response_model=MessageResponse, status_code=202)
async def request_password_reset(
    request: Request,
    background_tasks: BackgroundTasks,
    payload: PasswordResetRequest,
    db: Db,
    settings: AppSettings,
) -> MessageResponse:
    email = str(payload.email).strip().casefold()
    await _enforce_rate_limit(request, SecurityOperation.PASSWORD_RESET_REQUEST, email)
    user = await db.scalar(select(User).where(User.email == email))
    if user is not None and (not user.disabled or _deletion_recovery_open(user, datetime.now(UTC))):
        now = datetime.now(UTC)
        await db.execute(
            update(PasswordResetToken)
            .where(PasswordResetToken.user_id == user.id, PasswordResetToken.used_at.is_(None))
            .values(used_at=now)
        )
        token = secrets.token_urlsafe(48)
        db.add(
            PasswordResetToken(
                user_id=user.id,
                token_digest=digest_token(token, purpose="password_reset"),
                issued_at=now,
                expires_at=now + timedelta(minutes=settings.password_reset_token_minutes),
            )
        )
        await db.commit()
        background_tasks.add_task(
            _deliver_password_reset,
            request.app.state.email_sender,
            user.email,
            token,
        )
    return MessageResponse(detail="If that account exists, a reset token has been sent")


@router.post("/password/reset", response_model=MessageResponse)
async def reset_password(
    request: Request,
    payload: PasswordResetConfirmRequest,
    db: Db,
) -> MessageResponse:
    await _enforce_rate_limit(request, SecurityOperation.PASSWORD_RESET)
    now = datetime.now(UTC)
    result = await db.execute(
        select(PasswordResetToken, User)
        .join(User, User.id == PasswordResetToken.user_id)
        .where(
            PasswordResetToken.token_digest == digest_token(payload.token, purpose="password_reset")
        )
        .with_for_update()
    )
    row = result.one_or_none()
    if row is None:
        raise HTTPException(status_code=400, detail="Invalid or expired password reset token")
    reset_token, user = row
    expires_at = reset_token.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=UTC)
    if (
        (user.disabled and not _deletion_recovery_open(user, now))
        or reset_token.used_at is not None
        or expires_at <= now
    ):
        raise HTTPException(status_code=400, detail="Invalid or expired password reset token")

    reset_token.used_at = now
    user.password_hash = await hash_password(payload.new_password)
    recovered = _deletion_recovery_open(user, now)
    if recovered:
        user.disabled = False
        user.deletion_requested_at = None
        user.deletion_purge_after = None
    await db.execute(
        update(DeviceSession)
        .where(DeviceSession.user_id == user.id, DeviceSession.revoked_at.is_(None))
        .values(revoked_at=now)
    )
    await db.execute(
        update(RefreshToken)
        .where(
            RefreshToken.session_id.in_(
                select(DeviceSession.id).where(DeviceSession.user_id == user.id)
            ),
            RefreshToken.revoked_at.is_(None),
        )
        .values(revoked_at=now)
    )
    await record_security_event(db, user_id=user.id, event_type=SecurityEventType.PASSWORD_CHANGED)
    if recovered:
        await record_security_event(
            db, user_id=user.id, event_type=SecurityEventType.ACCOUNT_RECOVERED
        )
    await db.commit()
    detail = "Password reset; sign in again"
    if recovered:
        detail = "Password reset and account recovered; sign in again"
    return MessageResponse(detail=detail)


@router.delete("/account", response_model=MessageResponse)
async def delete_account(
    request: Request,
    payload: DeleteAccountRequest,
    auth: CurrentAuth,
    db: Db,
) -> MessageResponse:
    await _enforce_rate_limit(request, SecurityOperation.DELETE_ACCOUNT, auth.user.email)
    if not await verify_password(payload.password, auth.user.password_hash):
        log_security_signal(
            SecuritySignal.AUTH_REJECTED,
            operation=SecurityOperation.DELETE_ACCOUNT,
            reason=SecurityReason.WRONG_CURRENT_PASSWORD,
        )
        raise HTTPException(status_code=401, detail="Current password is incorrect")

    now = datetime.now(UTC)
    auth.user.disabled = True
    auth.user.deletion_requested_at = now
    auth.user.deletion_purge_after = now + ACCOUNT_DELETION_GRACE
    await db.execute(
        update(DeviceSession)
        .where(DeviceSession.user_id == auth.user.id, DeviceSession.revoked_at.is_(None))
        .values(revoked_at=now)
    )
    await db.execute(
        update(RefreshToken)
        .where(
            RefreshToken.session_id.in_(
                select(DeviceSession.id).where(DeviceSession.user_id == auth.user.id)
            ),
            RefreshToken.revoked_at.is_(None),
        )
        .values(revoked_at=now)
    )
    await record_security_event(
        db,
        user_id=auth.user.id,
        event_type=SecurityEventType.ACCOUNT_DELETION_REQUESTED,
    )
    await db.commit()
    return MessageResponse(detail="Account deletion scheduled; recover within 30 days")


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


@router.get("/security-events", response_model=list[SecurityEventView])
async def security_events(
    auth: CurrentAuth,
    db: Db,
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
    before_id: Annotated[int | None, Query(ge=1)] = None,
) -> list[SecurityEvent]:
    query = select(SecurityEvent).where(SecurityEvent.user_id == auth.user.id)
    if before_id is not None:
        query = query.where(SecurityEvent.id < before_id)
    return list((await db.scalars(query.order_by(SecurityEvent.id.desc()).limit(limit))).all())


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
    await record_security_event(
        db,
        user_id=auth.user.id,
        event_type=SecurityEventType.SESSION_REVOKED,
    )
    await db.commit()
    return MessageResponse(detail="Session revoked")
