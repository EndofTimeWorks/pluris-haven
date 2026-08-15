from fastapi.testclient import TestClient


def test_well_known_descriptor(client: TestClient) -> None:
    response = client.get("/.well-known/pluris-haven")
    assert response.status_code == 200
    body = response.json()
    assert body["protocol_version"] == 1
    assert body["registration_enabled"] is True
    assert body["friends_enabled"] is True
    assert "friend_requests" in body["capabilities"]
    assert "security_events_v1" in body["capabilities"]
    assert "directional_sharing_grants" not in body["capabilities"]


def test_v1_server_matches_well_known(client: TestClient) -> None:
    well_known = client.get("/.well-known/pluris-haven")
    v1 = client.get("/v1/server")
    assert well_known.status_code == 200
    assert v1.status_code == 200
    assert well_known.json() == v1.json()


def test_capabilities_exclude_friends_when_disabled(client_no_friends: TestClient) -> None:
    response = client_no_friends.get("/v1/server")
    assert response.status_code == 200
    body = response.json()
    assert "friend_requests" not in body["capabilities"]
    assert "directional_sharing_grants" not in body["capabilities"]
