"""Bound legacy backup reconciliation."""

import sqlalchemy as sa

from alembic import op

revision = "20260916_01"
down_revision = "20260914_01"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "backup_chunks",
        sa.Column("reconciliation_checked_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(
        "ix_backup_chunks_pending_reconciliation",
        "backup_chunks",
        ["reconciliation_checked_at", "id"],
        postgresql_where=sa.text("stored_at IS NULL"),
    )


def downgrade() -> None:
    op.drop_index("ix_backup_chunks_pending_reconciliation", table_name="backup_chunks")
    op.drop_column("backup_chunks", "reconciliation_checked_at")
