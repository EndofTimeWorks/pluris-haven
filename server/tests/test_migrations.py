from pathlib import Path

from alembic.config import Config
from sqlalchemy import create_engine, text

from alembic import command
from pluris_server.config import get_settings


def _alembic_config() -> Config:
    return Config(str(Path(__file__).parents[1] / "alembic.ini"))


def test_backup_upload_start_migration_repairs_all_legacy_upload_states(
    tmp_path, monkeypatch
) -> None:
    database_path = tmp_path / "migration.db"
    database_url = f"sqlite+aiosqlite:///{database_path}"
    monkeypatch.setenv("PLURIS_DATABASE_URL", database_url)
    get_settings.cache_clear()
    try:
        command.upgrade(_alembic_config(), "20260913_01")
        engine = create_engine(f"sqlite:///{database_path}")
        with engine.begin() as connection:
            connection.execute(
                text(
                    """
                    INSERT INTO backup_snapshots (
                        id, user_id, snapshot_id, manifest_sha256,
                        chunk_count, total_bytes, created_at,
                        upload_started_at
                    ) VALUES
                    (
                        'legacy-snapshot', 'legacy-user', 'legacy-upload', :digest,
                        1, 1024, '2000-01-01 00:00:00', '2000-01-01 00:00:00'
                    ),
                    (
                        'legacy-one-chunk', 'legacy-user', 'legacy-one', :digest,
                        2, 2048, '2099-01-01 00:00:00', '2099-01-01 00:00:00'
                    ),
                    (
                        'legacy-many-chunks', 'legacy-user', 'legacy-many', :digest,
                        3, 3072, '2000-01-01 00:00:00', '2000-01-01 00:00:00'
                    ),
                    (
                        'legacy-complete', 'legacy-user', 'legacy-complete', :digest,
                        1, 1024, '2000-01-01 00:00:00', '2000-01-01 00:00:00'
                    )
                    """
                ),
                {"digest": "a" * 64},
            )
            connection.execute(
                text(
                    """
                    INSERT INTO backup_chunks (id, snapshot_id, "index", sha256, size, stored_at)
                    VALUES
                    ('chunk-one', 'legacy-one-chunk', 0, :digest, 1024, '2099-01-01 00:00:00'),
                    ('chunk-many-0', 'legacy-many-chunks', 0, :digest, 1024, '2000-01-01 00:00:00'),
                    ('chunk-many-1', 'legacy-many-chunks', 1, :digest, 1024, '2000-01-01 00:00:00'),
                    ('chunk-complete', 'legacy-complete', 0, :digest, 1024, '2000-01-01 00:00:00')
                    """
                ),
                {"digest": "b" * 64},
            )
        engine.dispose()

        command.upgrade(_alembic_config(), "head")
        engine = create_engine(f"sqlite:///{database_path}")
        with engine.connect() as connection:
            repaired = connection.execute(
                text(
                    """
                    SELECT id, upload_started_at
                    FROM backup_snapshots
                    ORDER BY id
                    """
                )
            ).all()
            stored_counts = dict(
                connection.execute(
                    text(
                        """
                        SELECT snapshot_id, COUNT(*)
                        FROM backup_chunks
                        WHERE stored_at IS NOT NULL
                        GROUP BY snapshot_id
                        """
                    )
                ).all()
            )
        engine.dispose()

        # All legacy `created_at` copies are server-reset reservations, not
        # reconstructed client timestamps. This includes partially uploaded
        # and completed manifests; completeness is never inferred from an old
        # database marker until the bytes are reconciled.
        assert {row.id for row in repaired} == {
            "legacy-snapshot",
            "legacy-one-chunk",
            "legacy-many-chunks",
            "legacy-complete",
        }
        assert all(str(row.upload_started_at) != "2000-01-01 00:00:00" for row in repaired)
        assert all(str(row.upload_started_at) != "2099-01-01 00:00:00" for row in repaired)
        assert stored_counts == {}

        # Alembic head is idempotent after this repair.
        command.upgrade(_alembic_config(), "head")
    finally:
        get_settings.cache_clear()
