"""Track server-owned upload start and durable backup chunks."""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260913_01"
down_revision: str | None = "20260823_02"
branch_labels: str | Sequence[str] | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.add_column(
        "backup_snapshots",
        sa.Column("upload_started_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.execute(
        "UPDATE backup_snapshots SET upload_started_at = created_at WHERE upload_started_at IS NULL"
    )
    with op.batch_alter_table("backup_snapshots") as batch_op:
        batch_op.alter_column("upload_started_at", nullable=False)
    op.create_index("ix_backup_snapshots_upload_started", "backup_snapshots", ["upload_started_at"])

    op.add_column(
        "backup_chunks",
        sa.Column("stored_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.execute(
        "UPDATE backup_chunks SET stored_at = backup_snapshots.created_at "
        "FROM backup_snapshots "
        "WHERE backup_chunks.snapshot_id = backup_snapshots.id"
    )


def downgrade() -> None:
    op.drop_column("backup_chunks", "stored_at")
    op.drop_index("ix_backup_snapshots_upload_started", table_name="backup_snapshots")
    op.drop_column("backup_snapshots", "upload_started_at")
