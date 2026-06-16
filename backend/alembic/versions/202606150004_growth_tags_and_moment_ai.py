"""growth tags + moment AI fields

Revision ID: 202606150004
Revises: 202606150003
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

from app.config.growth_tag_seed import GROWTH_TAG_SEED

revision: str = "202606150004"
down_revision: str | None = "202606150003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "growth_tag_categories",
        sa.Column("id", sa.String(length=32), nullable=False),
        sa.Column("label", sa.String(length=32), nullable=False),
        sa.Column("icon", sa.String(length=64), nullable=False, server_default="label"),
        sa.Column("color", sa.String(length=16), nullable=False, server_default="#78909C"),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "growth_tags",
        sa.Column("id", sa.String(length=64), nullable=False),
        sa.Column("category_id", sa.String(length=32), nullable=False),
        sa.Column("label", sa.String(length=32), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["category_id"], ["growth_tag_categories.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("category_id", "label", name="uq_growth_tags_category_label"),
    )
    op.create_index("ix_growth_tags_category_id", "growth_tags", ["category_id"])

    categories_table = sa.table(
        "growth_tag_categories",
        sa.column("id", sa.String),
        sa.column("label", sa.String),
        sa.column("icon", sa.String),
        sa.column("color", sa.String),
        sa.column("sort_order", sa.Integer),
        sa.column("is_active", sa.Boolean),
    )
    tags_table = sa.table(
        "growth_tags",
        sa.column("id", sa.String),
        sa.column("category_id", sa.String),
        sa.column("label", sa.String),
        sa.column("sort_order", sa.Integer),
        sa.column("is_active", sa.Boolean),
    )

    category_rows = []
    tag_rows = []
    for category in GROWTH_TAG_SEED:
        category_rows.append(
            {
                "id": category["id"],
                "label": category["label"],
                "icon": category["icon"],
                "color": category["color"],
                "sort_order": category["sort_order"],
                "is_active": True,
            }
        )
        for index, label in enumerate(category["tags"]):
            safe = label.replace(" ", "_")
            tag_rows.append(
                {
                    "id": f"{category['id']}_{safe}"[:64],
                    "category_id": category["id"],
                    "label": label,
                    "sort_order": (index + 1) * 10,
                    "is_active": True,
                }
            )
    op.bulk_insert(categories_table, category_rows)
    op.bulk_insert(tags_table, tag_rows)

    op.add_column("daily_moments", sa.Column("primary_tag", sa.String(length=32), nullable=True))
    op.add_column("daily_moments", sa.Column("secondary_tags", postgresql.JSONB(), server_default=sa.text("'[]'::jsonb"), nullable=False))
    op.add_column("daily_moments", sa.Column("growth_points", postgresql.JSONB(), server_default=sa.text("'[]'::jsonb"), nullable=False))
    op.add_column("daily_moments", sa.Column("ai_emotion", sa.String(length=32), nullable=True))


def downgrade() -> None:
    op.drop_column("daily_moments", "ai_emotion")
    op.drop_column("daily_moments", "growth_points")
    op.drop_column("daily_moments", "secondary_tags")
    op.drop_column("daily_moments", "primary_tag")
    op.drop_index("ix_growth_tags_category_id", table_name="growth_tags")
    op.drop_table("growth_tags")
    op.drop_table("growth_tag_categories")
