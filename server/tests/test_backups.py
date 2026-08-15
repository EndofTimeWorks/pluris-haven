import asyncio
import hashlib

from fastapi.testclient import TestClient
from sqlalchemy import func, select

from pluris_server.backup_cleanup import sweep_backup_deletions
from pluris_server.models import BackupDeletion, BackupSnapshot
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

    events = client.get("/v1/auth/security-events", headers=headers)
    assert events.status_code == 200
    assert [event["event_type"] for event in events.json()] == ["backup_recovery_started"]

    duplicate = client.post("/v1/backups/snapshots", headers=headers, json=payload)
    assert duplicate.status_code == 409
    deleted = client.delete("/v1/backups/snapshots/snapshot-1", headers=headers)
    assert deleted.status_code == 200
    assert client.get("/v1/backups/snapshots", headers=headers).json() == []
    events = client.get("/v1/auth/security-events", headers=headers)
    assert [event["event_type"] for event in events.json()] == [
        "backup_deleted",
        "backup_recovery_started",
    ]


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


def test_backup_upload_rejects_stream_after_chunk_limit(client: TestClient) -> None:
    user = register(client, "bounded-upload@example.com", "Bounded upload")
    headers = auth(user["access_token"])
    settings = client.app.state.settings
    settings.backup_max_chunk_bytes = 4
    snapshot_id = "bounded-upload"
    assert (
        client.post(
            "/v1/backups/snapshots",
            headers=headers,
            json={
                "snapshot_id": snapshot_id,
                "manifest_sha256": "a" * 64,
                "chunk_count": 1,
                "total_bytes": 8,
            },
        ).status_code
        == 201
    )

    def oversized_body():
        yield b"1234"
        yield b"5"

    response = client.put(
        f"/v1/backups/snapshots/{snapshot_id}/chunks/0",
        headers={**headers, "X-Content-SHA256": hashlib.sha256(b"12345").hexdigest()},
        content=oversized_body(),
    )

    assert response.status_code == 413
    assert not any(client.app.state.backup_object_store.root.rglob("*.chunk"))


def test_backup_snapshot_quotas_reserve_declared_storage(client: TestClient) -> None:
    user = register(client, "quota@example.com", "Quota user")
    headers = auth(user["access_token"])
    settings = client.app.state.settings
    settings.backup_max_snapshots_per_user = 2
    settings.backup_max_total_bytes_per_user = 20

    first = client.post(
        "/v1/backups/snapshots",
        headers=headers,
        json={
            "snapshot_id": "quota-first",
            "manifest_sha256": "c" * 64,
            "chunk_count": 1,
            "total_bytes": 16,
        },
    )
    assert first.status_code == 201, first.text

    over_bytes = client.post(
        "/v1/backups/snapshots",
        headers=headers,
        json={
            "snapshot_id": "quota-second",
            "manifest_sha256": "d" * 64,
            "chunk_count": 1,
            "total_bytes": 5,
        },
    )
    assert over_bytes.status_code == 413
    assert "quota" in over_bytes.json()["detail"].lower()

    deleted = client.delete("/v1/backups/snapshots/quota-first", headers=headers)
    assert deleted.status_code == 200
    available = client.post(
        "/v1/backups/snapshots",
        headers=headers,
        json={
            "snapshot_id": "quota-second",
            "manifest_sha256": "d" * 64,
            "chunk_count": 1,
            "total_bytes": 5,
        },
    )
    assert available.status_code == 201, available.text


def test_backup_snapshot_count_quota_blocks_new_manifests(client: TestClient) -> None:
    user = register(client, "count-quota@example.com", "Count quota")
    headers = auth(user["access_token"])
    settings = client.app.state.settings
    settings.backup_max_snapshots_per_user = 1

    for snapshot_id in ("count-first", "count-second"):
        response = client.post(
            "/v1/backups/snapshots",
            headers=headers,
            json={
                "snapshot_id": snapshot_id,
                "manifest_sha256": "e" * 64,
                "chunk_count": 1,
                "total_bytes": 1,
            },
        )
        if snapshot_id == "count-first":
            assert response.status_code == 201, response.text
        else:
            assert response.status_code == 413
            assert "limit" in response.json()["detail"].lower()


def test_maximum_length_snapshot_id_uploads_without_storage_key_failure(
    client: TestClient,
) -> None:
    user = register(client, "long-snapshot@example.com", "Long snapshot")
    headers = auth(user["access_token"])
    snapshot_id = "s" * 128
    body = b"opaque"

    created = client.post(
        "/v1/backups/snapshots",
        headers=headers,
        json={
            "snapshot_id": snapshot_id,
            "manifest_sha256": "f" * 64,
            "chunk_count": 1,
            "total_bytes": len(body),
        },
    )
    assert created.status_code == 201, created.text

    uploaded = client.put(
        f"/v1/backups/snapshots/{snapshot_id}/chunks/0",
        headers={**headers, "X-Content-SHA256": hashlib.sha256(body).hexdigest()},
        content=body,
    )
    assert uploaded.status_code == 200, uploaded.text


def test_snapshot_delete_commits_before_blob_cleanup_and_retries(
    client: TestClient, monkeypatch
) -> None:
    user = register(client, "delete-retry@example.com", "Delete retry")
    headers = auth(user["access_token"])
    snapshot_id = "delete-retry"
    body = b"opaque"
    assert (
        client.post(
            "/v1/backups/snapshots",
            headers=headers,
            json={
                "snapshot_id": snapshot_id,
                "manifest_sha256": "a" * 64,
                "chunk_count": 1,
                "total_bytes": len(body),
            },
        ).status_code
        == 201
    )
    assert (
        client.put(
            f"/v1/backups/snapshots/{snapshot_id}/chunks/0",
            headers={**headers, "X-Content-SHA256": hashlib.sha256(body).hexdigest()},
            content=body,
        ).status_code
        == 200
    )

    store = client.app.state.backup_object_store
    real_delete = store.delete_snapshot

    def fail_cleanup(**_kwargs) -> None:
        raise OSError("simulated storage outage")

    monkeypatch.setattr(store, "delete_snapshot", fail_cleanup)
    deleted = client.delete(f"/v1/backups/snapshots/{snapshot_id}", headers=headers)
    assert deleted.status_code == 200, deleted.text

    async def assert_queued() -> None:
        async with client.app.state.session_factory() as session:
            assert await session.scalar(select(func.count(BackupSnapshot.id))) == 0
            assert await session.scalar(select(func.count(BackupDeletion.id))) == 1

    asyncio.run(assert_queued())

    monkeypatch.setattr(store, "delete_snapshot", real_delete)

    async def retry_cleanup() -> None:
        async with client.app.state.session_factory() as session:
            assert await sweep_backup_deletions(session, store) == 1
            assert await session.scalar(select(func.count(BackupDeletion.id))) == 0

    asyncio.run(retry_cleanup())
