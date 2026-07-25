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


def test_backup_upload_resumes_and_isolated_from_other_users(client: TestClient) -> None:
    owner = register(client, "resume-owner@example.com", "Resume owner")
    other_user = register(client, "resume-other@example.com", "Resume other")
    owner_headers = auth(owner["access_token"])
    other_headers = auth(other_user["access_token"])
    first_chunk = b"first opaque chunk"
    second_chunk = b"second opaque chunk"
    payload = {
        "snapshot_id": "resumable-snapshot",
        "manifest_sha256": "b" * 64,
        "chunk_count": 2,
        "total_bytes": len(first_chunk) + len(second_chunk),
    }

    created = client.post("/v1/backups/snapshots", headers=owner_headers, json=payload)
    assert created.status_code == 201, created.text

    first_headers = {
        **owner_headers,
        "X-Content-SHA256": hashlib.sha256(first_chunk).hexdigest(),
    }
    uploaded_first = client.put(
        "/v1/backups/snapshots/resumable-snapshot/chunks/0",
        headers=first_headers,
        content=first_chunk,
    )
    assert uploaded_first.status_code == 200, uploaded_first.text

    progress = client.get("/v1/backups/snapshots", headers=owner_headers)
    assert progress.status_code == 200
    assert progress.json()[0]["uploaded_chunks"] == 1
    assert progress.json()[0]["uploaded_bytes"] == len(first_chunk)

    retry = client.put(
        "/v1/backups/snapshots/resumable-snapshot/chunks/0",
        headers=first_headers,
        content=first_chunk,
    )
    assert retry.status_code == 200, retry.text

    conflicting_retry = client.put(
        "/v1/backups/snapshots/resumable-snapshot/chunks/0",
        headers={
            **owner_headers,
            "X-Content-SHA256": hashlib.sha256(b"different").hexdigest(),
        },
        content=b"different",
    )
    assert conflicting_retry.status_code == 409

    missing = client.get(
        "/v1/backups/snapshots/resumable-snapshot/chunks/1",
        headers=owner_headers,
    )
    assert missing.status_code == 404

    second_headers = {
        **owner_headers,
        "X-Content-SHA256": hashlib.sha256(second_chunk).hexdigest(),
    }
    uploaded_second = client.put(
        "/v1/backups/snapshots/resumable-snapshot/chunks/1",
        headers=second_headers,
        content=second_chunk,
    )
    assert uploaded_second.status_code == 200, uploaded_second.text

    complete = client.get("/v1/backups/snapshots", headers=owner_headers)
    assert complete.json()[0]["uploaded_chunks"] == 2
    assert complete.json()[0]["uploaded_bytes"] == payload["total_bytes"]

    assert client.get("/v1/backups/snapshots", headers=other_headers).json() == []
    assert (
        client.get(
            "/v1/backups/snapshots/resumable-snapshot/chunks/0",
            headers=other_headers,
        ).status_code
        == 404
    )
    assert (
        client.delete(
            "/v1/backups/snapshots/resumable-snapshot",
            headers=other_headers,
        ).status_code
        == 404
    )
