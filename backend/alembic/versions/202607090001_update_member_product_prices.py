"""update VIP member product prices

Revision ID: 202607090001
Revises: 202607080001
Create Date: 2026-07-09

"""

from typing import Sequence, Union

from alembic import op

revision: str = "202607090001"
down_revision: Union[str, None] = "202607080001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        """
        UPDATE member_products
        SET price = CASE product_id
            WHEN 'com.xiaoerlcx.app.vip.monthly' THEN 12.00
            WHEN 'com.xiaoerlcx.app.vip.quarterly' THEN 28.00
            WHEN 'com.xiaoerlcx.app.vip.yearly' THEN 98.00
            ELSE price
        END,
        updated_at = now()
        WHERE product_id IN (
            'com.xiaoerlcx.app.vip.monthly',
            'com.xiaoerlcx.app.vip.quarterly',
            'com.xiaoerlcx.app.vip.yearly'
        )
        """
    )


def downgrade() -> None:
    op.execute(
        """
        UPDATE member_products
        SET price = CASE product_id
            WHEN 'com.xiaoerlcx.app.vip.monthly' THEN 9.90
            WHEN 'com.xiaoerlcx.app.vip.quarterly' THEN 19.90
            WHEN 'com.xiaoerlcx.app.vip.yearly' THEN 99.90
            ELSE price
        END,
        updated_at = now()
        WHERE product_id IN (
            'com.xiaoerlcx.app.vip.monthly',
            'com.xiaoerlcx.app.vip.quarterly',
            'com.xiaoerlcx.app.vip.yearly'
        )
        """
    )
