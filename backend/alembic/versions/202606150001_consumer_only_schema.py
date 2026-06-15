"""consumer-only schema: drop school/teacher tables and columns

Revision ID: 202606150001
Revises: 202606130001
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "202606150001"
down_revision = "202606130001"
branch_labels = None
depends_on = None


def _drop_fk(table: str, column: str) -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    for fk in inspector.get_foreign_keys(table):
        if column in fk.get("constrained_columns", []):
            op.drop_constraint(fk["name"], table, type_="foreignkey")
            return


def upgrade() -> None:
    # Teacher-only tables
    op.execute("DROP TABLE IF EXISTS teacher_risk_moment_follows CASCADE")
    op.execute("DROP TABLE IF EXISTS teacher_follow_ups CASCADE")
    op.execute("DROP TABLE IF EXISTS teacher_alert_instances CASCADE")

    # daily_mood_reports: remove teacher / school columns
    _drop_fk("daily_mood_reports", "student_id")
    op.drop_column("daily_mood_reports", "student_id")
    op.drop_column("daily_mood_reports", "teacher_radar_scores")
    op.drop_column("daily_mood_reports", "fuzzy_analysis")

    # daily_moments
    _drop_fk("daily_moments", "student_id")
    op.drop_column("daily_moments", "student_id")

    # user_profiles
    _drop_fk("user_profiles", "student_id")
    _drop_fk("user_profiles", "class_id")
    op.drop_column("user_profiles", "student_id")
    op.drop_column("user_profiles", "class_id")
    op.drop_column("user_profiles", "class_name")

    # School domain
    op.execute("DROP TABLE IF EXISTS observation_records CASCADE")
    op.execute("DROP TABLE IF EXISTS students CASCADE")
    op.execute("DROP TABLE IF EXISTS school_classes CASCADE")


def downgrade() -> None:
    raise NotImplementedError("consumer-only migration is not reversible")
