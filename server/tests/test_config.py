import pytest
from fastapi.testclient import TestClient

from pluris_server.config import Settings
from pluris_server.main import create_app


def test_production_rejects_placeholder_secrets() -> None:
    with pytest.raises(RuntimeError, match="JWT_SECRET"):
        create_app(Settings(environment="production"))


def _production_settings(**overrides: object) -> Settings:
    values: dict[str, object] = {
        "environment": "production",
        "database_url": "postgresql+asyncpg://pluris:password@db/pluris",
        "jwt_secret": "test-jwt-secret-that-is-long-and-unique",
        "friend_code_pepper": "test-friend-code-pepper-that-is-different",
        "server_id": "019ff449-469e-7630-8fb6-d295796ccb0a",
    }
    values.update(overrides)
    return Settings(**values)


def test_production_requires_postgresql() -> None:
    settings = _production_settings(database_url="mysql+aiomysql://pluris:password@db/pluris")
    with pytest.raises(RuntimeError, match="PostgreSQL"):
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


def test_registration_is_closed_by_default(tmp_path) -> None:
    settings = Settings(
        environment="test",
        database_url=f"sqlite+aiosqlite:///{tmp_path / 'registration-disabled.db'}",
        jwt_secret="test-jwt-secret-that-is-long-and-unique",
        friend_code_pepper="test-friend-code-pepper-that-is-different",
    )
    with TestClient(create_app(settings)) as client:
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
