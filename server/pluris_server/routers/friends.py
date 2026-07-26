from datetime import UTC, datetime, timedelta
from math import ceil

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import delete, or_, select
from sqlalchemy.exc import IntegrityError

from pluris_server.dependencies import (
    AppSettings,
    CurrentAuth,
    Db,
    require_friends_enabled,
)
from pluris_server.models import (
    FriendGrant,
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
    GrantUpdate,
    MessageResponse,
    PublicUserView,
)
from pluris_server.security import digest_friend_code, new_friend_code

router = APIRouter(
    prefix="/v1/friends",
    tags=["friends"],
    dependencies=[Depends(require_friends_enabled)],
)

ALLOWED_GRANT_SCOPES = frozenset(
    {
        "front_status",
        "members",
        "member_details",
        "front_history",
        "groups",
        "notes",
        "polls",
    }
)


def _pair(first: str, second: str) -> tuple[str, str]:
    return tuple(sorted((first, second)))


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


async def _request_view(db: Db, request: FriendRequest, current_id: str) -> FriendRequestView:
    other_id = request.recipient_id if request.requester_id == current_id else request.requester_id
    other = await db.get(User, other_id)
    if other is None:
        raise HTTPException(status_code=404, detail="Request user no longer exists")
    return FriendRequestView(
        id=request.id,
        direction="outgoing" if request.requester_id == current_id else "incoming",
        status=request.status,
        user=PublicUserView(id=other.id, display_name=other.display_name),
        created_at=request.created_at,
        updated_at=request.updated_at,
    )


@router.post("/code/rotate", response_model=FriendCodeResponse)
async def rotate_code(auth: CurrentAuth, db: Db, settings: AppSettings) -> FriendCodeResponse:
    for _ in range(10):
        code = new_friend_code()
        digest = digest_friend_code(code, settings.friend_code_pepper)
        if await db.scalar(select(User.id).where(User.friend_code_digest == digest)) is None:
            auth.user.friend_code_digest = digest
            await db.commit()
            return FriendCodeResponse(friend_code=code)
    raise HTTPException(status_code=503, detail="Could not allocate a friend code")


@router.post("/requests", response_model=FriendRequestView, status_code=status.HTTP_201_CREATED)
async def create_request(
    payload: FriendRequestCreate,
    auth: CurrentAuth,
    db: Db,
    settings: AppSettings,
) -> FriendRequestView:
    digest = digest_friend_code(payload.friend_code, settings.friend_code_pepper)
    recipient = await db.scalar(select(User).where(User.friend_code_digest == digest))
    if recipient is None or recipient.disabled:
        raise HTTPException(status_code=404, detail="Friend code not found")
    if recipient.id == auth.user.id:
        raise HTTPException(status_code=400, detail="You cannot add yourself")
    if await _blocked(db, auth.user.id, recipient.id):
        raise HTTPException(status_code=404, detail="Friend code not found")
    if await _friendship_for(db, auth.user.id, recipient.id) is not None:
        raise HTTPException(status_code=409, detail="You are already connected")

    low, high = _pair(auth.user.id, recipient.id)
    request = await db.scalar(
        select(FriendRequest).where(
            FriendRequest.pair_low_id == low,
            FriendRequest.pair_high_id == high,
        )
    )
    now = datetime.now(UTC)
    if request is None:
        request = FriendRequest(
            pair_low_id=low,
            pair_high_id=high,
            requester_id=auth.user.id,
            recipient_id=recipient.id,
            status=RequestStatus.PENDING.value,
            created_at=now,
            updated_at=now,
        )
        db.add(request)
    elif request.status == RequestStatus.PENDING.value:
        raise HTTPException(status_code=409, detail="A request is already pending")
    else:
        if (
            request.status == RequestStatus.DECLINED.value
            and request.requester_id == auth.user.id
            and request.recipient_id == recipient.id
            and request.responded_at is not None
            and settings.friend_request_cooldown_seconds > 0
        ):
            responded_at = request.responded_at
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
        request.requester_id = auth.user.id
        request.recipient_id = recipient.id
        request.status = RequestStatus.PENDING.value
        request.created_at = now
        request.updated_at = now
        request.responded_at = None
    try:
        await db.commit()
    except IntegrityError as error:
        await db.rollback()
        raise HTTPException(status_code=409, detail="A request is already pending") from error
    await db.refresh(request)
    return await _request_view(db, request, auth.user.id)


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
    return [await _request_view(db, request, auth.user.id) for request in requests]


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
    request = await db.scalar(select(FriendRequest).where(FriendRequest.id == request_id))
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
    request = await db.scalar(select(FriendRequest).where(FriendRequest.id == request_id))
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
    grants = (
        await db.scalars(select(FriendGrant).where(FriendGrant.friendship_id == friendship.id))
    ).all()
    return FriendView(
        friendship_id=friendship.id,
        user=PublicUserView(id=other.id, display_name=other.display_name),
        created_at=friendship.created_at,
        grants_to_them=sorted(
            grant.scope
            for grant in grants
            if grant.owner_id == current_id and grant.viewer_id == other_id
        ),
        grants_from_them=sorted(
            grant.scope
            for grant in grants
            if grant.owner_id == other_id and grant.viewer_id == current_id
        ),
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
    return [await _friend_view(db, friendship, auth.user.id) for friendship in friendships]


@router.put("/{friendship_id}/grants", response_model=FriendView)
async def update_grants(
    friendship_id: str,
    payload: GrantUpdate,
    auth: CurrentAuth,
    db: Db,
) -> FriendView:
    unknown = payload.scopes - ALLOWED_GRANT_SCOPES
    if unknown:
        detail = f"Unknown sharing scopes: {', '.join(sorted(unknown))}"
        raise HTTPException(status_code=422, detail=detail)
    friendship = await db.get(Friendship, friendship_id)
    if friendship is None or auth.user.id not in {
        friendship.user_low_id,
        friendship.user_high_id,
    }:
        raise HTTPException(status_code=404, detail="Friend not found")
    viewer_id = (
        friendship.user_high_id
        if friendship.user_low_id == auth.user.id
        else friendship.user_low_id
    )
    await db.execute(
        delete(FriendGrant).where(
            FriendGrant.friendship_id == friendship.id,
            FriendGrant.owner_id == auth.user.id,
            FriendGrant.viewer_id == viewer_id,
        )
    )
    db.add_all(
        FriendGrant(
            friendship_id=friendship.id,
            owner_id=auth.user.id,
            viewer_id=viewer_id,
            scope=scope,
        )
        for scope in sorted(payload.scopes)
    )
    await db.commit()
    return await _friend_view(db, friendship, auth.user.id)


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
async def block_user(payload: BlockCreate, auth: CurrentAuth, db: Db) -> BlockView:
    if payload.user_id == auth.user.id:
        raise HTTPException(status_code=400, detail="You cannot block yourself")
    target = await db.get(User, payload.user_id)
    if target is None:
        raise HTTPException(status_code=404, detail="User not found")
    existing = await db.scalar(
        select(UserBlock).where(
            UserBlock.blocker_id == auth.user.id,
            UserBlock.blocked_id == target.id,
        )
    )
    if existing is None:
        existing = UserBlock(blocker_id=auth.user.id, blocked_id=target.id)
        db.add(existing)
        await db.flush()

    friendship = await _friendship_for(db, auth.user.id, target.id)
    if friendship is not None:
        await db.delete(friendship)
    low, high = _pair(auth.user.id, target.id)
    request = await db.scalar(
        select(FriendRequest).where(
            FriendRequest.pair_low_id == low,
            FriendRequest.pair_high_id == high,
        )
    )
    if request is not None and request.status == RequestStatus.PENDING.value:
        request.status = RequestStatus.CANCELLED.value
        request.responded_at = request.updated_at = datetime.now(UTC)
    await db.commit()
    return BlockView(
        user=PublicUserView(id=target.id, display_name=target.display_name),
        created_at=existing.created_at,
    )


@router.get("/blocks", response_model=list[BlockView])
async def list_blocks(auth: CurrentAuth, db: Db) -> list[BlockView]:
    blocks = (
        await db.scalars(
            select(UserBlock)
            .where(UserBlock.blocker_id == auth.user.id)
            .order_by(UserBlock.created_at.desc())
        )
    ).all()
    views: list[BlockView] = []
    for block in blocks:
        target = await db.get(User, block.blocked_id)
        if target is not None:
            views.append(
                BlockView(
                    user=PublicUserView(id=target.id, display_name=target.display_name),
                    created_at=block.created_at,
                )
            )
    return views


@router.delete("/blocks/{user_id}", response_model=MessageResponse)
async def unblock_user(user_id: str, auth: CurrentAuth, db: Db) -> MessageResponse:
    result = await db.execute(
        delete(UserBlock).where(
            UserBlock.blocker_id == auth.user.id,
            UserBlock.blocked_id == user_id,
        )
    )
    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail="Block not found")
    await db.commit()
    return MessageResponse(detail="User unblocked")
