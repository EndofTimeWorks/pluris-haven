from pathlib import Path

from alembic.config import Config
from sqlalchemy import create_engine, text

from alembic import command
from pluris_server.config import get_settings


def _alembic_config() -> Config:
    return Config(str(Path(__file__).parents[1] / "alembic.ini"))


def test_backup_upload_start_migration_does_not_expire_legacy_incomplete_upload(
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
                    ) VALUES (
                        'legacy-snapshot', 'legacy-user', 'legacy-upload', :digest,
                        1, 1024, '2000-01-01 00:00:00', '2000-01-01 00:00:00'
                    )
                    """
                ),
                {"digest": "a" * 64},
            )
        engine.dispose()

        command.upgrade(_alembic_config(), "head")
        engine = create_engine(f"sqlite:///{database_path}")
        with engine.connect() as connection:
            upload_started_at = connection.scalar(
                text(
                    """
                    SELECT upload_started_at
                    FROM backup_snapshots
                    WHERE id = 'legacy-snapshot'
                    """
                )
            )
        engine.dispose()

        assert upload_started_at is not None
        assert str(upload_started_at) != "2000-01-01 00:00:00"
    finally:
        get_settings.cache_clear()
