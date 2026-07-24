"""Opaque filesystem storage for client-encrypted backup chunks.

This module deliberately knows nothing about archive contents or encryption
keys. It provides immutable, resumable chunk writes for a later authenticated
backup API. Snapshot deletion is explicit; there is no implicit retention job.
"""

from __future__ import annotations

import hashlib
import os
import re
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
        snapshot_id: str,
        index: int,
        ciphertext: bytes,
        sha256: str,
    ) -> StoredBackupChunk:
        self._validate_key(snapshot_id, "snapshot_id")
        if index < 0:
            raise ValueError("index must be non-negative")
        if len(ciphertext) > self.max_chunk_bytes:
            raise ValueError("backup chunk exceeds configured size limit")
        actual_sha256 = hashlib.sha256(ciphertext).hexdigest()
        if actual_sha256 != sha256:
            raise BackupChunkIntegrityError("backup chunk digest does not match content")

        destination = self.root / snapshot_id / f"{index:012d}.chunk"
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

    def read_chunk(self, *, snapshot_id: str, index: int) -> bytes:
        self._validate_key(snapshot_id, "snapshot_id")
        if index < 0:
            raise ValueError("index must be non-negative")
        return (self.root / snapshot_id / f"{index:012d}.chunk").read_bytes()

    def delete_snapshot(self, *, snapshot_id: str) -> None:
        self._validate_key(snapshot_id, "snapshot_id")
        snapshot_dir = self.root / snapshot_id
        if not snapshot_dir.exists():
            return
        for path in snapshot_dir.iterdir():
            if path.is_file():
                path.unlink()
        snapshot_dir.rmdir()

    @staticmethod
    def _validate_key(value: str, name: str) -> None:
        if not _SAFE_KEY.fullmatch(value):
            raise ValueError(f"{name} contains unsafe characters")
