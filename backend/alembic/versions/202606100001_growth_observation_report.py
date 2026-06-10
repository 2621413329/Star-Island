"""growth_observation json on daily mood reports

Revision ID: 202606100001
Revises: 202606090002
Create Date: 2026-06-10
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "202606100001"
down_revision = "202606090002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "daily_mood_reports",
        sa.Column(
            "growth_observation",
            postgresql.JSONB(),
            server_default=sa.text("'{}'::jsonb"),
            nullable=False,
        ),
    )


def downgrade() -> None:
    op.drop_column("daily_mood_reports", "growth_observation")
