"""user building unlocks

Revision ID: 202606150003
Revises: 202606150002
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "202606150003"
down_revision: str | None = "202606150002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "user_building_unlocks",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("building_id", sa.String(length=64), nullable=False),
        sa.Column("unlock_level", sa.Integer(), nullable=False),
        sa.Column("unlocked_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "building_id", name="uq_user_building_unlocks_user_building"),
    )
    op.create_index("ix_user_building_unlocks_user_id", "user_building_unlocks", ["user_id"])
    op.create_index("ix_user_building_unlocks_building_id", "user_building_unlocks", ["building_id"])


def downgrade() -> None:
    op.drop_index("ix_user_building_unlocks_building_id", table_name="user_building_unlocks")
    op.drop_index("ix_user_building_unlocks_user_id", table_name="user_building_unlocks")
    op.drop_table("user_building_unlocks")
