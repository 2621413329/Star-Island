import uuid
from datetime import date

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.growth_tag import GrowthTagCategory
from app.models.profile import DailyMoment
from app.models.story_island import StoryIsland, StoryIslandDecorUnlock


class StoryIslandRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_categories(self) -> list[GrowthTagCategory]:
        result = await self.db.execute(
            select(GrowthTagCategory)
            .where(GrowthTagCategory.is_active.is_(True))
            .order_by(GrowthTagCategory.sort_order.asc(), GrowthTagCategory.id.asc())
        )
        return list(result.scalars().all())

    async def list_by_user(self, user_id: uuid.UUID) -> list[StoryIsland]:
        result = await self.db.execute(
            select(StoryIsland)
            .options(selectinload(StoryIsland.decor_unlocks))
            .where(StoryIsland.user_id == user_id)
            .order_by(StoryIsland.sort_order.asc(), StoryIsland.created_at.asc())
        )
        return list(result.scalars().unique().all())

    async def list_by_user_and_category(
        self,
        user_id: uuid.UUID,
        category_id: str,
        *,
        include_archived: bool = False,
    ) -> list[StoryIsland]:
        stmt = (
            select(StoryIsland)
            .where(StoryIsland.user_id == user_id, StoryIsland.category_id == category_id)
            .order_by(StoryIsland.sort_order.asc(), StoryIsland.created_at.asc())
        )
        if not include_archived:
            stmt = stmt.where(StoryIsland.is_archived.is_(False))
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_id_and_user(self, island_id: uuid.UUID, user_id: uuid.UUID) -> StoryIsland | None:
        result = await self.db.execute(
            select(StoryIsland)
            .options(selectinload(StoryIsland.decor_unlocks))
            .where(StoryIsland.id == island_id, StoryIsland.user_id == user_id)
        )
        return result.scalar_one_or_none()

    async def save(self, island: StoryIsland) -> StoryIsland:
        self.db.add(island)
        await self.db.commit()
        await self.db.refresh(island)
        return island

    async def count_moments_by_island(self, user_id: uuid.UUID) -> dict[uuid.UUID, int]:
        result = await self.db.execute(
            select(DailyMoment.story_island_id, func.count(DailyMoment.id))
            .where(DailyMoment.user_id == user_id, DailyMoment.story_island_id.is_not(None))
            .group_by(DailyMoment.story_island_id)
        )
        return {island_id: int(count) for island_id, count in result.all() if island_id is not None}

    async def active_dates_by_island(self, user_id: uuid.UUID) -> dict[uuid.UUID, list[date]]:
        result = await self.db.execute(
            select(DailyMoment.story_island_id, DailyMoment.moment_date)
            .where(DailyMoment.user_id == user_id, DailyMoment.story_island_id.is_not(None))
            .distinct()
            .order_by(DailyMoment.story_island_id.asc(), DailyMoment.moment_date.asc())
        )
        out: dict[uuid.UUID, list[date]] = {}
        for island_id, moment_date in result.all():
            if island_id is None:
                continue
            out.setdefault(island_id, []).append(moment_date)
        return out

    async def max_sort_order(self, user_id: uuid.UUID, category_id: str) -> int:
        result = await self.db.execute(
            select(func.max(StoryIsland.sort_order)).where(
                StoryIsland.user_id == user_id,
                StoryIsland.category_id == category_id,
            )
        )
        return int(result.scalar_one_or_none() or 0)

    async def add_decor_unlock(self, unlock: StoryIslandDecorUnlock) -> StoryIslandDecorUnlock:
        self.db.add(unlock)
        await self.db.commit()
        await self.db.refresh(unlock)
        return unlock
