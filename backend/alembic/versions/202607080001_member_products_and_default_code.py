"""seed VIP products and default activation code

Revision ID: 202607080001
Revises: 202607070002
Create Date: 2026-07-08

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "202607080001"
down_revision: Union[str, None] = "202607070002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "activation_codes",
        sa.Column("reusable", sa.Boolean(), server_default=sa.text("false"), nullable=False),
    )

    op.execute(
        """
        INSERT INTO member_products (
            id, product_id, name, membership_type, duration_days, price, currency,
            enable, entitlement, source, created_at, updated_at
        )
        VALUES
            (
                '1b4a8f70-3e0d-4a13-90c8-80f2cf2f0001',
                'com.xiaoerlcx.app.vip.monthly',
                'VIP 月卡',
                'monthly',
                30,
                9.90,
                'CNY',
                true,
                'vip',
                'apple',
                now(),
                now()
            ),
            (
                '1b4a8f70-3e0d-4a13-90c8-80f2cf2f0002',
                'com.xiaoerlcx.app.vip.quarterly',
                'VIP 季卡',
                'quarterly',
                90,
                19.90,
                'CNY',
                true,
                'vip',
                'apple',
                now(),
                now()
            ),
            (
                '1b4a8f70-3e0d-4a13-90c8-80f2cf2f0003',
                'com.xiaoerlcx.app.vip.yearly',
                'VIP 年卡',
                'yearly',
                365,
                99.90,
                'CNY',
                true,
                'vip',
                'apple',
                now(),
                now()
            )
        ON CONFLICT (product_id) DO UPDATE SET
            name = EXCLUDED.name,
            membership_type = EXCLUDED.membership_type,
            duration_days = EXCLUDED.duration_days,
            price = EXCLUDED.price,
            currency = EXCLUDED.currency,
            enable = EXCLUDED.enable,
            entitlement = EXCLUDED.entitlement,
            source = EXCLUDED.source,
            updated_at = now()
        """
    )

    op.execute(
        """
        INSERT INTO activation_codes (
            id, code, membership_type, duration_days, status, reusable,
            batch_no, remark, created_at
        )
        VALUES (
            '1b4a8f70-3e0d-4a13-90c8-80f2cf2f0100',
            'lcxdsg',
            'yearly',
            365,
            'unused',
            true,
            'default',
            '默认可复用测试激活码；可通过 status=disabled 停用',
            now()
        )
        ON CONFLICT (code) DO NOTHING
        """
    )


def downgrade() -> None:
    op.execute(
        """
        DELETE FROM activation_codes
        WHERE lower(code) = 'lcxdsg' AND batch_no = 'default'
        """
    )
    op.execute(
        """
        DELETE FROM member_products
        WHERE product_id IN (
            'com.xiaoerlcx.app.vip.monthly',
            'com.xiaoerlcx.app.vip.quarterly',
            'com.xiaoerlcx.app.vip.yearly'
        )
        """
    )
    op.drop_column("activation_codes", "reusable")
