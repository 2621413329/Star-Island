import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user_growth_state import UserGrowthState


class UserGrowthStateRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_user_id(self, user_id: uuid.UUID) -> UserGrowthState | None:
        result = await self.db.execute(
            select(UserGrowthState).where(UserGrowthState.user_id == user_id)
        )
        return result.scalar_one_or_none()

    async def upsert(self, state: UserGrowthState) -> UserGrowthState:
        existing = await self.get_by_user_id(state.user_id)
        if existing:
            existing.growth_value = state.growth_value
            existing.level = state.level
            existing.level_title = state.level_title
            existing.streak_days = state.streak_days
            existing.max_streak_days = state.max_streak_days
            existing.next_level = state.next_level
            existing.next_level_title = state.next_level_title
            existing.xp_into_level = state.xp_into_level
            existing.xp_for_next_level = state.xp_for_next_level
            existing.island_stage = state.island_stage
            existing.unlock_label = state.unlock_label
            existing.today_mood = state.today_mood
            existing.today_weather_label = state.today_weather_label
            existing.emotion_fragment_count = state.emotion_fragment_count
            existing.emotion_totals = state.emotion_totals
            if existing.island_seed == 0 and state.island_seed != 0:
                existing.island_seed = state.island_seed
            await self.db.commit()
            await self.db.refresh(existing)
            return existing
        self.db.add(state)
        await self.db.commit()
        await self.db.refresh(state)
        return state
