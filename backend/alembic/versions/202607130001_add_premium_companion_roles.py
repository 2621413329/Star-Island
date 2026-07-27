"""add premium companion roles

Revision ID: 202607130001
Revises: 202607090001
Create Date: 2026-07-13 12:09:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "202607130001"
down_revision: Union[str, None] = "202607090001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    roles = sa.table(
        "companion_roles",
        sa.column("id", sa.String),
        sa.column("display_name", sa.String),
        sa.column("render_key", sa.String),
        sa.column("is_active", sa.Boolean),
        sa.column("sort_order", sa.Integer),
    )
    op.bulk_insert(
        roles,
        [
            {
                "id": "yuan",
                "display_name": "小愿",
                "render_key": "yuan",
                "is_active": True,
                "sort_order": 2,
            },
            {
                "id": "meng",
                "display_name": "小梦",
                "render_key": "meng",
                "is_active": True,
                "sort_order": 3,
            },
        ],
    )


def downgrade() -> None:
    op.execute("DELETE FROM companion_roles WHERE id IN ('yuan', 'meng')")
