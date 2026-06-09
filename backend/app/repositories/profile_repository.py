import uuid
from datetime import date

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.profile import DailyMoment, UserProfile


class ProfileRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_user_id(self, user_id: uuid.UUID) -> UserProfile | None:
        result = await self.db.execute(select(UserProfile).where(UserProfile.user_id == user_id))
        return result.scalar_one_or_none()

    async def get_by_student_id(self, student_id: uuid.UUID) -> UserProfile | None:
        result = await self.db.execute(
            select(UserProfile).where(UserProfile.student_id == student_id)
        )
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

    async def save(self, moment: DailyMoment) -> DailyMoment:
        await self.db.commit()
        await self.db.refresh(moment)
        return moment

    async def create(self, moment: DailyMoment) -> DailyMoment:
        self.db.add(moment)
        await self.db.commit()
        await self.db.refresh(moment)
        return moment

    async def get_by_id_and_user(self, moment_id: uuid.UUID, user_id: uuid.UUID) -> DailyMoment | None:
        result = await self.db.execute(
            select(DailyMoment).where(DailyMoment.id == moment_id, DailyMoment.user_id == user_id)
        )
        return result.scalar_one_or_none()

    async def get_by_client_event_id(
        self, user_id: uuid.UUID, client_event_id: str
    ) -> DailyMoment | None:
        result = await self.db.execute(
            select(DailyMoment).where(
                DailyMoment.user_id == user_id,
                DailyMoment.client_event_id == client_event_id,
            )
        )
        return result.scalar_one_or_none()

    async def delete_by_id_and_user(self, moment_id: uuid.UUID, user_id: uuid.UUID) -> bool:
        result = await self.db.execute(
            delete(DailyMoment).where(
                DailyMoment.id == moment_id,
                DailyMoment.user_id == user_id,
            ).returning(DailyMoment.id)
        )
        deleted_id = result.scalar_one_or_none()
        await self.db.commit()
        return deleted_id is not None

    async def delete(self, moment: DailyMoment) -> None:
        await self.db.delete(moment)
        await self.db.commit()

    async def list_by_user_and_date(self, user_id: uuid.UUID, moment_date: date) -> list[DailyMoment]:
        result = await self.db.execute(
            select(DailyMoment)
            .where(DailyMoment.user_id == user_id, DailyMoment.moment_date == moment_date)
            .order_by(DailyMoment.created_at.desc())
        )
        return list(result.scalars().all())

    async def list_by_user(self, user_id: uuid.UUID) -> list[DailyMoment]:
        result = await self.db.execute(
            select(DailyMoment)
            .where(DailyMoment.user_id == user_id)
            .order_by(DailyMoment.moment_date.desc(), DailyMoment.created_at.desc())
        )
        return list(result.scalars().all())

    async def list_by_user_since(self, user_id: uuid.UUID, since: date) -> list[DailyMoment]:
        result = await self.db.execute(
            select(DailyMoment)
            .where(DailyMoment.user_id == user_id, DailyMoment.moment_date >= since)
            .order_by(DailyMoment.moment_date.desc(), DailyMoment.created_at.desc())
        )
        return list(result.scalars().all())

    async def list_distinct_dates_since(self, user_id: uuid.UUID, since: date) -> list[date]:
        result = await self.db.execute(
            select(DailyMoment.moment_date)
            .where(DailyMoment.user_id == user_id, DailyMoment.moment_date >= since)
            .distinct()
            .order_by(DailyMoment.moment_date.desc())
        )
        return list(result.scalars().all())
