"""补充成长二级标签

Revision ID: 202606150005
Revises: 202606150004
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "202606150005"
down_revision: str | None = "202606150004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

NEW_TAGS: list[tuple[str, str]] = [
    ("life", "记录"),
    ("life", "复盘"),
    ("emotion", "自我觉察"),
    ("emotion", "身体关怀"),
]


def upgrade() -> None:
    conn = op.get_bind()
    for category_id, label in NEW_TAGS:
        safe = label.replace(" ", "_")
        tag_id = f"{category_id}_{safe}"[:64]
        exists = conn.execute(
            sa.text(
                "SELECT 1 FROM growth_tags WHERE category_id = :category_id AND label = :label"
            ),
            {"category_id": category_id, "label": label},
        ).first()
        if exists:
            continue
        sort_order = conn.execute(
            sa.text(
                "SELECT COALESCE(MAX(sort_order), 0) + 10 FROM growth_tags WHERE category_id = :category_id"
            ),
            {"category_id": category_id},
        ).scalar_one()
        conn.execute(
            sa.text(
                """
                INSERT INTO growth_tags (id, category_id, label, sort_order, is_active)
                VALUES (:id, :category_id, :label, :sort_order, true)
                """
            ),
            {
                "id": tag_id,
                "category_id": category_id,
                "label": label,
                "sort_order": sort_order,
            },
        )


def downgrade() -> None:
    conn = op.get_bind()
    for category_id, label in NEW_TAGS:
        conn.execute(
            sa.text(
                "DELETE FROM growth_tags WHERE category_id = :category_id AND label = :label"
            ),
            {"category_id": category_id, "label": label},
        )
