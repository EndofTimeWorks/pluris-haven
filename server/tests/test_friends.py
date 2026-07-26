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


def test_friend_request_and_directional_grants(client: TestClient) -> None:
    alice, bob, friendship = connect_users(client)

    assert friendship["user"]["display_name"] == "Alice"
    assert friendship["grants_to_them"] == []
    assert friendship["grants_from_them"] == []

    alice_list = client.get("/v1/friends", headers=auth(alice["access_token"]))
    assert alice_list.status_code == 200
    assert alice_list.json()[0]["user"]["display_name"] == "Bob"
    assert alice_list.json()[0]["grants_to_them"] == []

    friendship_id = friendship["friendship_id"]
    grant = client.put(
        f"/v1/friends/{friendship_id}/grants",
        headers=auth(alice["access_token"]),
        json={"scopes": ["front_status", "members"]},
    )
    assert grant.status_code == 200, grant.text
    assert grant.json()["grants_to_them"] == ["front_status", "members"]

    bob_list = client.get("/v1/friends", headers=auth(bob["access_token"]))
    assert bob_list.json()[0]["grants_from_them"] == ["front_status", "members"]
    assert bob_list.json()[0]["grants_to_them"] == []

    invalid = client.put(
        f"/v1/friends/{friendship_id}/grants",
        headers=auth(alice["access_token"]),
        json={"scopes": ["everything"]},
    )
    assert invalid.status_code == 422

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
