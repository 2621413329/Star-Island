"""moment voice fields

Revision ID: 202606210001
Revises: 202606160001
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "202606210001"
down_revision: str | None = "202606160001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "daily_moments",
        sa.Column(
            "content_type",
            sa.String(length=16),
            nullable=False,
            server_default="text",
        ),
    )
    op.add_column(
        "daily_moments",
        sa.Column("voice_url", sa.String(length=512), nullable=True),
    )
    op.add_column(
        "daily_moments",
        sa.Column("voice_duration", sa.Integer(), nullable=True),
    )
    op.add_column(
        "daily_moments",
        sa.Column("voice_size", sa.Integer(), nullable=True),
    )
    op.add_column(
        "daily_moments",
        sa.Column("speech_text", sa.Text(), nullable=True),
    )
    op.add_column(
        "daily_moments",
        sa.Column("speech_status", sa.String(length=16), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("daily_moments", "speech_status")
    op.drop_column("daily_moments", "speech_text")
    op.drop_column("daily_moments", "voice_size")
    op.drop_column("daily_moments", "voice_duration")
    op.drop_column("daily_moments", "voice_url")
    op.drop_column("daily_moments", "content_type")
