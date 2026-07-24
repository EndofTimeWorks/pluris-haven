"""Add per-user encrypted backup snapshot metadata."""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260724_01"
down_revision: str | None = "20260714_01"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "backup_snapshots",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("snapshot_id", sa.String(length=128), nullable=False),
        sa.Column("manifest_sha256", sa.String(length=64), nullable=False),
        sa.Column("chunk_count", sa.Integer(), nullable=False),
        sa.Column("total_bytes", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["user_id"], ["users.id"], name="fk_backup_snapshots_user_id_users", ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id", name="pk_backup_snapshots"),
        sa.UniqueConstraint("user_id", "snapshot_id", name="uq_backup_snapshots_user_snapshot"),
    )
    op.create_index("ix_backup_snapshots_user_id", "backup_snapshots", ["user_id"], unique=False)
    op.create_index(
        "ix_backup_snapshots_user_created",
        "backup_snapshots",
        ["user_id", "created_at"],
        unique=False,
    )
    op.create_table(
        "backup_chunks",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("snapshot_id", sa.String(length=36), nullable=False),
        sa.Column("index", sa.Integer(), nullable=False),
        sa.Column("sha256", sa.String(length=64), nullable=False),
        sa.Column("size", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(
            ["snapshot_id"],
            ["backup_snapshots.id"],
            name="fk_backup_chunks_snapshot_id_backup_snapshots",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_backup_chunks"),
        sa.UniqueConstraint("snapshot_id", "index", name="uq_backup_chunks_snapshot_index"),
    )
    op.create_index("ix_backup_chunks_snapshot_id", "backup_chunks", ["snapshot_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_backup_chunks_snapshot_id", table_name="backup_chunks")
    op.drop_table("backup_chunks")
    op.drop_index("ix_backup_snapshots_user_created", table_name="backup_snapshots")
    op.drop_index("ix_backup_snapshots_user_id", table_name="backup_snapshots")
    op.drop_table("backup_snapshots")
