"""Add shared sliding-window rate-limit events.

Revision ID: 20260810_03
Revises: 20260810_02
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260810_03"
down_revision: str | None = "20260810_02"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "rate_limit_events",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("bucket_key", sa.String(length=255), nullable=False),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_rate_limit_events")),
    )
    op.create_index(
        "ix_rate_limit_events_bucket_occurred",
        "rate_limit_events",
        ["bucket_key", "occurred_at"],
        unique=False,
    )
    op.create_index(
        "ix_rate_limit_events_expires",
        "rate_limit_events",
        ["expires_at"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_rate_limit_events_expires", table_name="rate_limit_events")
    op.drop_index(
        "ix_rate_limit_events_bucket_occurred",
        table_name="rate_limit_events",
    )
    op.drop_table("rate_limit_events")
