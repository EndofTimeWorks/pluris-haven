import math
import threading
import time
from collections.abc import Callable
from dataclasses import dataclass


@dataclass
class _Bucket:
    count: int
    reset_at: float


class InMemoryRateLimiter:
    """A small per-process fixed-window limiter for sensitive endpoints."""

    def __init__(
        self,
        max_attempts: int,
        window_seconds: int,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        self.max_attempts = max_attempts
        self.window_seconds = window_seconds
        self._clock = clock
        self._buckets: dict[str, _Bucket] = {}
        self._lock = threading.Lock()

    async def retry_after(self, keys: list[str]) -> int | None:
        now = self._clock()
        with self._lock:
            self._remove_expired(now)
            retry_at = 0.0
            for key in set(keys):
                bucket = self._buckets.get(key)
                if bucket is not None and bucket.count >= self.max_attempts:
                    retry_at = max(retry_at, bucket.reset_at)

            if retry_at > now:
                return max(1, math.ceil(retry_at - now))

            reset_at = now + self.window_seconds
            for key in set(keys):
                bucket = self._buckets.get(key)
                if bucket is None:
                    self._buckets[key] = _Bucket(count=1, reset_at=reset_at)
                else:
                    bucket.count += 1
            return None

    def _remove_expired(self, now: float) -> None:
        expired = [key for key, bucket in self._buckets.items() if bucket.reset_at <= now]
        for key in expired:
            del self._buckets[key]
