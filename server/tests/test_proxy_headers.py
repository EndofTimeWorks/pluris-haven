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
