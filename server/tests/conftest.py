from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient

from pluris_server.config import Settings
from pluris_server.main import create_app


@pytest.fixture
def client(tmp_path) -> Iterator[TestClient]:
    settings = Settings(
        environment="test",
        database_url=f"sqlite+aiosqlite:///{tmp_path / 'test.db'}",
        jwt_secret="test-jwt-secret-that-is-long-and-unique",
        friend_code_pepper="test-friend-code-pepper-that-is-different",
        registration_enabled=True,
        friends_enabled=True,
        backup_object_dir=str(tmp_path / "backups"),
    )
    with TestClient(create_app(settings)) as test_client:
        yield test_client


def register(client: TestClient, email: str, name: str) -> dict:
    response = client.post(
        "/v1/auth/register",
        json={
            "email": email,
            "password": "correct horse battery staple",
            "display_name": name,
            "device_name": f"{name}'s test device",
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


def auth(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}
