"""unify all class names to 家人测试班

Revision ID: 202606010009
Revises: 202606010008
"""

from alembic import op

revision = "202606010009"
down_revision = "202606010008"
branch_labels = None
depends_on = None

TARGET = "家人测试班"


def upgrade() -> None:
    op.execute(f"UPDATE students SET class_name = '{TARGET}' WHERE class_name IS DISTINCT FROM '{TARGET}'")
    op.execute(
        f"UPDATE user_profiles SET class_name = '{TARGET}' "
        f"WHERE class_name IS NOT NULL AND class_name IS DISTINCT FROM '{TARGET}'"
    )


def downgrade() -> None:
    pass
