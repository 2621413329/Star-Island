import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.profile import DailyMoment, UserProfile


class ProfileRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_user_id(self, user_id: uuid.UUID) -> UserProfile | None:
        result = await self.db.execute(select(UserProfile).where(UserProfile.user_id == user_id))
        return result.scalar_one_or_none()

    async def create(self, profile: UserProfile) -> UserProfile:
        self.db.add(profile)
        await self.db.commit()
        await self.db.refresh(profile)
        return profile

    async def save(self, profile: UserProfile) -> UserProfile:
        await self.db.commit()
        await self.db.refresh(profile)
        return profile


class DailyMomentRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, moment: DailyMoment) -> DailyMoment:
        self.db.add(moment)
        await self.db.commit()
        await self.db.refresh(moment)
        return moment

    async def list_by_user_and_date(self, user_id: uuid.UUID, moment_date: date) -> list[DailyMoment]:
        result = await self.db.execute(
            select(DailyMoment)
            .where(DailyMoment.user_id == user_id, DailyMoment.moment_date == moment_date)
            .order_by(DailyMoment.created_at.desc())
        )
        return list(result.scalars().all())
