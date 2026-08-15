import json
import logging

import pytest
from fastapi.testclient import TestClient

from tests.conftest import auth, register


def _security_payloads(caplog: pytest.LogCaptureFixture) -> list[dict[str, str]]:
    return [
        json.loads(record.message) for record in caplog.records if record.name == "pluris.security"
    ]


def test_auth_signals_are_aggregate_and_exclude_request_data(
    client: TestClient,
    caplog: pytest.LogCaptureFixture,
) -> None:
    register(client, "private-address@example.com", "Private user")
    caplog.clear()
    caplog.set_level(logging.WARNING, logger="pluris.security")

    rejected = client.post(
        "/v1/auth/login",
        json={
            "email": "private-address@example.com",
            "password": "not-the-private-password",
            "device_name": "Private device name",
        },
    )

    assert rejected.status_code == 401
    assert _security_payloads(caplog) == [
        {
            "event": "security.auth.rejected",
            "operation": "login",
            "reason": "invalid_credentials",
        }
    ]
    assert "private-address" not in caplog.text
    assert "not-the-private-password" not in caplog.text
    assert "Private device name" not in caplog.text


def test_missing_bearer_token_does_not_create_unbounded_security_logs(
    client: TestClient,
    caplog: pytest.LogCaptureFixture,
) -> None:
    caplog.set_level(logging.WARNING, logger="pluris.security")

    response = client.get("/v1/auth/me")

    assert response.status_code == 401
    assert _security_payloads(caplog) == []


def test_rate_limit_and_capacity_rejections_emit_distinct_signals(
    client: TestClient,
    caplog: pytest.LogCaptureFixture,
) -> None:
    registered = register(client, "signals@example.com", "Signals user")
    client.app.state.auth_rate_limiter.max_attempts = 1
    caplog.clear()
    caplog.set_level(logging.WARNING, logger="pluris.security")

    login_payload = {
        "email": "signals@example.com",
        "password": "wrong-password",
        "device_name": "Phone",
    }
    assert client.post("/v1/auth/login", json=login_payload).status_code == 401
    assert client.post("/v1/auth/login", json=login_payload).status_code == 429

    client.app.state.settings.backup_max_snapshots_per_user = 1
    headers = auth(registered["access_token"])
    for snapshot_id in ("first", "second"):
        response = client.post(
            "/v1/backups/snapshots",
            headers=headers,
            json={
                "snapshot_id": snapshot_id,
                "manifest_sha256": "a" * 64,
                "chunk_count": 1,
                "total_bytes": 1,
            },
        )
    assert response.status_code == 413

    assert _security_payloads(caplog) == [
        {
            "event": "security.auth.rejected",
            "operation": "login",
            "reason": "invalid_credentials",
        },
        {
            "event": "security.auth.rate_limited",
            "operation": "login",
            "reason": "rate_limit",
        },
        {
            "event": "security.capacity.rejected",
            "operation": "backup_snapshot",
            "reason": "snapshot_limit",
        },
    ]
