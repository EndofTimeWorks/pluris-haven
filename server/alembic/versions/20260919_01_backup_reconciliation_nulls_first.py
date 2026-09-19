"""Order pending backup reconciliation by unchecked chunks first."""

import sqlalchemy as sa

from alembic import op

revision = "20260919_01"
down_revision = "20260916_01"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_index("ix_backup_chunks_pending_reconciliation", table_name="backup_chunks")
    op.create_index(
        "ix_backup_chunks_pending_reconciliation",
        "backup_chunks",
        ["reconciliation_checked_at", "id"],
        postgresql_where=sa.text("stored_at IS NULL"),
        postgresql_ops={"reconciliation_checked_at": "ASC NULLS FIRST"},
    )


def downgrade() -> None:
    op.drop_index("ix_backup_chunks_pending_reconciliation", table_name="backup_chunks")
    op.create_index(
        "ix_backup_chunks_pending_reconciliation",
        "backup_chunks",
        ["reconciliation_checked_at", "id"],
        postgresql_where=sa.text("stored_at IS NULL"),
    )
