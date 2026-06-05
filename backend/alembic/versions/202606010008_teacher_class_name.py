"""teacher profile class_name for data isolation

Revision ID: 202606010008
Revises: 202606010007
"""

from alembic import op
import sqlalchemy as sa

revision = "202606010008"
down_revision = "202606010007"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("user_profiles", sa.Column("class_name", sa.String(64), nullable=True))
    op.create_index("ix_user_profiles_class_name", "user_profiles", ["class_name"])


def downgrade() -> None:
    op.drop_index("ix_user_profiles_class_name", table_name="user_profiles")
    op.drop_column("user_profiles", "class_name")
