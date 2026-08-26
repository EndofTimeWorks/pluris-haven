import asyncio

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

    with pytest.raises(PasswordWorkSaturated):
        await security.verify_password("password", "not-a-valid-hash")
