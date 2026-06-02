"""student mvp: user profiles and daily moments

Revision ID: 202606010003
Revises: 202606010002
Create Date: 2026-06-01
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "202606010003"
down_revision: str | None = "202606010002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "user_profiles",
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("student_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("gender", sa.String(16), nullable=True),
        sa.Column("companion_style", sa.String(16), nullable=True),
        sa.Column("today_mood", sa.String(32), nullable=True),
        sa.Column("onboarding_completed", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["student_id"], ["students.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("user_id"),
    )
    op.create_index("ix_user_profiles_student_id", "user_profiles", ["student_id"])

    op.create_table(
        "daily_moments",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("student_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("event_tags", postgresql.JSONB(), server_default=sa.text("'[]'::jsonb"), nullable=False),
        sa.Column("emotion_tag", sa.String(32), nullable=False),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("companion_scene", sa.String(128), nullable=False),
        sa.Column("companion_pose", sa.String(32), server_default="breathing", nullable=False),
        sa.Column("visual_payload", postgresql.JSONB(), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.Column("moment_date", sa.Date(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["student_id"], ["students.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_daily_moments_user_id", "daily_moments", ["user_id"])
    op.create_index("ix_daily_moments_moment_date", "daily_moments", ["moment_date"])
    op.create_index("ix_daily_moments_user_date", "daily_moments", ["user_id", "moment_date"])


def downgrade() -> None:
    op.drop_index("ix_daily_moments_user_date", table_name="daily_moments")
    op.drop_index("ix_daily_moments_moment_date", table_name="daily_moments")
    op.drop_index("ix_daily_moments_user_id", table_name="daily_moments")
    op.drop_table("daily_moments")
    op.drop_index("ix_user_profiles_student_id", table_name="user_profiles")
    op.drop_table("user_profiles")
