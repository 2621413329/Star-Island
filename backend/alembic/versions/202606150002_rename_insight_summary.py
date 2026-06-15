"""rename student_insight to insight_summary

Revision ID: 202606150002
Revises: 202606150001
"""

from alembic import op

revision = "202606150002"
down_revision = "202606150001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.alter_column(
        "daily_mood_reports",
        "student_insight",
        new_column_name="insight_summary",
    )


def downgrade() -> None:
    op.alter_column(
        "daily_mood_reports",
        "insight_summary",
        new_column_name="student_insight",
    )
