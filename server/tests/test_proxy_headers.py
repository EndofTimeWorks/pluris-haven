from starlette.applications import Starlette
from starlette.requests import Request
from starlette.responses import JSONResponse
from starlette.routing import Route
from starlette.testclient import TestClient
from uvicorn.middleware.proxy_headers import ProxyHeadersMiddleware


async def _client_address(request: Request) -> JSONResponse:
    return JSONResponse({"host": request.client.host})


def _client_for(peer: str) -> TestClient:
    app = Starlette(routes=[Route("/", _client_address)])
    return TestClient(
        ProxyHeadersMiddleware(app, trusted_hosts="127.0.0.1"),
        client=(peer, 8000),
    )


def test_trusted_proxy_uses_forwarded_client_address() -> None:
    with _client_for("127.0.0.1") as client:
        response = client.get("/", headers={"X-Forwarded-For": "198.51.100.4"})

    assert response.json() == {"host": "198.51.100.4"}


def test_direct_client_ignores_forwarded_client_address() -> None:
    with _client_for("198.51.100.4") as client:
        response = client.get("/", headers={"X-Forwarded-For": "203.0.113.8"})

    assert response.json() == {"host": "198.51.100.4"}


def test_untrusted_proxy_cannot_choose_client_address() -> None:
    with _client_for("10.0.0.2") as client:
        response = client.get("/", headers={"X-Forwarded-For": "203.0.113.8"})

    assert response.json() == {"host": "10.0.0.2"}


def test_application_rate_limits_forwarded_clients_independently(client: TestClient) -> None:
    client.app.state.auth_rate_limiter.max_attempts = 1
    proxied_app = ProxyHeadersMiddleware(client.app, trusted_hosts="127.0.0.1")
    with TestClient(proxied_app, client=("127.0.0.1", 8000)) as proxied:
        first = proxied.post(
            "/v1/auth/login",
            headers={"X-Forwarded-For": "198.51.100.4"},
            json={
                "email": "first@example.com",
                "password": "correct horse battery staple",
                "device_name": "Test device",
            },
        )
        second = proxied.post(
            "/v1/auth/login",
            headers={"X-Forwarded-For": "203.0.113.8"},
            json={
                "email": "second@example.com",
                "password": "correct horse battery staple",
                "device_name": "Test device",
            },
        )

    assert first.status_code == 401
    assert second.status_code == 401
