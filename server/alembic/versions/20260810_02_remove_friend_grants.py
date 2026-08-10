"""Remove sharing grants that had no protected resources behind them."""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260810_02"
down_revision: str | None = "20260810_01"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.drop_table("friend_grants")


def downgrade() -> None:
    op.create_table(
        "friend_grants",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("friendship_id", sa.String(length=36), nullable=False),
        sa.Column("owner_id", sa.String(length=36), nullable=False),
        sa.Column("viewer_id", sa.String(length=36), nullable=False),
        sa.Column("scope", sa.String(length=40), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["friendship_id"],
            ["friendships.id"],
            name="fk_friend_grants_friendship_id_friendships",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["owner_id"], ["users.id"], name="fk_friend_grants_owner_id_users", ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["viewer_id"], ["users.id"], name="fk_friend_grants_viewer_id_users", ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id", name="pk_friend_grants"),
        sa.UniqueConstraint(
            "friendship_id",
            "owner_id",
            "viewer_id",
            "scope",
            name="uq_friend_grant_scope",
        ),
    )
