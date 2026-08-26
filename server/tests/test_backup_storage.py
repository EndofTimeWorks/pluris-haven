import hashlib

import pytest

from pluris_server.backup_storage import (
    BackupChunkConflict,
    BackupChunkIntegrityError,
    FilesystemBackupObjectStore,
)


def test_chunk_store_is_idempotent_but_never_overwrites(tmp_path) -> None:
    store = FilesystemBackupObjectStore(tmp_path)
    owner_id = "00000000-0000-0000-0000-000000000001"
    payload = b"opaque client ciphertext"
    digest = hashlib.sha256(payload).hexdigest()

    first = store.put_chunk(
        owner_id=owner_id,
        snapshot_id="snapshot-1",
        index=0,
        ciphertext=payload,
        sha256=digest,
    )
    second = store.put_chunk(
        owner_id=owner_id,
        snapshot_id="snapshot-1",
        index=0,
        ciphertext=payload,
        sha256=digest,
    )

    assert first == second
    assert store.read_chunk(owner_id=owner_id, snapshot_id="snapshot-1", index=0) == payload
    with pytest.raises(BackupChunkConflict):
        store.put_chunk(
            owner_id=owner_id,
            snapshot_id="snapshot-1",
            index=0,
            ciphertext=b"different ciphertext",
            sha256=hashlib.sha256(b"different ciphertext").hexdigest(),
        )


def test_chunk_store_rejects_bad_digest_and_path_traversal(tmp_path) -> None:
    store = FilesystemBackupObjectStore(tmp_path)
    with pytest.raises(BackupChunkIntegrityError):
        store.put_chunk(
            owner_id="owner-1",
            snapshot_id="snapshot-1",
            index=0,
            ciphertext=b"data",
            sha256="0" * 64,
        )
    with pytest.raises(ValueError):
        store.put_chunk(
            owner_id="owner-1",
            snapshot_id="../outside",
            index=0,
            ciphertext=b"data",
            sha256="0" * 64,
        )


def test_snapshot_deletion_is_explicit(tmp_path) -> None:
    store = FilesystemBackupObjectStore(tmp_path)
    owner_id = "owner-1"
    payload = b"opaque"
    store.put_chunk(
        owner_id=owner_id,
        snapshot_id="snapshot-1",
        index=0,
        ciphertext=payload,
        sha256=hashlib.sha256(payload).hexdigest(),
    )
    store.delete_snapshot(owner_id=owner_id, snapshot_id="snapshot-1")
    assert not (tmp_path / owner_id / "snapshot-1").exists()


def test_owner_and_snapshot_are_separate_safe_path_segments(tmp_path) -> None:
    store = FilesystemBackupObjectStore(tmp_path)
    owner_id = "00000000-0000-0000-0000-000000000001"
    snapshot_id = "s" * 128
    payload = b"opaque"

    store.put_chunk(
        owner_id=owner_id,
        snapshot_id=snapshot_id,
        index=0,
        ciphertext=payload,
        sha256=hashlib.sha256(payload).hexdigest(),
    )

    assert store.read_chunk(owner_id=owner_id, snapshot_id=snapshot_id, index=0) == payload
    assert (tmp_path / owner_id / snapshot_id / "000000000000.chunk").is_file()


def test_legacy_snapshot_migration_requires_an_unambiguous_owner_id(tmp_path) -> None:
    store = FilesystemBackupObjectStore(tmp_path)
    owner_id = "00000000-0000-0000-0000-000000000001"
    snapshot_id = "snapshot_with_underscores"
    payload = b"opaque"
    legacy_dir = tmp_path / f"{owner_id}_{snapshot_id}"
    legacy_dir.mkdir()
    (legacy_dir / "000000000000.chunk").write_bytes(payload)

    assert store.read_chunk(owner_id=owner_id, snapshot_id=snapshot_id, index=0) == payload
    assert not legacy_dir.exists()
    assert (tmp_path / owner_id / snapshot_id / "000000000000.chunk").is_file()
    assert store._legacy_snapshot_dir("owner_part", "snapshot_part") is None
