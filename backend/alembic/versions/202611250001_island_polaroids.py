"""island polaroids

Revision ID: 202611250001
Revises: 202611240001
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "202611250001"
down_revision: str | None = "202611240001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "island_polaroids",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("island_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("island_kind", sa.String(length=16), nullable=False),
        sa.Column("level", sa.Integer(), nullable=False),
        sa.Column("building_name", sa.String(length=64), nullable=False),
        sa.Column("asset_key", sa.String(length=128), nullable=False, server_default=""),
        sa.Column("category_id", sa.String(length=32), nullable=False, server_default=""),
        sa.Column("companion_role", sa.String(length=32), nullable=False, server_default=""),
        sa.Column("skin_id", sa.String(length=32), nullable=False, server_default="plain"),
        sa.Column("taken_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("front_caption", sa.String(length=80), nullable=False),
        sa.Column("back_summary", sa.Text(), nullable=True),
        sa.Column("back_status", sa.String(length=16), nullable=False, server_default="fallback"),
        sa.Column("captured_live", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column(
            "source_moments",
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=False,
            server_default=sa.text("'[]'::jsonb"),
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["island_id"], ["story_islands.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "user_id",
            "island_id",
            "level",
            name="uq_island_polaroids_user_island_level",
        ),
    )
    op.create_index("ix_island_polaroids_user_id", "island_polaroids", ["user_id"])
    op.create_index("ix_island_polaroids_island_id", "island_polaroids", ["island_id"])


def downgrade() -> None:
    op.drop_index("ix_island_polaroids_island_id", table_name="island_polaroids")
    op.drop_index("ix_island_polaroids_user_id", table_name="island_polaroids")
    op.drop_table("island_polaroids")
