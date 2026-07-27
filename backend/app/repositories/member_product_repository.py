import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.member import MemberProduct


class MemberProductRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, product_id: uuid.UUID) -> MemberProduct | None:
        return await self.db.get(MemberProduct, product_id)

    async def get_by_apple_product_id(self, apple_product_id: str) -> MemberProduct | None:
        result = await self.db.execute(
            select(MemberProduct).where(MemberProduct.product_id == apple_product_id)
        )
        return result.scalar_one_or_none()

    async def list_all(self, *, enable_only: bool = False) -> list[MemberProduct]:
        stmt = select(MemberProduct).order_by(MemberProduct.created_at.desc())
        if enable_only:
            stmt = stmt.where(MemberProduct.enable.is_(True))
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def create(self, product: MemberProduct) -> MemberProduct:
        self.db.add(product)
        await self.db.commit()
        await self.db.refresh(product)
        return product

    async def save(self, product: MemberProduct) -> MemberProduct:
        await self.db.commit()
        await self.db.refresh(product)
        return product
