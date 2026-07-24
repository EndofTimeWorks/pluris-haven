import hashlib

import pytest

from pluris_server.backup_storage import (
    BackupChunkConflict,
    BackupChunkIntegrityError,
    FilesystemBackupObjectStore,
)


def test_chunk_store_is_idempotent_but_never_overwrites(tmp_path) -> None:
    store = FilesystemBackupObjectStore(tmp_path)
    payload = b"opaque client ciphertext"
    digest = hashlib.sha256(payload).hexdigest()

    first = store.put_chunk(snapshot_id="snapshot-1", index=0, ciphertext=payload, sha256=digest)
    second = store.put_chunk(snapshot_id="snapshot-1", index=0, ciphertext=payload, sha256=digest)

    assert first == second
    assert store.read_chunk(snapshot_id="snapshot-1", index=0) == payload
    with pytest.raises(BackupChunkConflict):
        store.put_chunk(
            snapshot_id="snapshot-1",
            index=0,
            ciphertext=b"different ciphertext",
            sha256=hashlib.sha256(b"different ciphertext").hexdigest(),
        )


def test_chunk_store_rejects_bad_digest_and_path_traversal(tmp_path) -> None:
    store = FilesystemBackupObjectStore(tmp_path)
    with pytest.raises(BackupChunkIntegrityError):
        store.put_chunk(snapshot_id="snapshot-1", index=0, ciphertext=b"data", sha256="0" * 64)
    with pytest.raises(ValueError):
        store.put_chunk(snapshot_id="../outside", index=0, ciphertext=b"data", sha256="0" * 64)


def test_snapshot_deletion_is_explicit(tmp_path) -> None:
    store = FilesystemBackupObjectStore(tmp_path)
    payload = b"opaque"
    store.put_chunk(
        snapshot_id="snapshot-1",
        index=0,
        ciphertext=payload,
        sha256=hashlib.sha256(payload).hexdigest(),
    )
    store.delete_snapshot(snapshot_id="snapshot-1")
    assert not (tmp_path / "snapshot-1").exists()
