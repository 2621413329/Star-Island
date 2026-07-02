"""Add daily_moments query indexes.

Revision ID: 202607010001
Revises: 202606300001
Create Date: 2026-07-01
"""

from alembic import op

revision = "202607010001"
down_revision = "202606300001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_index(
        "ix_daily_moments_user_moment_date_created",
        "daily_moments",
        ["user_id", "moment_date", "created_at"],
        unique=False,
    )
    op.create_index(
        "ix_daily_moments_user_story_island_moment_date",
        "daily_moments",
        ["user_id", "story_island_id", "moment_date"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        "ix_daily_moments_user_story_island_moment_date",
        table_name="daily_moments",
    )
    op.drop_index(
        "ix_daily_moments_user_moment_date_created",
        table_name="daily_moments",
    )
