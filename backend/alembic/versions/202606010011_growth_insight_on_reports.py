"""growth_insight json on daily mood reports

Revision ID: 202606010011
Revises: 202606010010
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "202606010011"
down_revision = "202606010010"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "daily_mood_reports",
        sa.Column("growth_insight", postgresql.JSONB(), server_default=sa.text("'{}'::jsonb"), nullable=False),
    )


def downgrade() -> None:
    op.drop_column("daily_mood_reports", "growth_insight")
