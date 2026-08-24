"""Add the 30-day account deletion recovery window."""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260823_01"
down_revision: str | None = "20260822_02"
branch_labels: str | Sequence[str] | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.add_column("users", sa.Column("deletion_requested_at", sa.DateTime(timezone=True)))
    op.add_column("users", sa.Column("deletion_purge_after", sa.DateTime(timezone=True)))
    op.drop_constraint("security_event_valid_type", "security_events", type_="check")
    op.create_check_constraint(
        "security_event_valid_type",
        "security_events",
        "event_type IN ('signed_out', 'password_changed', 'session_revoked', "
        "'backup_recovery_started', 'backup_deleted', 'account_deleted', "
        "'account_deletion_requested', 'account_recovered')",
    )


def downgrade() -> None:
    op.drop_constraint("security_event_valid_type", "security_events", type_="check")
    op.create_check_constraint(
        "security_event_valid_type",
        "security_events",
        "event_type IN ('signed_out', 'password_changed', 'session_revoked', "
        "'backup_recovery_started', 'backup_deleted', 'account_deleted')",
    )
    op.drop_column("users", "deletion_purge_after")
    op.drop_column("users", "deletion_requested_at")
