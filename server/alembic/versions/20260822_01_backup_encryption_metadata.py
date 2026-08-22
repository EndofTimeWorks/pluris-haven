"""Store opaque encrypted-backup reconstruction metadata."""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260822_01"
down_revision: str | None = "20260816_01"
branch_labels: str | Sequence[str] | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.add_column(
        "backup_snapshots",
        sa.Column("format", sa.String(length=128), nullable=True),
    )
    op.add_column(
        "backup_snapshots",
        sa.Column("version", sa.Integer(), nullable=True),
    )
    op.add_column(
        "backup_snapshots",
        sa.Column("chunk_size", sa.Integer(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("backup_snapshots", "chunk_size")
    op.drop_column("backup_snapshots", "version")
    op.drop_column("backup_snapshots", "format")
