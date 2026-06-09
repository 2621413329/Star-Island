"""daily moment client event id

Revision ID: 202606090002
Revises: 202606090001
"""

from alembic import op
import sqlalchemy as sa


revision = "202606090002"
down_revision = "202606090001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "daily_moments",
        sa.Column("client_event_id", sa.String(length=96), nullable=True),
    )
    op.create_unique_constraint(
        "uq_daily_moments_user_client_event",
        "daily_moments",
        ["user_id", "client_event_id"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "uq_daily_moments_user_client_event",
        "daily_moments",
        type_="unique",
    )
    op.drop_column("daily_moments", "client_event_id")
