"""user growth state and emotion fragment aggregates

Revision ID: 202606090001
Revises: 202606010014
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "202606090001"
down_revision = "202606010014"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "user_growth_states",
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("growth_value", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("level", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("level_title", sa.String(length=32), nullable=False, server_default="漂流者"),
        sa.Column("streak_days", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("max_streak_days", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("next_level", sa.Integer(), nullable=True),
        sa.Column("next_level_title", sa.String(length=32), nullable=True),
        sa.Column("xp_into_level", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("xp_for_next_level", sa.Integer(), nullable=True),
        sa.Column("island_stage", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("unlock_label", sa.String(length=64), nullable=False, server_default=""),
        sa.Column("today_mood", sa.String(length=32), nullable=True),
        sa.Column("today_weather_label", sa.String(length=32), nullable=False, server_default="☀ 平静"),
        sa.Column("emotion_fragment_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column(
            "emotion_totals",
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
        sa.Column("island_seed", sa.Integer(), nullable=False, server_default="0"),
        sa.Column(
            "computed_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("user_id"),
    )


def downgrade() -> None:
    op.drop_table("user_growth_states")
