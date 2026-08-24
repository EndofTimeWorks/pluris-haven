"""Index backup snapshot expiry scans."""

from collections.abc import Sequence

from alembic import op

revision: str = "20260823_02"
down_revision: str | None = "20260823_01"
branch_labels: str | Sequence[str] | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.create_index("ix_backup_snapshots_created", "backup_snapshots", ["created_at"])


def downgrade() -> None:
    op.drop_index("ix_backup_snapshots_created", table_name="backup_snapshots")
