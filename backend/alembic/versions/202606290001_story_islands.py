"""story islands

Revision ID: 202606290001
Revises: 202606210002
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql


revision: str = "202606290001"
down_revision: str | None = "202606210002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "story_islands",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("category_id", sa.String(length=32), nullable=False),
        sa.Column("name", sa.String(length=32), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("target_completion_days", sa.Integer(), nullable=False, server_default="90"),
        sa.Column("completion_target_date", sa.Date(), nullable=True),
        sa.Column("cover_image_key", sa.String(length=128), nullable=True),
        sa.Column(
            "background_config",
            postgresql.JSONB(),
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
        sa.Column("is_archived", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["category_id"], ["growth_tag_categories.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "category_id", "name", name="uq_story_islands_user_category_name"),
    )
    op.create_index("ix_story_islands_user_id", "story_islands", ["user_id"])
    op.create_index("ix_story_islands_category_id", "story_islands", ["category_id"])

    op.create_table(
        "story_island_decor_unlocks",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("island_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("decor_id", sa.String(length=64), nullable=False),
        sa.Column("unlock_order", sa.Integer(), nullable=False),
        sa.Column("unlocked_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["island_id"], ["story_islands.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("island_id", "decor_id", name="uq_story_island_decor_unlock"),
    )
    op.create_index("ix_story_island_decor_unlocks_user_id", "story_island_decor_unlocks", ["user_id"])
    op.create_index("ix_story_island_decor_unlocks_island_id", "story_island_decor_unlocks", ["island_id"])

    op.add_column(
        "daily_moments",
        sa.Column("story_island_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_index("ix_daily_moments_story_island_id", "daily_moments", ["story_island_id"])
    op.create_foreign_key(
        "fk_daily_moments_story_island_id",
        "daily_moments",
        "story_islands",
        ["story_island_id"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_constraint("fk_daily_moments_story_island_id", "daily_moments", type_="foreignkey")
    op.drop_index("ix_daily_moments_story_island_id", table_name="daily_moments")
    op.drop_column("daily_moments", "story_island_id")
    op.drop_index("ix_story_island_decor_unlocks_island_id", table_name="story_island_decor_unlocks")
    op.drop_index("ix_story_island_decor_unlocks_user_id", table_name="story_island_decor_unlocks")
    op.drop_table("story_island_decor_unlocks")
    op.drop_index("ix_story_islands_category_id", table_name="story_islands")
    op.drop_index("ix_story_islands_user_id", table_name="story_islands")
    op.drop_table("story_islands")
