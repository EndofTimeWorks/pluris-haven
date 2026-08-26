"""Opaque filesystem storage for client-encrypted backup chunks.

This module deliberately knows nothing about archive contents or encryption
keys. It provides immutable, resumable chunk writes for a later authenticated
backup API. Snapshot deletion is explicit; there is no implicit retention job.
"""

from __future__ import annotations

import hashlib
import os
import re
import uuid
from dataclasses import dataclass
from pathlib import Path


class BackupStorageError(Exception):
    """Base class for safe backup storage failures."""


class BackupChunkConflict(BackupStorageError):
    """A chunk key already exists with different content."""


class BackupChunkIntegrityError(BackupStorageError):
    """The supplied content does not match the client-provided digest."""


_SAFE_KEY = re.compile(r"^[A-Za-z0-9_-]{1,128}$")


@dataclass(frozen=True, slots=True)
class StoredBackupChunk:
    snapshot_id: str
    index: int
    sha256: str
    size: int


class FilesystemBackupObjectStore:
    """Stores opaque snapshot chunks without allowing path traversal/overwrite."""

    def __init__(self, root: Path, *, max_chunk_bytes: int = 8 * 1024 * 1024) -> None:
        if max_chunk_bytes < 1024:
            raise ValueError("max_chunk_bytes must be at least 1024")
        self.root = root
        self.max_chunk_bytes = max_chunk_bytes

    def put_chunk(
        self,
        *,
        owner_id: str,
        snapshot_id: str,
        index: int,
        ciphertext: bytes,
        sha256: str,
    ) -> StoredBackupChunk:
        snapshot_dir = self._snapshot_dir(owner_id, snapshot_id)
        self._migrate_legacy_snapshot(owner_id, snapshot_id, snapshot_dir)
        if index < 0:
            raise ValueError("index must be non-negative")
        if len(ciphertext) > self.max_chunk_bytes:
            raise ValueError("backup chunk exceeds configured size limit")
        actual_sha256 = hashlib.sha256(ciphertext).hexdigest()
        if actual_sha256 != sha256:
            raise BackupChunkIntegrityError("backup chunk digest does not match content")

        destination = snapshot_dir / f"{index:012d}.chunk"
        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.exists():
            existing = destination.read_bytes()
            if existing != ciphertext:
                raise BackupChunkConflict("backup chunk key already contains other content")
            return StoredBackupChunk(snapshot_id, index, sha256, len(existing))

        try:
            with destination.open("xb") as handle:
                handle.write(ciphertext)
                handle.flush()
                os.fsync(handle.fileno())
        except FileExistsError as error:
            existing = destination.read_bytes()
            if existing != ciphertext:
                raise BackupChunkConflict(
                    "backup chunk key already contains other content"
                ) from error
        except Exception:
            destination.unlink(missing_ok=True)
            raise

        return StoredBackupChunk(snapshot_id, index, sha256, len(ciphertext))

    def read_chunk(self, *, owner_id: str, snapshot_id: str, index: int) -> bytes:
        snapshot_dir = self._snapshot_dir(owner_id, snapshot_id)
        self._migrate_legacy_snapshot(owner_id, snapshot_id, snapshot_dir)
        if index < 0:
            raise ValueError("index must be non-negative")
        return (snapshot_dir / f"{index:012d}.chunk").read_bytes()

    def delete_snapshot(self, *, owner_id: str, snapshot_id: str) -> None:
        snapshot_dir = self._snapshot_dir(owner_id, snapshot_id)
        legacy_dir = self._legacy_snapshot_dir(owner_id, snapshot_id)
        for candidate in (snapshot_dir, legacy_dir):
            if candidate is None or not candidate.exists():
                continue
            for path in candidate.iterdir():
                if path.is_file():
                    path.unlink()
            candidate.rmdir()
        owner_dir = self.root / owner_id
        if owner_dir.exists() and not any(owner_dir.iterdir()):
            owner_dir.rmdir()

    def delete_snapshots(self, *, owner_id: str, snapshot_ids: list[str]) -> None:
        """Delete a known set of snapshot directories during account removal."""
        for snapshot_id in snapshot_ids:
            self.delete_snapshot(owner_id=owner_id, snapshot_id=snapshot_id)

    def _snapshot_dir(self, owner_id: str, snapshot_id: str) -> Path:
        self._validate_key(owner_id, "owner_id")
        self._validate_key(snapshot_id, "snapshot_id")
        return self.root / owner_id / snapshot_id

    def _legacy_snapshot_dir(self, owner_id: str, snapshot_id: str) -> Path | None:
        try:
            uuid.UUID(owner_id)
        except ValueError:
            return None
        legacy_key = f"{owner_id}_{snapshot_id}"
        if not _SAFE_KEY.fullmatch(legacy_key):
            return None
        return self.root / legacy_key

    def _migrate_legacy_snapshot(self, owner_id: str, snapshot_id: str, destination: Path) -> None:
        legacy_dir = self._legacy_snapshot_dir(owner_id, snapshot_id)
        if legacy_dir is None or not legacy_dir.exists() or destination.exists():
            return
        destination.parent.mkdir(parents=True, exist_ok=True)
        legacy_dir.rename(destination)

    @staticmethod
    def _validate_key(value: str, name: str) -> None:
        if not _SAFE_KEY.fullmatch(value):
            raise ValueError(f"{name} contains unsafe characters")
