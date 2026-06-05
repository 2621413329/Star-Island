"""growth observation fields and teacher follow ups

Revision ID: 202606010010
Revises: 202606010009
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "202606010010"
down_revision = "202606010009"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("teacher_alert_instances", sa.Column("growth_status", sa.String(16), nullable=True))
    op.add_column("teacher_alert_instances", sa.Column("focus_tags", postgresql.JSONB(), nullable=True))
    op.add_column("teacher_alert_instances", sa.Column("focus_directions", postgresql.JSONB(), nullable=True))
    op.add_column("teacher_alert_instances", sa.Column("trend", sa.String(16), nullable=True))
    op.add_column("teacher_alert_instances", sa.Column("risk_level", sa.String(16), server_default="none"))
    op.add_column("teacher_alert_instances", sa.Column("risk_reminder", sa.String(256), nullable=True))
    op.add_column("teacher_alert_instances", sa.Column("ai_summary", sa.String(512), nullable=True))

    op.create_table(
        "teacher_follow_ups",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("student_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("teacher_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("action", sa.String(32), nullable=False),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["student_id"], ["students.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["teacher_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_teacher_follow_ups_student", "teacher_follow_ups", ["student_id"])


def downgrade() -> None:
    op.drop_index("ix_teacher_follow_ups_student", table_name="teacher_follow_ups")
    op.drop_table("teacher_follow_ups")
    for col in (
        "ai_summary",
        "risk_reminder",
        "risk_level",
        "trend",
        "focus_directions",
        "focus_tags",
        "growth_status",
    ):
        op.drop_column("teacher_alert_instances", col)
