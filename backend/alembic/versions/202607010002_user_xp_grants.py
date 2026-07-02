"""daily_moments indexes + user xp grants for main island tasks

Revision ID: 202607010002
Revises: 202606300001
Create Date: 2026-07-01

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "202607010002"
down_revision: Union[str, None] = "202606300001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Merged from 202607010001 (idempotent for partial deploys).
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_daily_moments_user_moment_date_created "
        "ON daily_moments (user_id, moment_date, created_at)"
    )
    op.execute(
        "CREATE INDEX IF NOT EXISTS ix_daily_moments_user_story_island_moment_date "
        "ON daily_moments (user_id, story_island_id, moment_date)"
    )
    op.create_table(
        "user_xp_grants",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("grant_date", sa.Date(), nullable=False),
        sa.Column("source", sa.String(length=32), nullable=False),
        sa.Column("amount", sa.Integer(), nullable=False),
        sa.Column("task_completion_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("moment_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["moment_id"], ["daily_moments.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["task_completion_id"], ["story_island_task_completions.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_user_xp_grants_user_id", "user_xp_grants", ["user_id"])
    op.create_index("ix_user_xp_grants_grant_date", "user_xp_grants", ["grant_date"])
    op.create_index("ix_user_xp_grants_source", "user_xp_grants", ["source"])
    op.create_index("ix_user_xp_grants_task_completion_id", "user_xp_grants", ["task_completion_id"])
    op.create_index("ix_user_xp_grants_moment_id", "user_xp_grants", ["moment_id"])


def downgrade() -> None:
    op.drop_index("ix_user_xp_grants_moment_id", table_name="user_xp_grants")
    op.drop_index("ix_user_xp_grants_task_completion_id", table_name="user_xp_grants")
    op.drop_index("ix_user_xp_grants_source", table_name="user_xp_grants")
    op.drop_index("ix_user_xp_grants_grant_date", table_name="user_xp_grants")
    op.drop_index("ix_user_xp_grants_user_id", table_name="user_xp_grants")
    op.drop_table("user_xp_grants")
    op.drop_index(
        "ix_daily_moments_user_story_island_moment_date",
        table_name="daily_moments",
        if_exists=True,
    )
    op.drop_index(
        "ix_daily_moments_user_moment_date_created",
        table_name="daily_moments",
        if_exists=True,
    )
