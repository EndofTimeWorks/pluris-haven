import hashlib

from fastapi.testclient import TestClient

from tests.conftest import auth, register


def test_authenticated_backup_snapshot_upload_download_and_delete(client: TestClient) -> None:
    user = register(client, "backup@example.com", "Backup user")
    headers = auth(user["access_token"])
    payload = {
        "snapshot_id": "snapshot-1",
        "manifest_sha256": "a" * 64,
        "chunk_count": 1,
        "total_bytes": 13,
    }

    created = client.post("/v1/backups/snapshots", headers=headers, json=payload)
    assert created.status_code == 201, created.text
    assert created.json()["uploaded_chunks"] == 0

    body = b"opaque-chunk"
    chunk_headers = {
        **headers,
        "X-Content-SHA256": hashlib.sha256(body).hexdigest(),
    }
    uploaded = client.put(
        "/v1/backups/snapshots/snapshot-1/chunks/0",
        headers=chunk_headers,
        content=body,
    )
    assert uploaded.status_code == 200, uploaded.text
    assert uploaded.json()["size"] == len(body)

    listed = client.get("/v1/backups/snapshots", headers=headers)
    assert listed.status_code == 200
    assert listed.json()[0]["uploaded_chunks"] == 1
    assert listed.json()[0]["uploaded_bytes"] == len(body)

    downloaded = client.get("/v1/backups/snapshots/snapshot-1/chunks/0", headers=headers)
    assert downloaded.status_code == 200
    assert downloaded.content == body
    assert downloaded.headers["X-Content-SHA256"] == chunk_headers["X-Content-SHA256"]

    duplicate = client.post("/v1/backups/snapshots", headers=headers, json=payload)
    assert duplicate.status_code == 409
    deleted = client.delete("/v1/backups/snapshots/snapshot-1", headers=headers)
    assert deleted.status_code == 200
    assert client.get("/v1/backups/snapshots", headers=headers).json() == []
