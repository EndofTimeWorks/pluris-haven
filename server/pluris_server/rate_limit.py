import hashlib
import hmac
from collections.abc import Callable
from datetime import UTC, datetime, timedelta
from math import ceil

from sqlalchemy import delete, func, select, text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from pluris_server.models import RateLimitEvent


class DatabaseRateLimiter:
    """A shared sliding-window limiter backed by the application database."""

    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
        max_attempts: int,
        window_seconds: int,
        key_pepper: str,
        clock: Callable[[], datetime] = lambda: datetime.now(UTC),
    ) -> None:
        self._session_factory = session_factory
        self.max_attempts = max_attempts
        self.window_seconds = window_seconds
        self._key_pepper = key_pepper.encode()
        self._clock = clock

    async def retry_after(self, keys: list[str]) -> int | None:
        unique_keys = sorted({self._digest_key(key) for key in keys})
        if not unique_keys:
            return None

        now = self._clock()
        cutoff = now - timedelta(seconds=self.window_seconds)
        expires_at = now + timedelta(seconds=self.window_seconds)
        async with self._session_factory() as session, session.begin():
            if session.bind is not None and session.bind.dialect.name == "postgresql":
                for key in unique_keys:
                    await session.execute(
                        text("SELECT pg_advisory_xact_lock(hashtextextended(:key, 0))"),
                        {"key": key},
                    )

            await session.execute(delete(RateLimitEvent).where(RateLimitEvent.expires_at <= now))
            retry_at: datetime | None = None
            for key in unique_keys:
                count, earliest_expiry = (
                    await session.execute(
                        select(
                            func.count(RateLimitEvent.id),
                            func.min(RateLimitEvent.expires_at),
                        ).where(
                            RateLimitEvent.bucket_key == key,
                            RateLimitEvent.occurred_at > cutoff,
                        )
                    )
                ).one()
                if count >= self.max_attempts and earliest_expiry is not None:
                    if earliest_expiry.tzinfo is None:
                        earliest_expiry = earliest_expiry.replace(tzinfo=UTC)
                    retry_at = max(retry_at or earliest_expiry, earliest_expiry)

            if retry_at is not None:
                return max(1, ceil((retry_at - now).total_seconds()))

            session.add_all(
                RateLimitEvent(
                    bucket_key=key,
                    occurred_at=now,
                    expires_at=expires_at,
                )
                for key in unique_keys
            )
        return None

    def _digest_key(self, key: str) -> str:
        return hmac.new(
            self._key_pepper,
            b"pluris-haven:rate-limit-key:v1\0" + key.encode(),
            hashlib.sha256,
        ).hexdigest()
