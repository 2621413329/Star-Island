import uuid
from datetime import date

from sqlalchemy import delete, func, or_, select
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

    @staticmethod
    def _category_filter_clause(category_filter: str | None):
        if not category_filter:
            return None
        return or_(
            DailyMoment.primary_tag == category_filter,
            func.jsonb_array_element_text(DailyMoment.event_tags, 0) == category_filter,
        )

    async def count_by_user_period(
        self,
        user_id: uuid.UUID,
        *,
        since: date,
        until: date,
        category_filter: str | None = None,
    ) -> int:
        conditions = [
            DailyMoment.user_id == user_id,
            DailyMoment.moment_date >= since,
            DailyMoment.moment_date <= until,
        ]
        category_clause = self._category_filter_clause(category_filter)
        if category_clause is not None:
            conditions.append(category_clause)
        result = await self.db.execute(
            select(func.count()).select_from(DailyMoment).where(*conditions)
        )
        return int(result.scalar_one() or 0)

    async def list_by_user_period_paginated(
        self,
        user_id: uuid.UUID,
        *,
        since: date,
        until: date,
        category_filter: str | None = None,
        page: int = 1,
        page_size: int = 10,
    ) -> tuple[int, list[DailyMoment]]:
        conditions = [
            DailyMoment.user_id == user_id,
            DailyMoment.moment_date >= since,
            DailyMoment.moment_date <= until,
        ]
        category_clause = self._category_filter_clause(category_filter)
        if category_clause is not None:
            conditions.append(category_clause)
        total = await self.count_by_user_period(
            user_id,
            since=since,
            until=until,
            category_filter=category_filter,
        )
        safe_page = max(1, page)
        safe_size = max(1, min(page_size, 50))
        result = await self.db.execute(
            select(DailyMoment)
            .where(*conditions)
            .order_by(DailyMoment.moment_date.desc(), DailyMoment.created_at.desc())
            .offset((safe_page - 1) * safe_size)
            .limit(safe_size)
        )
        return total, list(result.scalars().all())
