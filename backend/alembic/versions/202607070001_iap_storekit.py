"""iap storekit subscription tables

Revision ID: 202607070001
Revises: 202607010002
Create Date: 2026-07-07

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "202607070001"
down_revision: Union[str, None] = "202607010002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "iap_products",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("product_id", sa.String(length=255), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("product_type", sa.String(length=64), nullable=False),
        sa.Column("duration_days", sa.Integer(), nullable=True),
        sa.Column("price", sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("enable", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("product_id"),
    )
    op.create_index("ix_iap_products_product_id", "iap_products", ["product_id"])
    op.create_index("ix_iap_products_product_type", "iap_products", ["product_type"])

    op.create_table(
        "iap_purchases",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("product_id", sa.String(length=255), nullable=False),
        sa.Column("transaction_id", sa.String(length=255), nullable=False),
        sa.Column("original_transaction_id", sa.String(length=255), nullable=False),
        sa.Column("purchase_date", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_date", sa.DateTime(timezone=True), nullable=True),
        sa.Column("environment", sa.String(length=32), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("receipt", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["product_id"], ["iap_products.product_id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("transaction_id"),
    )
    op.create_index("ix_iap_purchases_user_id", "iap_purchases", ["user_id"])
    op.create_index("ix_iap_purchases_product_id", "iap_purchases", ["product_id"])
    op.create_index("ix_iap_purchases_original_transaction_id", "iap_purchases", ["original_transaction_id"])
    op.create_index("ix_iap_purchases_environment", "iap_purchases", ["environment"])
    op.create_index("ix_iap_purchases_status", "iap_purchases", ["status"])

    op.create_table(
        "user_entitlements",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("entitlement", sa.String(length=64), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("start_time", sa.DateTime(timezone=True), nullable=False),
        sa.Column("end_time", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_user_entitlements_user_id", "user_entitlements", ["user_id"])
    op.create_index("ix_user_entitlements_entitlement", "user_entitlements", ["entitlement"])
    op.create_index("ix_user_entitlements_status", "user_entitlements", ["status"])


def downgrade() -> None:
    op.drop_index("ix_user_entitlements_status", table_name="user_entitlements")
    op.drop_index("ix_user_entitlements_entitlement", table_name="user_entitlements")
    op.drop_index("ix_user_entitlements_user_id", table_name="user_entitlements")
    op.drop_table("user_entitlements")

    op.drop_index("ix_iap_purchases_status", table_name="iap_purchases")
    op.drop_index("ix_iap_purchases_environment", table_name="iap_purchases")
    op.drop_index("ix_iap_purchases_original_transaction_id", table_name="iap_purchases")
    op.drop_index("ix_iap_purchases_product_id", table_name="iap_purchases")
    op.drop_index("ix_iap_purchases_user_id", table_name="iap_purchases")
    op.drop_table("iap_purchases")

    op.drop_index("ix_iap_products_product_type", table_name="iap_products")
    op.drop_index("ix_iap_products_product_id", table_name="iap_products")
    op.drop_table("iap_products")
