"""story island tasks and growth

Revision ID: 202606290002
Revises: 202606290001
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql


revision: str = "202606290002"
down_revision: str | None = "202606290001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "story_islands",
        sa.Column("size_kind", sa.String(length=16), nullable=False, server_default="small"),
    )
    op.add_column(
        "story_islands",
        sa.Column("growth_value", sa.Integer(), nullable=False, server_default="0"),
    )

    op.create_table(
        "story_island_tasks",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("island_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("title", sa.String(length=80), nullable=False),
        sa.Column("is_daily", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_archived", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["island_id"], ["story_islands.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_story_island_tasks_user_id", "story_island_tasks", ["user_id"])
    op.create_index("ix_story_island_tasks_island_id", "story_island_tasks", ["island_id"])

    op.create_table(
        "story_island_task_completions",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("island_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("task_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("completed_on", sa.Date(), nullable=False),
        sa.Column("growth_delta", sa.Integer(), nullable=False, server_default="5"),
        sa.Column("completed_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["island_id"], ["story_islands.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["task_id"], ["story_island_tasks.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("task_id", "completed_on", name="uq_story_island_task_completion_day"),
    )
    op.create_index("ix_story_island_task_completions_user_id", "story_island_task_completions", ["user_id"])
    op.create_index("ix_story_island_task_completions_island_id", "story_island_task_completions", ["island_id"])
    op.create_index("ix_story_island_task_completions_task_id", "story_island_task_completions", ["task_id"])
    op.create_index("ix_story_island_task_completions_completed_on", "story_island_task_completions", ["completed_on"])


def downgrade() -> None:
    op.drop_index("ix_story_island_task_completions_completed_on", table_name="story_island_task_completions")
    op.drop_index("ix_story_island_task_completions_task_id", table_name="story_island_task_completions")
    op.drop_index("ix_story_island_task_completions_island_id", table_name="story_island_task_completions")
    op.drop_index("ix_story_island_task_completions_user_id", table_name="story_island_task_completions")
    op.drop_table("story_island_task_completions")
    op.drop_index("ix_story_island_tasks_island_id", table_name="story_island_tasks")
    op.drop_index("ix_story_island_tasks_user_id", table_name="story_island_tasks")
    op.drop_table("story_island_tasks")
    op.drop_column("story_islands", "growth_value")
    op.drop_column("story_islands", "size_kind")
