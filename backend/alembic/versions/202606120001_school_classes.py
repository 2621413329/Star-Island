"""school_classes registry and student/teacher class bindings

Revision ID: 202606120001
Revises: 202606110001
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "202606120001"
down_revision = "202606110001"
branch_labels = None
depends_on = None

TARGET_CLASS = "测试班"
LEGACY_CLASS = "家人测试班"


def upgrade() -> None:
    op.create_table(
        "school_classes",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(64), nullable=False),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.UniqueConstraint("name", name="uq_school_classes_name"),
    )
    op.create_index("ix_school_classes_name", "school_classes", ["name"])

    # 使用 gen_random_uuid() 避免 asyncpg 将 Python 字符串绑定为 VARCHAR。
    op.execute(
        sa.text(
            "INSERT INTO school_classes (id, name, is_active) "
            "VALUES (gen_random_uuid(), :name, true)"
        ).bindparams(name=TARGET_CLASS)
    )

    op.add_column(
        "students",
        sa.Column("class_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_index("ix_students_class_id", "students", ["class_id"])
    op.create_foreign_key(
        "fk_students_class_id_school_classes",
        "students",
        "school_classes",
        ["class_id"],
        ["id"],
        ondelete="RESTRICT",
    )

    op.add_column(
        "user_profiles",
        sa.Column("class_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_index("ix_user_profiles_class_id", "user_profiles", ["class_id"])
    op.create_foreign_key(
        "fk_user_profiles_class_id_school_classes",
        "user_profiles",
        "school_classes",
        ["class_id"],
        ["id"],
        ondelete="RESTRICT",
    )

    op.execute(
        sa.text(
            "UPDATE students SET class_name = :target WHERE class_name = :legacy"
        ).bindparams(target=TARGET_CLASS, legacy=LEGACY_CLASS)
    )
    op.execute(
        sa.text(
            "UPDATE user_profiles SET class_name = :target WHERE class_name = :legacy"
        ).bindparams(target=TARGET_CLASS, legacy=LEGACY_CLASS)
    )
    op.execute(
        sa.text(
            "UPDATE students SET class_id = ("
            "  SELECT id FROM school_classes WHERE name = :target LIMIT 1"
            ") WHERE class_id IS NULL"
        ).bindparams(target=TARGET_CLASS)
    )
    op.execute(
        sa.text(
            "UPDATE user_profiles SET class_id = ("
            "  SELECT id FROM school_classes WHERE name = :target LIMIT 1"
            ") WHERE class_name = :target AND class_id IS NULL"
        ).bindparams(target=TARGET_CLASS)
    )


def downgrade() -> None:
    op.drop_constraint("fk_user_profiles_class_id_school_classes", "user_profiles", type_="foreignkey")
    op.drop_index("ix_user_profiles_class_id", table_name="user_profiles")
    op.drop_column("user_profiles", "class_id")
    op.drop_constraint("fk_students_class_id_school_classes", "students", type_="foreignkey")
    op.drop_index("ix_students_class_id", table_name="students")
    op.drop_column("students", "class_id")
    op.drop_index("ix_school_classes_name", table_name="school_classes")
    op.drop_table("school_classes")
