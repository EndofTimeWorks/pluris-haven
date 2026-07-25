from fastapi.testclient import TestClient

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
