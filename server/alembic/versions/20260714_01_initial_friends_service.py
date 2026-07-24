"""Initial account and friend service schema."""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260714_01"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("email", sa.String(length=320), nullable=False),
        sa.Column("display_name", sa.String(length=80), nullable=False),
        sa.Column("password_hash", sa.String(length=255), nullable=False),
        sa.Column("friend_code_digest", sa.String(length=64), nullable=True),
        sa.Column("disabled", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_users"),
        sa.UniqueConstraint("friend_code_digest", name="uq_users_friend_code_digest"),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    op.create_table(
        "device_sessions",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("device_name", sa.String(length=120), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_used_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["user_id"], ["users.id"], name="fk_device_sessions_user_id_users", ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id", name="pk_device_sessions"),
    )
    op.create_index("ix_device_sessions_user_id", "device_sessions", ["user_id"], unique=False)

    op.create_table(
        "refresh_tokens",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("session_id", sa.String(length=36), nullable=False),
        sa.Column("token_digest", sa.String(length=64), nullable=False),
        sa.Column("issued_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("used_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["session_id"],
            ["device_sessions.id"],
            name="fk_refresh_tokens_session_id_device_sessions",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_refresh_tokens"),
    )
    op.create_index("ix_refresh_tokens_session_id", "refresh_tokens", ["session_id"], unique=False)
    op.create_index(
        "ix_refresh_tokens_token_digest",
        "refresh_tokens",
        ["token_digest"],
        unique=True,
    )

    op.create_table(
        "friend_requests",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("pair_low_id", sa.String(length=36), nullable=False),
        sa.Column("pair_high_id", sa.String(length=36), nullable=False),
        sa.Column("requester_id", sa.String(length=36), nullable=False),
        sa.Column("recipient_id", sa.String(length=36), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("responded_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["pair_low_id"],
            ["users.id"],
            name="fk_friend_requests_pair_low_id_users",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["pair_high_id"],
            ["users.id"],
            name="fk_friend_requests_pair_high_id_users",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["requester_id"],
            ["users.id"],
            name="fk_friend_requests_requester_id_users",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["recipient_id"],
            ["users.id"],
            name="fk_friend_requests_recipient_id_users",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_friend_requests"),
        sa.UniqueConstraint("pair_low_id", "pair_high_id", name="uq_friend_request_pair"),
        sa.CheckConstraint(
            "pair_low_id < pair_high_id",
            name="ck_friend_requests_friend_request_canonical_pair",
        ),
        sa.CheckConstraint(
            "requester_id <> recipient_id",
            name="ck_friend_requests_friend_request_distinct_users",
        ),
        sa.CheckConstraint(
            "status IN ('pending', 'accepted', 'declined', 'cancelled')",
            name="ck_friend_requests_friend_request_valid_status",
        ),
    )
    op.create_index(
        "ix_friend_requests_recipient_status",
        "friend_requests",
        ["recipient_id", "status"],
        unique=False,
    )

    op.create_table(
        "friendships",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_low_id", sa.String(length=36), nullable=False),
        sa.Column("user_high_id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["user_low_id"],
            ["users.id"],
            name="fk_friendships_user_low_id_users",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["user_high_id"],
            ["users.id"],
            name="fk_friendships_user_high_id_users",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_friendships"),
        sa.UniqueConstraint("user_low_id", "user_high_id", name="uq_friendship_pair"),
        sa.CheckConstraint(
            "user_low_id < user_high_id",
            name="ck_friendships_friendship_canonical_pair",
        ),
    )

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
            "friendship_id", "owner_id", "viewer_id", "scope", name="uq_friend_grant_scope"
        ),
        sa.CheckConstraint(
            "owner_id <> viewer_id",
            name="ck_friend_grants_friend_grant_distinct_users",
        ),
        sa.CheckConstraint(
            "scope IN ('front_status', 'members', 'member_details', 'front_history', "
            "'groups', 'notes', 'polls')",
            name="ck_friend_grants_friend_grant_valid_scope",
        ),
    )
    op.create_index(
        "ix_friend_grants_friendship_id", "friend_grants", ["friendship_id"], unique=False
    )

    op.create_table(
        "user_blocks",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("blocker_id", sa.String(length=36), nullable=False),
        sa.Column("blocked_id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["blocker_id"], ["users.id"], name="fk_user_blocks_blocker_id_users", ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["blocked_id"], ["users.id"], name="fk_user_blocks_blocked_id_users", ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id", name="pk_user_blocks"),
        sa.UniqueConstraint("blocker_id", "blocked_id", name="uq_user_block_pair"),
        sa.CheckConstraint(
            "blocker_id <> blocked_id",
            name="ck_user_blocks_user_block_distinct_users",
        ),
    )


def downgrade() -> None:
    op.drop_table("user_blocks")
    op.drop_index("ix_friend_grants_friendship_id", table_name="friend_grants")
    op.drop_table("friend_grants")
    op.drop_table("friendships")
    op.drop_index("ix_friend_requests_recipient_status", table_name="friend_requests")
    op.drop_table("friend_requests")
    op.drop_index("ix_refresh_tokens_token_digest", table_name="refresh_tokens")
    op.drop_index("ix_refresh_tokens_session_id", table_name="refresh_tokens")
    op.drop_table("refresh_tokens")
    op.drop_index("ix_device_sessions_user_id", table_name="device_sessions")
    op.drop_table("device_sessions")
    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")
