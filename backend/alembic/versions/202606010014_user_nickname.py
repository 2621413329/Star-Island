"""users nickname for display name

Revision ID: 202606010014
Revises: 202606010013
"""

from alembic import op
import sqlalchemy as sa

revision = "202606010014"
down_revision = "202606010013"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("users", sa.Column("nickname", sa.String(32), nullable=True))
    op.execute("UPDATE users SET nickname = username WHERE nickname IS NULL")


def downgrade() -> None:
    op.drop_column("users", "nickname")
