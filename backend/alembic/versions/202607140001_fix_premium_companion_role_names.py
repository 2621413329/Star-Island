"""fix premium companion role names

Revision ID: 202607140001
Revises: 202607130001
Create Date: 2026-07-14 09:42:00.000000
"""

from typing import Sequence, Union

from alembic import op


revision: str = "202607140001"
down_revision: Union[str, None] = "202607130001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("UPDATE companion_roles SET display_name = '小愿' WHERE id = 'yuan'")
    op.execute("UPDATE companion_roles SET display_name = '小梦' WHERE id = 'meng'")


def downgrade() -> None:
    op.execute("UPDATE companion_roles SET display_name = '小元' WHERE id = 'yuan'")
    op.execute("UPDATE companion_roles SET display_name = '小萌' WHERE id = 'meng'")
