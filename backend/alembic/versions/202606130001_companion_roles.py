"""companion_roles registry and user_profiles.companion_role_id

Revision ID: 202606130001
Revises: 202606120001
"""

from alembic import op
import sqlalchemy as sa

revision = "202606130001"
down_revision = "202606120001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "companion_roles",
        sa.Column("id", sa.String(32), primary_key=True),
        sa.Column("display_name", sa.String(32), nullable=False),
        sa.Column("render_key", sa.String(16), nullable=False),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("sort_order", sa.Integer(), server_default=sa.text("0"), nullable=False),
    )
    op.bulk_insert(
        sa.table(
            "companion_roles",
            sa.column("id", sa.String),
            sa.column("display_name", sa.String),
            sa.column("render_key", sa.String),
            sa.column("is_active", sa.Boolean),
            sa.column("sort_order", sa.Integer),
        ),
        [
            {
                "id": "xiao_xingzai",
                "display_name": "小星仔",
                "render_key": "male",
                "is_active": True,
                "sort_order": 0,
            },
            {
                "id": "xiao_guangbao",
                "display_name": "小光宝",
                "render_key": "female",
                "is_active": True,
                "sort_order": 1,
            },
        ],
    )

    op.add_column(
        "user_profiles",
        sa.Column("companion_role_id", sa.String(32), nullable=True),
    )
    op.create_foreign_key(
        "fk_user_profiles_companion_role_id",
        "user_profiles",
        "companion_roles",
        ["companion_role_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_index(
        "ix_user_profiles_companion_role_id",
        "user_profiles",
        ["companion_role_id"],
    )

    op.execute(
        """
        UPDATE user_profiles
        SET companion_role_id = CASE gender
            WHEN 'male' THEN 'xiao_xingzai'
            WHEN 'female' THEN 'xiao_guangbao'
            ELSE NULL
        END
        WHERE companion_role_id IS NULL
        """
    )


def downgrade() -> None:
    op.drop_index("ix_user_profiles_companion_role_id", table_name="user_profiles")
    op.drop_constraint(
        "fk_user_profiles_companion_role_id",
        "user_profiles",
        type_="foreignkey",
    )
    op.drop_column("user_profiles", "companion_role_id")
    op.drop_table("companion_roles")
