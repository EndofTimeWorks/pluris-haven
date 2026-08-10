"""Add durable backup blob deletion queue."""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260810_01"
down_revision: str | None = "20260724_01"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "backup_deletions",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("owner_id", sa.String(length=128), nullable=False),
        sa.Column("snapshot_id", sa.String(length=128), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_backup_deletions"),
        sa.UniqueConstraint(
            "owner_id",
            "snapshot_id",
            name="uq_backup_deletion_owner_snapshot",
        ),
    )


def downgrade() -> None:
    op.drop_table("backup_deletions")
