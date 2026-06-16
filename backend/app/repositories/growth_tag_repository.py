import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.growth_tag import GrowthTag, GrowthTagCategory


class GrowthTagRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_categories(self, *, active_only: bool = True) -> list[GrowthTagCategory]:
        stmt = (
            select(GrowthTagCategory)
            .options(selectinload(GrowthTagCategory.tags))
            .order_by(GrowthTagCategory.sort_order.asc(), GrowthTagCategory.id.asc())
        )
        if active_only:
            stmt = stmt.where(GrowthTagCategory.is_active.is_(True))
        result = await self.db.execute(stmt)
        categories = list(result.scalars().unique().all())
        if active_only:
            for category in categories:
                category.tags = [tag for tag in category.tags if tag.is_active]
        return categories

    async def get_category(self, category_id: str) -> GrowthTagCategory | None:
        result = await self.db.execute(
            select(GrowthTagCategory)
            .options(selectinload(GrowthTagCategory.tags))
            .where(GrowthTagCategory.id == category_id)
        )
        return result.scalar_one_or_none()

    async def save_category(self, category: GrowthTagCategory) -> GrowthTagCategory:
        self.db.add(category)
        await self.db.commit()
        await self.db.refresh(category)
        return category

    async def get_tag(self, tag_id: str) -> GrowthTag | None:
        result = await self.db.execute(select(GrowthTag).where(GrowthTag.id == tag_id))
        return result.scalar_one_or_none()

    async def save_tag(self, tag: GrowthTag) -> GrowthTag:
        self.db.add(tag)
        await self.db.commit()
        await self.db.refresh(tag)
        return tag

    async def delete_tag(self, tag: GrowthTag) -> None:
        await self.db.delete(tag)
        await self.db.commit()

    @staticmethod
    def slug_tag_id(category_id: str, label: str) -> str:
        safe = label.strip().replace(" ", "_")
        return f"{category_id}_{safe}"[:64]
