import pytest

from pluris_server.rate_limit import InMemoryRateLimiter


@pytest.mark.asyncio
async def test_rate_limiter_blocks_until_window_expires() -> None:
    clock = iter([100.0, 100.0, 100.0, 106.0])
    limiter = InMemoryRateLimiter(
        max_attempts=2,
        window_seconds=5,
        clock=lambda: next(clock),
    )

    assert await limiter.retry_after(["client"]) is None
    assert await limiter.retry_after(["client"]) is None
    assert await limiter.retry_after(["client"]) == 5

    assert await limiter.retry_after(["client"]) is None
