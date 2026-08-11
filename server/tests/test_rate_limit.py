from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine

from pluris_server.database import Base, create_session_factory
from pluris_server.models import RateLimitEvent
from pluris_server.rate_limit import DatabaseRateLimiter


@pytest.mark.asyncio
async def test_rate_limiter_uses_a_shared_sliding_window(tmp_path) -> None:
    engine = create_async_engine(f"sqlite+aiosqlite:///{tmp_path / 'limits.db'}")
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    session_factory = create_session_factory(engine)
    current_time = [datetime(2026, 8, 10, tzinfo=UTC)]

    def clock() -> datetime:
        return current_time[0]

    first_process = DatabaseRateLimiter(
        session_factory,
        max_attempts=2,
        window_seconds=5,
        key_pepper="test-rate-limit-pepper",
        clock=clock,
    )
    second_process = DatabaseRateLimiter(
        session_factory,
        max_attempts=2,
        window_seconds=5,
        key_pepper="test-rate-limit-pepper",
        clock=clock,
    )

    assert await first_process.retry_after(["client"]) is None
    assert await second_process.retry_after(["client"]) is None
    assert await first_process.retry_after(["client"]) == 5

    async with session_factory() as session:
        stored_keys = (await session.scalars(select(RateLimitEvent.bucket_key))).all()
    assert stored_keys
    assert all(len(key) == 64 and "client" not in key for key in stored_keys)

    current_time[0] += timedelta(seconds=5)
    assert await second_process.retry_after(["client"]) is None
    await engine.dispose()
