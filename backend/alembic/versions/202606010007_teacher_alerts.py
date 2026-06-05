"""teacher alerts and teacher role seed

Revision ID: 202606010007
Revises: 202606010006
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "202606010007"
down_revision = "202606010006"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "teacher_alert_instances",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("alert_key", sa.String(128), nullable=False),
        sa.Column("student_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("alert_type", sa.String(32), nullable=False),
        sa.Column("report_date", sa.Date(), nullable=True),
        sa.Column("date_end", sa.Date(), nullable=False),
        sa.Column("title", sa.String(64), nullable=False),
        sa.Column("summary", sa.String(256), nullable=False),
        sa.Column("payload", postgresql.JSONB(), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.Column("priority", sa.Integer(), server_default="1", nullable=False),
        sa.Column("status", sa.String(16), server_default="pending", nullable=False),
        sa.Column("acked_by", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("acked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["student_id"], ["students.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["acked_by"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("alert_key", name="uq_teacher_alert_key"),
    )
    op.create_index("ix_teacher_alert_student", "teacher_alert_instances", ["student_id"])
    op.create_index("ix_teacher_alert_status", "teacher_alert_instances", ["status"])
    op.create_index("ix_teacher_alert_date_end", "teacher_alert_instances", ["date_end"])

    op.execute(
        """
        INSERT INTO roles (id, name, description, created_at)
        SELECT gen_random_uuid(), 'teacher', '班主任/教师端账号', now()
        WHERE NOT EXISTS (SELECT 1 FROM roles WHERE name = 'teacher')
        """
    )


def downgrade() -> None:
    op.drop_index("ix_teacher_alert_date_end", table_name="teacher_alert_instances")
    op.drop_index("ix_teacher_alert_status", table_name="teacher_alert_instances")
    op.drop_index("ix_teacher_alert_student", table_name="teacher_alert_instances")
    op.drop_table("teacher_alert_instances")
