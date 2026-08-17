"""Widen backup snapshot byte totals.

Revision ID: 20260816_01
Revises: 20260815_01
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "20260816_01"
down_revision: str | None = "20260815_01"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    with op.batch_alter_table("backup_snapshots") as batch_op:
        batch_op.alter_column(
            "total_bytes",
            existing_type=sa.Integer(),
            type_=sa.BigInteger(),
            existing_nullable=False,
        )


def downgrade() -> None:
    with op.batch_alter_table("backup_snapshots") as batch_op:
        batch_op.alter_column(
            "total_bytes",
            existing_type=sa.BigInteger(),
            type_=sa.Integer(),
            existing_nullable=False,
        )
