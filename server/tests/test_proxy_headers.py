from starlette.applications import Starlette
from starlette.requests import Request
from starlette.responses import JSONResponse
from starlette.routing import Route
from starlette.testclient import TestClient
from uvicorn.middleware.proxy_headers import ProxyHeadersMiddleware

from tests.conftest import register


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


def test_failed_logins_cannot_lock_out_account_from_another_ip(client: TestClient) -> None:
    register(client, "victim@example.com", "Victim")
    client.app.state.auth_rate_limiter.max_attempts = 2
    proxied_app = ProxyHeadersMiddleware(client.app, trusted_hosts="127.0.0.1")
    with TestClient(proxied_app, client=("127.0.0.1", 8000)) as proxied:
        login = {
            "email": "victim@example.com",
            "password": "wrong password phrase",
            "device_name": "Test device",
        }
        for _ in range(2):
            failed = proxied.post(
                "/v1/auth/login",
                headers={"X-Forwarded-For": "198.51.100.4"},
                json=login,
            )
            assert failed.status_code == 401
        attacker_limited = proxied.post(
            "/v1/auth/login",
            headers={"X-Forwarded-For": "198.51.100.4"},
            json=login,
        )
        legitimate = proxied.post(
            "/v1/auth/login",
            headers={"X-Forwarded-For": "203.0.113.8"},
            json={**login, "password": "correct horse battery staple"},
        )

    assert attacker_limited.status_code == 429
    assert legitimate.status_code == 200


def test_distributed_failed_logins_share_account_bucket_without_lockout(
    client: TestClient,
) -> None:
    register(client, "victim@example.com", "Victim")
    client.app.state.auth_rate_limiter.max_attempts = 10
    client.app.state.failed_login_rate_limiter.max_attempts = 2
    proxied_app = ProxyHeadersMiddleware(client.app, trusted_hosts="127.0.0.1")
    with TestClient(proxied_app, client=("127.0.0.1", 8000)) as proxied:
        wrong = {
            "email": "victim@example.com",
            "password": "wrong password phrase",
            "device_name": "Test device",
        }
        results = [
            proxied.post(
                "/v1/auth/login",
                headers={"X-Forwarded-For": address},
                json=wrong,
            )
            for address in ("198.51.100.4", "203.0.113.8", "192.0.2.12")
        ]
        legitimate = proxied.post(
            "/v1/auth/login",
            headers={"X-Forwarded-For": "192.0.2.13"},
            json={**wrong, "password": "correct horse battery staple"},
        )

    assert [response.status_code for response in results] == [401, 401, 429]
    assert results[-1].headers["Retry-After"]
    assert legitimate.status_code == 200


def test_failed_login_limit_does_not_reveal_account_existence(client: TestClient) -> None:
    register(client, "exists@example.com", "Existing")
    client.app.state.auth_rate_limiter.max_attempts = 10
    client.app.state.failed_login_rate_limiter.max_attempts = 1
    proxied_app = ProxyHeadersMiddleware(client.app, trusted_hosts="127.0.0.1")
    with TestClient(proxied_app, client=("127.0.0.1", 8000)) as proxied:
        results = {}
        for email in ("exists@example.com", "absent@example.com"):
            results[email] = [
                proxied.post(
                    "/v1/auth/login",
                    headers={"X-Forwarded-For": address},
                    json={
                        "email": email,
                        "password": "wrong password phrase",
                        "device_name": "Test device",
                    },
                )
                for address in ("198.51.100.4", "203.0.113.8")
            ]

    assert [response.status_code for response in results["exists@example.com"]] == [401, 429]
    assert [response.status_code for response in results["absent@example.com"]] == [401, 429]
    assert results["exists@example.com"][1].json() == results["absent@example.com"][1].json()


def test_ipv6_clients_in_one_64_share_a_login_bucket(client: TestClient) -> None:
    client.app.state.auth_rate_limiter.max_attempts = 1
    proxied_app = ProxyHeadersMiddleware(client.app, trusted_hosts="127.0.0.1")
    with TestClient(proxied_app, client=("127.0.0.1", 8000)) as proxied:
        login = {
            "email": "absent@example.com",
            "password": "wrong password phrase",
            "device_name": "Test device",
        }
        responses = [
            proxied.post(
                "/v1/auth/login",
                headers={"X-Forwarded-For": address},
                json=login,
            )
            for address in ("2001:db8:abcd:1::1", "2001:db8:abcd:1::2", "2001:db8:abcd:2::1")
        ]

    assert [response.status_code for response in responses] == [401, 429, 401]


def test_ipv4_mapped_ipv6_uses_the_ipv4_login_bucket(client: TestClient) -> None:
    client.app.state.auth_rate_limiter.max_attempts = 1
    proxied_app = ProxyHeadersMiddleware(client.app, trusted_hosts="127.0.0.1")
    with TestClient(proxied_app, client=("127.0.0.1", 8000)) as proxied:
        login = {
            "email": "absent@example.com",
            "password": "wrong password phrase",
            "device_name": "Test device",
        }
        first = proxied.post(
            "/v1/auth/login",
            headers={"X-Forwarded-For": "198.51.100.4"},
            json=login,
        )
        mapped = proxied.post(
            "/v1/auth/login",
            headers={"X-Forwarded-For": "::ffff:198.51.100.4"},
            json=login,
        )

    assert first.status_code == 401
    assert mapped.status_code == 429
