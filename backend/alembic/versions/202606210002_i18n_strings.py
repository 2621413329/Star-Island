"""i18n_strings 多语言文案表。"""

import sqlalchemy as sa
from alembic import op

revision = "202606210002"
down_revision = "202606210001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "i18n_strings",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("key", sa.String(length=128), nullable=False),
        sa.Column("locale", sa.String(length=16), nullable=False),
        sa.Column("value", sa.String(length=1024), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False, server_default="active"),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("key", "locale", name="uq_i18n_strings_key_locale"),
    )
    op.create_index("ix_i18n_strings_key", "i18n_strings", ["key"])
    op.create_index("ix_i18n_strings_locale", "i18n_strings", ["locale"])


def downgrade() -> None:
    op.drop_index("ix_i18n_strings_locale", table_name="i18n_strings")
    op.drop_index("ix_i18n_strings_key", table_name="i18n_strings")
    op.drop_table("i18n_strings")
