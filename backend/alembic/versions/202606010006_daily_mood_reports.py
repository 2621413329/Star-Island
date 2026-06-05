"""daily mood reports for teacher dashboard

Revision ID: 202606010006
Revises: 202606010005
Create Date: 2026-06-03
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "202606010006"
down_revision: str | None = "202606010005"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "daily_mood_reports",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("student_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("report_date", sa.Date(), nullable=False),
        sa.Column("category_filter", sa.String(16), nullable=True),
        sa.Column("moment_count", sa.Integer(), server_default="0", nullable=False),
        sa.Column("mood_counts", postgresql.JSONB(), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.Column("radar_scores", postgresql.JSONB(), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.Column(
            "teacher_radar_scores",
            postgresql.JSONB(),
            server_default=sa.text("'{}'::jsonb"),
            nullable=False,
        ),
        sa.Column(
            "category_breakdown",
            postgresql.JSONB(),
            server_default=sa.text("'{}'::jsonb"),
            nullable=False,
        ),
        sa.Column("concern_level", sa.String(16), server_default="normal", nullable=False),
        sa.Column("risk_flags", postgresql.JSONB(), server_default=sa.text("'[]'::jsonb"), nullable=False),
        sa.Column(
            "attention_highlights",
            postgresql.JSONB(),
            server_default=sa.text("'[]'::jsonb"),
            nullable=False,
        ),
        sa.Column("fuzzy_analysis", sa.String(512), nullable=False),
        sa.Column("student_insight", sa.String(512), nullable=False),
        sa.Column("warm_suggestion", sa.String(512), nullable=False),
        sa.Column("ai_generated", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["student_id"], ["students.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "report_date", name="uq_daily_mood_reports_user_date"),
    )
    op.create_index("ix_daily_mood_reports_student_date", "daily_mood_reports", ["student_id", "report_date"])


def downgrade() -> None:
    op.drop_index("ix_daily_mood_reports_student_date", table_name="daily_mood_reports")
    op.drop_table("daily_mood_reports")
