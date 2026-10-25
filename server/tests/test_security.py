import asyncio
import threading

import pytest

from pluris_server import security
from pluris_server.security import PasswordWorkSaturated, digest_legacy_token, digest_token


def test_secret_digests_are_domain_separated() -> None:
    token = "same-secret-material"

    assert digest_token(token, purpose="refresh") != digest_token(token, purpose="rotation_nonce")
    assert digest_token(token, purpose="refresh") != digest_token(token, purpose="password_reset")


def test_legacy_digest_is_explicitly_separate_from_new_digests() -> None:
    token = "same-secret-material"

    assert digest_legacy_token(token) != digest_token(token, purpose="refresh")


@pytest.mark.asyncio
async def test_password_verification_rejects_when_at_capacity(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(security, "_password_verify_slots", asyncio.Semaphore(0))
    monkeypatch.setattr(security, "_PASSWORD_WORK_WAIT_SECONDS", 0.01)

    with pytest.raises(PasswordWorkSaturated):
        await security.verify_password("password", "not-a-valid-hash")


@pytest.mark.asyncio
async def test_password_verification_waits_for_short_bursts(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    started = 0
    both_started = asyncio.Event()
    loop = asyncio.get_running_loop()
    release = threading.Event()

    def verify(_password: str, _encoded: str) -> bool:
        nonlocal started
        started += 1
        if started == 2:
            loop.call_soon_threadsafe(both_started.set)
        release.wait(timeout=5)
        return True

    monkeypatch.setattr(security, "_password_verify_slots", asyncio.Semaphore(2))
    monkeypatch.setattr(security._password_hash, "verify", verify)
    first = asyncio.create_task(security.verify_password("first", "hash"))
    second = asyncio.create_task(security.verify_password("second", "hash"))
    third = None
    try:
        await asyncio.wait_for(both_started.wait(), timeout=2)
        third = asyncio.create_task(security.verify_password("third", "hash"))
        await asyncio.sleep(0.01)
        assert not third.done()
    finally:
        release.set()
        tasks = [first, second]
        if third is not None:
            tasks.append(third)
        await asyncio.gather(*tasks, return_exceptions=True)

    assert third is not None
    assert third.result() is True
