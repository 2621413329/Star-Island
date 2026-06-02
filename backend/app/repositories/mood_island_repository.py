from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.mood_island import MoodIslandStyle


class MoodIslandRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_active(self) -> list[MoodIslandStyle]:
        result = await self.db.execute(
            select(MoodIslandStyle).where(MoodIslandStyle.is_active.is_(True)).order_by(MoodIslandStyle.mood_id)
        )
        return list(result.scalars().all())

    async def get(self, mood_id: str) -> MoodIslandStyle | None:
        return await self.db.get(MoodIslandStyle, mood_id)

    async def save(self, style: MoodIslandStyle) -> MoodIslandStyle:
        await self.db.commit()
        await self.db.refresh(style)
        return style
