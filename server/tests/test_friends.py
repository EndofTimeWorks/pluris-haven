from fastapi.testclient import TestClient

from tests.conftest import auth, register


def connect_users(client: TestClient) -> tuple[dict, dict, dict]:
    alice = register(client, "alice@example.com", "Alice")
    bob = register(client, "bob@example.com", "Bob")
    created = client.post(
        "/v1/friends/requests",
        headers=auth(alice["access_token"]),
        json={"friend_code": bob["friend_code"]},
    )
    assert created.status_code == 201, created.text
    request = created.json()
    accepted = client.post(
        f"/v1/friends/requests/{request['id']}/accept",
        headers=auth(bob["access_token"]),
    )
    assert accepted.status_code == 200, accepted.text
    return alice, bob, accepted.json()


def test_friend_request_and_relationship_removal(client: TestClient) -> None:
    alice, bob, friendship = connect_users(client)

    assert friendship["user"]["display_name"] == "Alice"

    alice_list = client.get("/v1/friends", headers=auth(alice["access_token"]))
    assert alice_list.status_code == 200
    assert alice_list.json()[0]["user"]["display_name"] == "Bob"
    friendship_id = friendship["friendship_id"]
    removed = client.delete(f"/v1/friends/{friendship_id}", headers=auth(alice["access_token"]))
    assert removed.status_code == 200
    assert client.get("/v1/friends", headers=auth(bob["access_token"])).json() == []


def test_decline_cancel_rotation_and_re_request(client: TestClient) -> None:
    alice = register(client, "alice2@example.com", "Alice")
    bob = register(client, "bob2@example.com", "Bob")

    first = client.post(
        "/v1/friends/requests",
        headers=auth(alice["access_token"]),
        json={"friend_code": bob["friend_code"]},
    ).json()
    declined = client.post(
        f"/v1/friends/requests/{first['id']}/decline",
        headers=auth(bob["access_token"]),
    )
    assert declined.status_code == 200

    second = client.post(
        "/v1/friends/requests",
        headers=auth(alice["access_token"]),
        json={"friend_code": bob["friend_code"]},
    )
    assert second.status_code == 429
    assert int(second.headers["Retry-After"]) > 0

    charlie = register(client, "charlie2@example.com", "Charlie")
    third = client.post(
        "/v1/friends/requests",
        headers=auth(alice["access_token"]),
        json={"friend_code": charlie["friend_code"]},
    )
    assert third.status_code == 201, third.text
    cancelled = client.post(
        f"/v1/friends/requests/{third.json()['id']}/cancel",
        headers=auth(alice["access_token"]),
    )
    assert cancelled.status_code == 200
    re_requested = client.post(
        "/v1/friends/requests",
        headers=auth(alice["access_token"]),
        json={"friend_code": charlie["friend_code"]},
    )
    assert re_requested.status_code == 201, re_requested.text

    rotated = client.post("/v1/friends/code/rotate", headers=auth(bob["access_token"]))
    assert rotated.status_code == 200
    assert rotated.json()["friend_code"] != bob["friend_code"]
    stale = client.post(
        "/v1/friends/requests",
        headers=auth(alice["access_token"]),
        json={"friend_code": bob["friend_code"]},
    )
    assert stale.status_code == 404


def test_block_removes_friendship_and_prevents_new_requests(client: TestClient) -> None:
    alice, bob, friendship = connect_users(client)
    bob_me = client.get("/v1/auth/me", headers=auth(bob["access_token"])).json()

    blocked = client.post(
        "/v1/friends/blocks",
        headers=auth(alice["access_token"]),
        json={"user_id": bob_me["id"]},
    )
    assert blocked.status_code == 201, blocked.text
    assert client.get("/v1/friends", headers=auth(alice["access_token"])).json() == []

    request = client.post(
        "/v1/friends/requests",
        headers=auth(bob["access_token"]),
        json={"friend_code": alice["friend_code"]},
    )
    assert request.status_code == 404

    unblocked = client.delete(
        f"/v1/friends/blocks/{bob_me['id']}", headers=auth(alice["access_token"])
    )
    assert unblocked.status_code == 200


def test_blocking_requires_an_existing_relationship_or_request(client: TestClient) -> None:
    alice = register(client, "block-alice@example.com", "Alice")
    bob = register(client, "block-bob@example.com", "Bob")
    bob_me = client.get("/v1/auth/me", headers=auth(bob["access_token"])).json()

    blocked = client.post(
        "/v1/friends/blocks",
        headers=auth(alice["access_token"]),
        json={"user_id": bob_me["id"]},
    )

    assert blocked.status_code == 404
    assert blocked.json()["detail"] == "User is not available to block"


def test_friend_request_endpoint_is_rate_limited(client: TestClient) -> None:
    alice = register(client, "rate-alice@example.com", "Rate Alice")
    bob = register(client, "rate-bob@example.com", "Rate Bob")

    responses = [
        client.post(
            "/v1/friends/requests",
            headers=auth(alice["access_token"]),
            json={"friend_code": bob["friend_code"]},
        )
        for _ in range(11)
    ]

    assert all(response.status_code != 429 for response in responses[:10])
    assert responses[-1].status_code == 429
    assert responses[-1].headers["Retry-After"].isdigit()


def test_friend_code_rotation_is_rate_limited(client: TestClient) -> None:
    user = register(client, "rotate-rate@example.com", "Rotate Rate")

    responses = [
        client.post(
            "/v1/friends/code/rotate",
            headers=auth(user["access_token"]),
        )
        for _ in range(11)
    ]

    assert all(response.status_code == 200 for response in responses[:10])
    assert responses[-1].status_code == 429
    assert responses[-1].headers["Retry-After"].isdigit()
