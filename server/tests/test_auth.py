import asyncio
import hashlib

from fastapi.testclient import TestClient
from sqlalchemy import func, select

from pluris_server.models import BackupSnapshot, User
from tests.conftest import auth, register


def test_registration_login_refresh_and_session_revocation(client: TestClient) -> None:
    registered = register(client, "test@example.com", "Test User")

    me = client.get("/v1/auth/me", headers=auth(registered["access_token"]))
    assert me.status_code == 200
    assert me.json()["email"] == "test@example.com"

    login = client.post(
        "/v1/auth/login",
        json={
            "email": "TEST@example.com",
            "password": "correct horse battery staple",
            "device_name": "Second device",
        },
    )
    assert login.status_code == 200
    second = login.json()

    sessions = client.get("/v1/auth/sessions", headers=auth(second["access_token"]))
    assert sessions.status_code == 200
    assert len(sessions.json()) == 2
    first_session = next(
        row for row in sessions.json() if row["device_name"].endswith("test device")
    )

    revoked = client.delete(
        f"/v1/auth/sessions/{first_session['id']}", headers=auth(second["access_token"])
    )
    assert revoked.status_code == 200
    assert client.get("/v1/auth/me", headers=auth(registered["access_token"])).status_code == 401

    refresh = client.post("/v1/auth/refresh", json={"refresh_token": second["refresh_token"]})
    assert refresh.status_code == 200
    rotated = refresh.json()
    assert rotated["refresh_token"] != second["refresh_token"]
    client.app.state.settings.refresh_reuse_grace_seconds = 0
    assert (
        client.post("/v1/auth/refresh", json={"refresh_token": second["refresh_token"]}).status_code
        == 401
    )
    assert client.get("/v1/auth/me", headers=auth(rotated["access_token"])).status_code == 401
    assert (
        client.post(
            "/v1/auth/refresh", json={"refresh_token": rotated["refresh_token"]}
        ).status_code
        == 401
    )


def test_logout_revokes_access_and_refresh_tokens(client: TestClient) -> None:
    registered = register(client, "logout@example.com", "Logout User")
    logout = client.post("/v1/auth/logout", headers=auth(registered["access_token"]))
    assert logout.status_code == 200
    assert client.get("/v1/auth/me", headers=auth(registered["access_token"])).status_code == 401
    assert (
        client.post(
            "/v1/auth/refresh", json={"refresh_token": registered["refresh_token"]}
        ).status_code
        == 401
    )


def test_duplicate_registration_and_bad_password(client: TestClient) -> None:
    register(client, "same@example.com", "First")
    duplicate = client.post(
        "/v1/auth/register",
        json={
            "email": "SAME@example.com",
            "password": "another correct horse battery staple",
            "display_name": "Second",
            "device_name": "Phone",
        },
    )
    assert duplicate.status_code == 409

    bad_login = client.post(
        "/v1/auth/login",
        json={
            "email": "same@example.com",
            "password": "wrong",
            "device_name": "Phone",
        },
    )
    assert bad_login.status_code == 401


def test_refresh_requests_are_rate_limited(client: TestClient) -> None:
    payload = {"refresh_token": "x" * 32}
    responses = [client.post("/v1/auth/refresh", json=payload) for _ in range(11)]

    assert all(response.status_code == 401 for response in responses[:10])
    assert responses[-1].status_code == 429
    assert responses[-1].headers["Retry-After"].isdigit()


def test_immediate_refresh_retry_returns_the_same_rotated_token(client: TestClient) -> None:
    registered = register(client, "refresh-retry@example.com", "Refresh retry")
    payload = {"refresh_token": registered["refresh_token"]}

    first = client.post("/v1/auth/refresh", json=payload)
    retry = client.post("/v1/auth/refresh", json=payload)

    assert first.status_code == 200, first.text
    assert retry.status_code == 200, retry.text
    assert retry.json()["refresh_token"] == first.json()["refresh_token"]
    assert client.get("/v1/auth/me", headers=auth(retry.json()["access_token"])).status_code == 200


def test_refresh_rate_limit_is_not_shared_by_clients_behind_one_ip(
    client: TestClient,
) -> None:
    for _ in range(10):
        assert client.post("/v1/auth/refresh", json={"refresh_token": "a" * 32}).status_code == 401

    unrelated = client.post("/v1/auth/refresh", json={"refresh_token": "b" * 32})
    assert unrelated.status_code == 401


def test_account_deletion_requires_password_and_removes_server_data(client: TestClient) -> None:
    registered = register(client, "delete@example.com", "Delete User")
    headers = auth(registered["access_token"])
    payload = {
        "snapshot_id": "delete-snapshot",
        "manifest_sha256": "f" * 64,
        "chunk_count": 1,
        "total_bytes": 4,
    }
    created = client.post("/v1/backups/snapshots", headers=headers, json=payload)
    assert created.status_code == 201, created.text

    body = b"data"
    uploaded = client.put(
        "/v1/backups/snapshots/delete-snapshot/chunks/0",
        headers={**headers, "X-Content-SHA256": hashlib.sha256(body).hexdigest()},
        content=body,
    )
    assert uploaded.status_code == 200, uploaded.text

    wrong_password = client.request(
        "DELETE",
        "/v1/auth/account",
        headers=headers,
        json={"password": "not the password"},
    )
    assert wrong_password.status_code == 401
    assert client.get("/v1/auth/me", headers=headers).status_code == 200

    deleted = client.request(
        "DELETE",
        "/v1/auth/account",
        headers=headers,
        json={"password": "correct horse battery staple"},
    )
    assert deleted.status_code == 200, deleted.text
    assert deleted.json() == {"detail": "Account deleted"}
    assert client.get("/v1/auth/me", headers=headers).status_code == 401
    assert (
        client.post(
            "/v1/auth/refresh", json={"refresh_token": registered["refresh_token"]}
        ).status_code
        == 401
    )
    login = client.post(
        "/v1/auth/login",
        json={
            "email": "delete@example.com",
            "password": "correct horse battery staple",
            "device_name": "Phone",
        },
    )
    assert login.status_code == 401

    async def assert_deleted() -> None:
        async with client.app.state.session_factory() as session:
            assert (
                await session.scalar(select(User).where(User.email == "delete@example.com")) is None
            )
            assert await session.scalar(select(func.count(BackupSnapshot.id))) == 0

    asyncio.run(assert_deleted())
    storage_root = client.app.state.backup_object_store.root
    assert not any(storage_root.iterdir())
