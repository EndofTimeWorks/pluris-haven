import asyncio

import pytest
from fastapi.testclient import TestClient

from pluris_server.config import Settings
from pluris_server.http_security import RequestBodyLimitMiddleware
from pluris_server.main import create_app


@pytest.mark.parametrize("environment", ["development", "test", "production"])
def test_placeholder_secrets_are_rejected_in_every_environment(environment: str) -> None:
    with pytest.raises(RuntimeError, match="JWT_SECRET"):
        create_app(
            Settings(
                environment=environment,
                jwt_secret="development-only-change-me",
                friend_code_pepper="development-only-change-me",
            )
        )


def _production_settings(**overrides: object) -> Settings:
    values: dict[str, object] = {
        "environment": "production",
        "database_url": "postgresql+asyncpg://pluris:password@db/pluris",
        "jwt_secret": "test-jwt-secret-that-is-long-and-unique",
        "friend_code_pepper": "test-friend-code-pepper-that-is-different",
        "server_id": "019ff449-469e-7630-8fb6-d295796ccb0a",
        "public_url": "https://api.example.test",
    }
    values.update(overrides)
    return Settings(**values)


def test_production_requires_postgresql() -> None:
    settings = _production_settings(database_url="mysql+aiomysql://pluris:password@db/pluris")
    with pytest.raises(RuntimeError, match="PostgreSQL"):
        settings.validate_for_startup()


def test_production_requires_https_public_url() -> None:
    settings = _production_settings(public_url="http://api.example.test")
    with pytest.raises(RuntimeError, match="HTTPS URL"):
        settings.validate_for_startup()


def test_production_registration_is_closed_until_email_verification_exists() -> None:
    settings = _production_settings(registration_enabled=True)
    with pytest.raises(RuntimeError, match="verified email"):
        settings.validate_for_startup()


def test_comma_separated_cors_origins(monkeypatch) -> None:
    monkeypatch.setenv(
        "PLURIS_CORS_ORIGINS",
        "https://app.example.com, https://admin.example.com",
    )
    settings = Settings(_env_file=None)
    assert settings.cors_origins == (
        "https://app.example.com",
        "https://admin.example.com",
    )


def test_security_headers_and_host_validation(client: TestClient) -> None:
    response = client.get("/health")
    assert response.headers["x-content-type-options"] == "nosniff"
    assert response.headers["x-frame-options"] == "DENY"
    assert response.headers["referrer-policy"] == "no-referrer"
    assert "strict-transport-security" not in response.headers

    rejected = client.get("http://untrusted.example/health")
    assert rejected.status_code == 400


def test_cors_allows_browser_backup_digest_header(tmp_path) -> None:
    settings = Settings(
        environment="test",
        database_url=f"sqlite+aiosqlite:///{tmp_path / 'cors.db'}",
        jwt_secret="test-jwt-secret-that-is-long-and-unique",
        friend_code_pepper="test-friend-code-pepper-that-is-different",
        cors_origins=("https://app.example.com",),
    )
    with TestClient(create_app(settings)) as client:
        preflight = client.options(
            "/v1/backups/snapshots/snapshot/chunks/0",
            headers={
                "Origin": "https://app.example.com",
                "Access-Control-Request-Method": "PUT",
                "Access-Control-Request-Headers": ("authorization,content-type,x-content-sha256"),
            },
        )
        response = client.get(
            "/health",
            headers={"Origin": "https://app.example.com"},
        )

    assert preflight.status_code == 200
    assert preflight.headers["access-control-allow-origin"] == "https://app.example.com"
    assert "x-content-sha256" in preflight.headers["access-control-allow-headers"].lower()
    assert response.headers["access-control-expose-headers"].lower() == "x-content-sha256"


def test_friends_feature_is_closed_by_default(tmp_path) -> None:
    settings = Settings(
        environment="test",
        database_url=f"sqlite+aiosqlite:///{tmp_path / 'disabled.db'}",
        jwt_secret="test-jwt-secret-that-is-long-and-unique",
        friend_code_pepper="test-friend-code-pepper-that-is-different",
        friends_enabled=False,
    )
    with TestClient(create_app(settings)) as client:
        response = client.get("/v1/friends")
    assert response.status_code == 503


def test_disabled_registration_does_not_touch_rate_limiter(tmp_path, monkeypatch) -> None:
    settings = Settings(
        environment="test",
        database_url=f"sqlite+aiosqlite:///{tmp_path / 'registration-disabled.db'}",
        jwt_secret="test-jwt-secret-that-is-long-and-unique",
        friend_code_pepper="test-friend-code-pepper-that-is-different",
    )
    with TestClient(create_app(settings)) as client:
        calls = 0

        async def retry_after(_keys: list[str]) -> None:
            nonlocal calls
            calls += 1
            return None

        monkeypatch.setattr(client.app.state.auth_rate_limiter, "retry_after", retry_after)
        response = client.post(
            "/v1/auth/register",
            json={
                "email": "closed@example.com",
                "password": "correct horse battery staple",
                "display_name": "Closed",
                "device_name": "Phone",
            },
        )
    assert response.status_code == 503
    assert calls == 0


def test_auth_requests_reject_oversized_bodies(client: TestClient) -> None:
    response = client.post(
        "/v1/auth/login",
        content=b"x" * (64 * 1024 + 1),
        headers={"content-type": "application/json"},
    )

    assert response.status_code == 413


def test_body_limit_preserves_partial_request_before_disconnect() -> None:
    received: list[dict[str, object]] = []

    async def app(_scope, receive, _send) -> None:
        received.append(await receive())
        received.append(await receive())

    pending = iter(
        [
            {"type": "http.request", "body": b"part", "more_body": True},
            {"type": "http.disconnect"},
        ]
    )

    async def receive() -> dict[str, object]:
        return next(pending)

    async def send(_message: dict[str, object]) -> None:
        return None

    asyncio.run(
        RequestBodyLimitMiddleware(app, maximum_bytes=64)(
            {"type": "http", "path": "/v1/auth/login", "headers": []},
            receive,
            send,
        )
    )

    assert received == [
        {"type": "http.request", "body": b"part", "more_body": False},
        {"type": "http.disconnect"},
    ]
