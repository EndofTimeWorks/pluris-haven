"""Add the 30-day account deletion recovery window."""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260823_01"
down_revision: str | None = "20260822_02"
branch_labels: str | Sequence[str] | None = None
depends_on: str | None = None


def upgrade() -> None:
    with op.batch_alter_table("users") as batch:
        batch.add_column(sa.Column("deletion_requested_at", sa.DateTime(timezone=True)))
        batch.add_column(sa.Column("deletion_purge_after", sa.DateTime(timezone=True)))
    with op.batch_alter_table("security_events") as batch:
        batch.drop_constraint("security_event_valid_type", type_="check")
        batch.create_check_constraint(
            "security_event_valid_type",
            "event_type IN ('signed_out', 'password_changed', 'session_revoked', "
            "'backup_recovery_started', 'backup_deleted', 'account_deleted', "
            "'account_deletion_requested', 'account_recovered')",
        )


def downgrade() -> None:
    with op.batch_alter_table("security_events") as batch:
        batch.drop_constraint("security_event_valid_type", type_="check")
        batch.create_check_constraint(
            "security_event_valid_type",
            "event_type IN ('signed_out', 'password_changed', 'session_revoked', "
            "'backup_recovery_started', 'backup_deleted', 'account_deleted')",
        )
    with op.batch_alter_table("users") as batch:
        batch.drop_column("deletion_purge_after")
        batch.drop_column("deletion_requested_at")
