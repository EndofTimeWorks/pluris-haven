"""Repair legacy backup upload-start timestamps.

The preceding durability migration had no server-owned timestamp available for
existing rows, so it copied client-provided capture time into
``upload_started_at``. Only incomplete rows can be swept for expiry; give
those known backfills a fresh server-owned start time on this upgrade.
"""

from collections.abc import Sequence

from alembic import op

revision: str = "20260914_01"
down_revision: str | None = "20260913_01"
branch_labels: str | Sequence[str] | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.drop_index("ix_backup_snapshots_upload_started", table_name="backup_snapshots")
    op.create_index(
        "ix_backup_snapshots_upload_started_at",
        "backup_snapshots",
        ["upload_started_at"],
    )
    op.execute(
        """
        UPDATE backup_snapshots
        SET upload_started_at = CURRENT_TIMESTAMP
        WHERE upload_started_at = created_at
          AND NOT EXISTS (
            SELECT 1
            FROM backup_chunks
            WHERE backup_chunks.snapshot_id = backup_snapshots.id
          )
        """
    )


def downgrade() -> None:
    # The previous client capture value is not recoverable. Keeping the
    # server-owned value is safer than restoring an expiry timestamp we know
    # was not authoritative.
    op.drop_index("ix_backup_snapshots_upload_started_at", table_name="backup_snapshots")
    op.create_index(
        "ix_backup_snapshots_upload_started",
        "backup_snapshots",
        ["upload_started_at"],
    )
