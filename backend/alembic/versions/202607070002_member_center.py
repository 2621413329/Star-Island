"""member center tables

Revision ID: 202607070002
Revises: 202607070001
Create Date: 2026-07-07

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "202607070002"
down_revision: Union[str, None] = "202607070001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "member_products",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("product_id", sa.String(length=255), nullable=True),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("membership_type", sa.String(length=32), nullable=False),
        sa.Column("duration_days", sa.Integer(), nullable=True),
        sa.Column("price", sa.Numeric(precision=10, scale=2), server_default="0", nullable=False),
        sa.Column("currency", sa.String(length=3), server_default="CNY", nullable=False),
        sa.Column("enable", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("entitlement", sa.String(length=64), server_default="vip", nullable=False),
        sa.Column("source", sa.String(length=32), nullable=False),
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
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("product_id"),
    )
    op.create_index("ix_member_products_product_id", "member_products", ["product_id"])
    op.create_index("ix_member_products_membership_type", "member_products", ["membership_type"])
    op.create_index("ix_member_products_entitlement", "member_products", ["entitlement"])
    op.create_index("ix_member_products_source", "member_products", ["source"])

    op.create_table(
        "activation_codes",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("code", sa.String(length=64), nullable=False),
        sa.Column("membership_type", sa.String(length=32), nullable=False),
        sa.Column("duration_days", sa.Integer(), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("used_time", sa.DateTime(timezone=True), nullable=True),
        sa.Column("expire_time", sa.DateTime(timezone=True), nullable=True),
        sa.Column("batch_no", sa.String(length=64), nullable=True),
        sa.Column("remark", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("code"),
    )
    op.create_index("ix_activation_codes_code", "activation_codes", ["code"])
    op.create_index("ix_activation_codes_membership_type", "activation_codes", ["membership_type"])
    op.create_index("ix_activation_codes_status", "activation_codes", ["status"])
    op.create_index("ix_activation_codes_user_id", "activation_codes", ["user_id"])
    op.create_index("ix_activation_codes_batch_no", "activation_codes", ["batch_no"])

    op.create_table(
        "member_records",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("product_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("source", sa.String(length=32), nullable=False),
        sa.Column("transaction_id", sa.String(length=255), nullable=True),
        sa.Column("original_transaction_id", sa.String(length=255), nullable=True),
        sa.Column("activation_code_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("admin_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("membership_type", sa.String(length=32), nullable=False),
        sa.Column("start_time", sa.DateTime(timezone=True), nullable=False),
        sa.Column("end_time", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("remark", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["activation_code_id"], ["activation_codes.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["admin_id"], ["users.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["product_id"], ["member_products.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("transaction_id"),
    )
    op.create_index("ix_member_records_user_id", "member_records", ["user_id"])
    op.create_index("ix_member_records_product_id", "member_records", ["product_id"])
    op.create_index("ix_member_records_source", "member_records", ["source"])
    op.create_index("ix_member_records_original_transaction_id", "member_records", ["original_transaction_id"])
    op.create_index("ix_member_records_activation_code_id", "member_records", ["activation_code_id"])
    op.create_index("ix_member_records_admin_id", "member_records", ["admin_id"])
    op.create_index("ix_member_records_membership_type", "member_records", ["membership_type"])
    op.create_index("ix_member_records_status", "member_records", ["status"])

    op.create_table(
        "user_membership",
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("membership_type", sa.String(length=32), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("start_time", sa.DateTime(timezone=True), nullable=True),
        sa.Column("end_time", sa.DateTime(timezone=True), nullable=True),
        sa.Column("source", sa.String(length=32), nullable=True),
        sa.Column("latest_record_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["latest_record_id"], ["member_records.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("user_id"),
    )
    op.create_index("ix_user_membership_status", "user_membership", ["status"])
    op.create_index("ix_user_membership_source", "user_membership", ["source"])

    # Migrate legacy IAP data when present.
    op.execute(
        """
        INSERT INTO member_products (
            id, product_id, name, membership_type, duration_days, price, currency,
            enable, entitlement, source, created_at, updated_at
        )
        SELECT
            id,
            product_id,
            name,
            CASE
                WHEN product_type ILIKE '%lifetime%' THEN 'lifetime'
                WHEN duration_days >= 365 THEN 'yearly'
                WHEN duration_days >= 90 THEN 'quarterly'
                ELSE 'monthly'
            END,
            duration_days,
            price,
            currency,
            enable,
            'vip',
            'apple',
            created_at,
            created_at
        FROM iap_products
        ON CONFLICT (product_id) DO NOTHING
        """
    )
    op.execute(
        """
        INSERT INTO member_records (
            id, user_id, product_id, source, transaction_id, original_transaction_id,
            membership_type, start_time, end_time, status, created_at
        )
        SELECT
            p.id,
            p.user_id,
            mp.id,
            'apple',
            p.transaction_id,
            p.original_transaction_id,
            COALESCE(mp.membership_type, 'monthly'),
            p.purchase_date,
            p.expires_date,
            p.status,
            p.created_at
        FROM iap_purchases p
        LEFT JOIN member_products mp ON mp.product_id = p.product_id
        ON CONFLICT (transaction_id) DO NOTHING
        """
    )
    op.execute(
        """
        INSERT INTO user_membership (
            user_id, membership_type, status, start_time, end_time, source, updated_at
        )
        SELECT DISTINCT ON (e.user_id)
            e.user_id,
            COALESCE(mp.membership_type, 'monthly'),
            CASE WHEN e.status = 'active' THEN 'active' ELSE 'expired' END,
            e.start_time,
            e.end_time,
            'apple',
            NOW()
        FROM user_entitlements e
        LEFT JOIN member_products mp ON mp.product_id = e.entitlement
        ORDER BY e.user_id, e.end_time DESC NULLS FIRST
        ON CONFLICT (user_id) DO NOTHING
        """
    )

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


def downgrade() -> None:
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

    op.drop_index("ix_user_membership_source", table_name="user_membership")
    op.drop_index("ix_user_membership_status", table_name="user_membership")
    op.drop_table("user_membership")

    op.drop_index("ix_member_records_status", table_name="member_records")
    op.drop_index("ix_member_records_membership_type", table_name="member_records")
    op.drop_index("ix_member_records_admin_id", table_name="member_records")
    op.drop_index("ix_member_records_activation_code_id", table_name="member_records")
    op.drop_index("ix_member_records_original_transaction_id", table_name="member_records")
    op.drop_index("ix_member_records_source", table_name="member_records")
    op.drop_index("ix_member_records_product_id", table_name="member_records")
    op.drop_index("ix_member_records_user_id", table_name="member_records")
    op.drop_table("member_records")

    op.drop_index("ix_activation_codes_batch_no", table_name="activation_codes")
    op.drop_index("ix_activation_codes_user_id", table_name="activation_codes")
    op.drop_index("ix_activation_codes_status", table_name="activation_codes")
    op.drop_index("ix_activation_codes_membership_type", table_name="activation_codes")
    op.drop_index("ix_activation_codes_code", table_name="activation_codes")
    op.drop_table("activation_codes")

    op.drop_index("ix_member_products_source", table_name="member_products")
    op.drop_index("ix_member_products_entitlement", table_name="member_products")
    op.drop_index("ix_member_products_membership_type", table_name="member_products")
    op.drop_index("ix_member_products_product_id", table_name="member_products")
    op.drop_table("member_products")
