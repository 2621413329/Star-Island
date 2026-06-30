"""drop story island target completion fields

Revision ID: 202606300001
Revises: 202606290002
Create Date: 2026-06-30
"""

from alembic import op
import sqlalchemy as sa

revision = "202606300001"
down_revision = "202606290002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_column("story_islands", "completion_target_date")
    op.drop_column("story_islands", "target_completion_days")


def downgrade() -> None:
    op.add_column(
        "story_islands",
        sa.Column("target_completion_days", sa.Integer(), nullable=False, server_default="90"),
    )
    op.add_column(
        "story_islands",
        sa.Column("completion_target_date", sa.Date(), nullable=True),
    )
    op.alter_column("story_islands", "target_completion_days", server_default=None)
