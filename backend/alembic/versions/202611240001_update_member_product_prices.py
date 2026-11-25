"""update VIP member product prices to 9.9 / 19.9 / 59.9

Revision ID: 202611240001
Revises: 202607140001
Create Date: 2026-11-24

"""

from typing import Sequence, Union

from alembic import op

revision: str = "202611240001"
down_revision: Union[str, None] = "202607140001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        """
        UPDATE member_products
        SET price = CASE product_id
            WHEN 'com.xiaoerlcx.app.vip.monthly' THEN 9.90
            WHEN 'com.xiaoerlcx.app.vip.quarterly' THEN 19.90
            WHEN 'com.xiaoerlcx.app.vip.yearly' THEN 59.90
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
