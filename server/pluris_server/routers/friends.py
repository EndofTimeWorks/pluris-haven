from datetime import UTC, datetime, timedelta
from math import ceil

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import delete, func, or_, select
from sqlalchemy.exc import IntegrityError

from pluris_server.dependencies import (
    AppSettings,
    CurrentAuth,
    Db,
    require_friends_enabled,
)
from pluris_server.models import (
    FriendRequest,
    Friendship,
    RequestStatus,
    User,
    UserBlock,
)
from pluris_server.schemas import (
    BlockCreate,
    BlockView,
    FriendCodeResponse,
    FriendRequestCreate,
    FriendRequestView,
    FriendView,
    MessageResponse,
    PublicUserView,
)
from pluris_server.security import (
    digest_friend_code,
    digest_legacy_friend_code,
    new_friend_code,
)

router = APIRouter(
    prefix="/v1/friends",
    tags=["friends"],
    dependencies=[Depends(require_friends_enabled)],
)


async def _enforce_request_rate_limit(request: Request, user_id: str) -> None:
    client_host = request.client.host if request.client is not None else "unknown"
    retry_after = await request.app.state.friend_request_rate_limiter.retry_after(
        [
            f"friends:requests:ip:{client_host}",
            f"friends:requests:user:{user_id}",
        ]
    )
    if retry_after is not None:
        raise HTTPException(
            status_code=429,
            detail="Too many friend requests",
            headers={"Retry-After": str(retry_after)},
        )


async def _enforce_code_rotation_rate_limit(request: Request, user_id: str) -> None:
    client_host = request.client.host if request.client is not None else "unknown"
    retry_after = await request.app.state.friend_request_rate_limiter.retry_after(
        [
            f"friends:code-rotation:ip:{client_host}",
            f"friends:code-rotation:user:{user_id}",
        ]
    )
    if retry_after is not None:
        raise HTTPException(
            status_code=429,
            detail="Too many friend-code rotations",
            headers={"Retry-After": str(retry_after)},
        )


def _pair(first: str, second: str) -> tuple[str, str]:
    return (first, second) if first < second else (second, first)


async def _blocked(db: Db, first: str, second: str) -> bool:
    return (
        await db.scalar(
            select(UserBlock.id).where(
                or_(
                    (UserBlock.blocker_id == first) & (UserBlock.blocked_id == second),
                    (UserBlock.blocker_id == second) & (UserBlock.blocked_id == first),
                )
            )
        )
        is not None
    )


async def _friendship_for(db: Db, first: str, second: str) -> Friendship | None:
    low, high = _pair(first, second)
    return await db.scalar(
        select(Friendship).where(
            Friendship.user_low_id == low,
            Friendship.user_high_id == high,
        )
    )


def _request_view(request: FriendRequest, current_id: str, other: User) -> FriendRequestView:
    other_id = request.recipient_id if request.requester_id == current_id else request.requester_id
    if other.id != other_id:
        raise ValueError("request view user does not match request")
    return FriendRequestView(
        id=request.id,
        direction="outgoing" if request.requester_id == current_id else "incoming",
        status=request.status,
        user=PublicUserView(id=other.id, display_name=other.display_name),
        created_at=request.created_at,
        updated_at=request.updated_at,
    )


@router.post("/code/rotate", response_model=FriendCodeResponse)
async def rotate_code(
    request: Request,
    auth: CurrentAuth,
    db: Db,
    settings: AppSettings,
) -> FriendCodeResponse:
    await _enforce_code_rotation_rate_limit(request, auth.user.id)
    for _ in range(10):
        code = new_friend_code()
        digest = digest_friend_code(code, settings.friend_code_pepper)
        legacy_digest = digest_legacy_friend_code(code, settings.friend_code_pepper)
        existing = await db.scalar(
            select(User.id).where(User.friend_code_digest.in_((digest, legacy_digest)))
        )
        if existing is None:
            auth.user.friend_code_digest = digest
            await db.commit()
            return FriendCodeResponse(friend_code=code)
    raise HTTPException(status_code=503, detail="Could not allocate a friend code")


@router.post("/requests", response_model=FriendRequestView, status_code=status.HTTP_201_CREATED)
async def create_request(
    payload: FriendRequestCreate,
    request: Request,
    auth: CurrentAuth,
    db: Db,
    settings: AppSettings,
) -> FriendRequestView:
    await _enforce_request_rate_limit(request, auth.user.id)
    digest = digest_friend_code(payload.friend_code, settings.friend_code_pepper)
    legacy_digest = digest_legacy_friend_code(payload.friend_code, settings.friend_code_pepper)
    recipients = (
        await db.scalars(select(User).where(User.friend_code_digest.in_((digest, legacy_digest))))
    ).all()
    if len(recipients) != 1 or recipients[0].disabled:
        raise HTTPException(status_code=404, detail="Friend code not found")
    recipient = recipients[0]
    if recipient.friend_code_digest == legacy_digest:
        recipient.friend_code_digest = digest
    if recipient.id == auth.user.id:
        raise HTTPException(status_code=400, detail="You cannot add yourself")
    if await _blocked(db, auth.user.id, recipient.id):
        raise HTTPException(status_code=404, detail="Friend code not found")
    if await _friendship_for(db, auth.user.id, recipient.id) is not None:
        raise HTTPException(status_code=409, detail="You are already connected")

    low, high = _pair(auth.user.id, recipient.id)
    friend_request = await db.scalar(
        select(FriendRequest).where(
            FriendRequest.pair_low_id == low,
            FriendRequest.pair_high_id == high,
        )
    )
    now = datetime.now(UTC)
    if friend_request is None:
        friend_request = FriendRequest(
            pair_low_id=low,
            pair_high_id=high,
            requester_id=auth.user.id,
            recipient_id=recipient.id,
            status=RequestStatus.PENDING.value,
            created_at=now,
            updated_at=now,
        )
        db.add(friend_request)
    elif friend_request.status == RequestStatus.PENDING.value:
        raise HTTPException(status_code=409, detail="A request is already pending")
    else:
        if (
            friend_request.status == RequestStatus.DECLINED.value
            and friend_request.requester_id == auth.user.id
            and friend_request.recipient_id == recipient.id
            and friend_request.responded_at is not None
            and settings.friend_request_cooldown_seconds > 0
        ):
            responded_at = friend_request.responded_at
            if responded_at.tzinfo is None:
                responded_at = responded_at.replace(tzinfo=UTC)
            retry_after = (
                responded_at + timedelta(seconds=settings.friend_request_cooldown_seconds) - now
            ).total_seconds()
            if retry_after > 0:
                raise HTTPException(
                    status_code=429,
                    detail="You cannot send another request to this account yet",
                    headers={"Retry-After": str(max(1, ceil(retry_after)))},
                )
        friend_request.requester_id = auth.user.id
        friend_request.recipient_id = recipient.id
        friend_request.status = RequestStatus.PENDING.value
        friend_request.created_at = now
        friend_request.updated_at = now
        friend_request.responded_at = None
    try:
        await db.commit()
    except IntegrityError as error:
        await db.rollback()
        raise HTTPException(status_code=409, detail="A request is already pending") from error
    await db.refresh(friend_request)
    return _request_view(friend_request, auth.user.id, recipient)


@router.get("/requests", response_model=list[FriendRequestView])
async def list_requests(auth: CurrentAuth, db: Db) -> list[FriendRequestView]:
    requests = (
        await db.scalars(
            select(FriendRequest)
            .where(
                or_(
                    FriendRequest.requester_id == auth.user.id,
                    FriendRequest.recipient_id == auth.user.id,
                ),
                FriendRequest.status == RequestStatus.PENDING.value,
            )
            .order_by(FriendRequest.created_at.desc())
        )
    ).all()
    other_ids = {
        request.recipient_id if request.requester_id == auth.user.id else request.requester_id
        for request in requests
    }
    users = (
        await db.scalars(select(User).where(User.id.in_(other_ids), User.disabled.is_(False)))
        if other_ids
        else []
    )
    users_by_id = {user.id: user for user in users}
    return [
        _request_view(
            request,
            auth.user.id,
            users_by_id[
                request.recipient_id
                if request.requester_id == auth.user.id
                else request.requester_id
            ],
        )
        for request in requests
        if (request.recipient_id if request.requester_id == auth.user.id else request.requester_id)
        in users_by_id
    ]


@router.post("/requests/{request_id}/accept", response_model=FriendView)
async def accept_request(request_id: str, auth: CurrentAuth, db: Db) -> FriendView:
    request = await db.scalar(
        select(FriendRequest).where(FriendRequest.id == request_id).with_for_update()
    )
    if (
        request is None
        or request.recipient_id != auth.user.id
        or request.status != RequestStatus.PENDING.value
    ):
        raise HTTPException(status_code=404, detail="Pending request not found")
    requester = await db.get(User, request.requester_id)
    if requester is None or requester.disabled:
        raise HTTPException(status_code=404, detail="Pending request not found")
    if await _blocked(db, request.requester_id, request.recipient_id):
        raise HTTPException(status_code=409, detail="This request can no longer be accepted")

    friendship = await _friendship_for(db, request.requester_id, request.recipient_id)
    if friendship is None:
        low, high = _pair(request.requester_id, request.recipient_id)
        friendship = Friendship(user_low_id=low, user_high_id=high)
        db.add(friendship)
        await db.flush()
    request.status = RequestStatus.ACCEPTED.value
    request.responded_at = request.updated_at = datetime.now(UTC)
    await db.commit()
    return await _friend_view(db, friendship, auth.user.id)


@router.post("/requests/{request_id}/decline", response_model=MessageResponse)
async def decline_request(request_id: str, auth: CurrentAuth, db: Db) -> MessageResponse:
    request = await db.scalar(
        select(FriendRequest).where(FriendRequest.id == request_id).with_for_update()
    )
    if (
        request is None
        or request.recipient_id != auth.user.id
        or request.status != RequestStatus.PENDING.value
    ):
        raise HTTPException(status_code=404, detail="Pending request not found")
    request.status = RequestStatus.DECLINED.value
    request.responded_at = request.updated_at = datetime.now(UTC)
    await db.commit()
    return MessageResponse(detail="Request declined")


@router.post("/requests/{request_id}/cancel", response_model=MessageResponse)
async def cancel_request(request_id: str, auth: CurrentAuth, db: Db) -> MessageResponse:
    request = await db.scalar(
        select(FriendRequest).where(FriendRequest.id == request_id).with_for_update()
    )
    if (
        request is None
        or request.requester_id != auth.user.id
        or request.status != RequestStatus.PENDING.value
    ):
        raise HTTPException(status_code=404, detail="Pending request not found")
    request.status = RequestStatus.CANCELLED.value
    request.responded_at = request.updated_at = datetime.now(UTC)
    await db.commit()
    return MessageResponse(detail="Request cancelled")


async def _friend_view(db: Db, friendship: Friendship, current_id: str) -> FriendView:
    other_id = (
        friendship.user_high_id if friendship.user_low_id == current_id else friendship.user_low_id
    )
    other = await db.get(User, other_id)
    if other is None or other.disabled:
        raise HTTPException(status_code=404, detail="Friend not found")
    return FriendView(
        friendship_id=friendship.id,
        user=PublicUserView(id=other.id, display_name=other.display_name),
        created_at=friendship.created_at,
    )


@router.get("", response_model=list[FriendView])
async def list_friends(auth: CurrentAuth, db: Db) -> list[FriendView]:
    friendships = (
        await db.scalars(
            select(Friendship)
            .where(
                or_(
                    Friendship.user_low_id == auth.user.id,
                    Friendship.user_high_id == auth.user.id,
                )
            )
            .order_by(Friendship.created_at.desc())
        )
    ).all()
    other_ids = {
        friendship.user_high_id
        if friendship.user_low_id == auth.user.id
        else friendship.user_low_id
        for friendship in friendships
    }
    users = (
        await db.scalars(select(User).where(User.id.in_(other_ids), User.disabled.is_(False)))
        if other_ids
        else []
    )
    users_by_id = {user.id: user for user in users}
    return [
        FriendView(
            friendship_id=friendship.id,
            user=PublicUserView(
                id=other_id,
                display_name=users_by_id[other_id].display_name,
            ),
            created_at=friendship.created_at,
        )
        for friendship in friendships
        for other_id in [
            friendship.user_high_id
            if friendship.user_low_id == auth.user.id
            else friendship.user_low_id
        ]
        if other_id in users_by_id
    ]


@router.delete("/{friendship_id}", response_model=MessageResponse)
async def remove_friend(friendship_id: str, auth: CurrentAuth, db: Db) -> MessageResponse:
    friendship = await db.get(Friendship, friendship_id)
    if friendship is None or auth.user.id not in {
        friendship.user_low_id,
        friendship.user_high_id,
    }:
        raise HTTPException(status_code=404, detail="Friend not found")
    await db.delete(friendship)
    await db.commit()
    return MessageResponse(detail="Friend removed")


@router.post("/blocks", response_model=BlockView, status_code=status.HTTP_201_CREATED)
async def block_user(
    payload: BlockCreate,
    request_context: Request,
    auth: CurrentAuth,
    db: Db,
    settings: AppSettings,
) -> BlockView:
    await _enforce_request_rate_limit(request_context, auth.user.id)
    if payload.user_id == auth.user.id:
        raise HTTPException(status_code=400, detail="You cannot block yourself")
    existing = await db.scalar(
        select(UserBlock).where(
            UserBlock.blocker_id == auth.user.id,
            UserBlock.blocked_id == payload.user_id,
        )
    )
    low, high = _pair(auth.user.id, payload.user_id)
    friend_request = await db.scalar(
        select(FriendRequest)
        .where(
            FriendRequest.pair_low_id == low,
            FriendRequest.pair_high_id == high,
        )
        .with_for_update()
    )
    # Acceptance locks the same canonical pair request before creating a
    # friendship. Re-read the friendship after acquiring that lock so a block
    # cannot commit alongside a friendship created while this transaction was
    # waiting.
    friendship = await _friendship_for(db, auth.user.id, payload.user_id)
    if existing is None and friendship is None and friend_request is None:
        raise HTTPException(status_code=404, detail="User is not available to block")
    target = await db.get(User, payload.user_id)
    if target is None:
        raise HTTPException(status_code=404, detail="User is not available to block")
    if existing is None:
        block_count = await db.scalar(
            select(func.count(UserBlock.id)).where(UserBlock.blocker_id == auth.user.id)
        )
        if int(block_count or 0) >= settings.max_blocks_per_user:
            raise HTTPException(status_code=413, detail="Block list limit reached")
        existing = UserBlock(blocker_id=auth.user.id, blocked_id=target.id)
        db.add(existing)
        await db.flush()

    if friendship is not None:
        await db.delete(friendship)
    if friend_request is not None and friend_request.status == RequestStatus.PENDING.value:
        friend_request.status = RequestStatus.CANCELLED.value
        friend_request.responded_at = friend_request.updated_at = datetime.now(UTC)
    await db.commit()
    return BlockView(
        user=PublicUserView(id=target.id, display_name=target.display_name),
        created_at=existing.created_at,
    )


@router.get("/blocks", response_model=list[BlockView])
async def list_blocks(auth: CurrentAuth, db: Db) -> list[BlockView]:
    rows = (
        await db.execute(
            select(UserBlock, User)
            .join(User, User.id == UserBlock.blocked_id)
            .where(UserBlock.blocker_id == auth.user.id)
            .order_by(UserBlock.created_at.desc())
        )
    ).all()
    return [
        BlockView(
            user=PublicUserView(id=target.id, display_name=target.display_name),
            created_at=block.created_at,
        )
        for block, target in rows
    ]


@router.delete("/blocks/{user_id}", response_model=MessageResponse)
async def unblock_user(user_id: str, auth: CurrentAuth, db: Db) -> MessageResponse:
    deleted_block_id = await db.scalar(
        delete(UserBlock)
        .where(
            UserBlock.blocker_id == auth.user.id,
            UserBlock.blocked_id == user_id,
        )
        .returning(UserBlock.id)
    )
    if deleted_block_id is None:
        raise HTTPException(status_code=404, detail="Block not found")
    await db.commit()
    return MessageResponse(detail="User unblocked")
