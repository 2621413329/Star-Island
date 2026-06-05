"""teacher risk moment follows

Revision ID: 202606010013
Revises: 202606010012
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "202606010013"
down_revision = "202606010012"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "teacher_risk_moment_follows",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("moment_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("student_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("teacher_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("status", sa.String(16), nullable=False, server_default="followed"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("followed_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["moment_id"], ["daily_moments.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["student_id"], ["students.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["teacher_id"], ["users.id"], ondelete="CASCADE"),
        sa.UniqueConstraint("moment_id", name="uq_teacher_risk_moment_follow"),
    )
    op.create_index("ix_teacher_risk_moment_follow_student", "teacher_risk_moment_follows", ["student_id"])


def downgrade() -> None:
    op.drop_index("ix_teacher_risk_moment_follow_student", table_name="teacher_risk_moment_follows")
    op.drop_table("teacher_risk_moment_follows")
