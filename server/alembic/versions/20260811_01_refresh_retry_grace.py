"""Add one-use refresh rotation retry tracking.

Revision ID: 20260811_01
Revises: 20260810_03
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260811_01"
down_revision: str | None = "20260810_03"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    with op.batch_alter_table("refresh_tokens") as batch_op:
        batch_op.add_column(sa.Column("rotation_nonce_digest", sa.String(length=64), nullable=True))
        batch_op.add_column(sa.Column("replacement_token_id", sa.String(length=36), nullable=True))
        batch_op.add_column(
            sa.Column("rotation_retried_at", sa.DateTime(timezone=True), nullable=True)
        )
        batch_op.create_foreign_key(
            op.f("fk_refresh_tokens_replacement_token_id_refresh_tokens"),
            "refresh_tokens",
            ["replacement_token_id"],
            ["id"],
            ondelete="SET NULL",
        )
        batch_op.create_index(
            op.f("ix_refresh_tokens_replacement_token_id"),
            ["replacement_token_id"],
            unique=False,
        )


def downgrade() -> None:
    with op.batch_alter_table("refresh_tokens") as batch_op:
        batch_op.drop_index(op.f("ix_refresh_tokens_replacement_token_id"))
        batch_op.drop_constraint(
            op.f("fk_refresh_tokens_replacement_token_id_refresh_tokens"),
            type_="foreignkey",
        )
        batch_op.drop_column("rotation_retried_at")
        batch_op.drop_column("replacement_token_id")
        batch_op.drop_column("rotation_nonce_digest")
