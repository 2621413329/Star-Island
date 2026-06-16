import uuid
from datetime import date, datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user_building_unlock import UserBuildingUnlock


class UserBuildingUnlockRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_by_user_id(self, user_id: uuid.UUID) -> list[UserBuildingUnlock]:
        result = await self.db.execute(
            select(UserBuildingUnlock)
            .where(UserBuildingUnlock.user_id == user_id)
            .order_by(UserBuildingUnlock.unlocked_at.asc())
        )
        return list(result.scalars().all())

    async def get_unlocked_ids(self, user_id: uuid.UUID) -> set[str]:
        result = await self.db.execute(
            select(UserBuildingUnlock.building_id).where(UserBuildingUnlock.user_id == user_id)
        )
        return set(result.scalars().all())

    async def create_if_absent(
        self,
        *,
        user_id: uuid.UUID,
        building_id: str,
        unlock_level: int,
        unlocked_at: datetime,
    ) -> UserBuildingUnlock | None:
        existing = await self.db.execute(
            select(UserBuildingUnlock).where(
                UserBuildingUnlock.user_id == user_id,
                UserBuildingUnlock.building_id == building_id,
            )
        )
        if existing.scalar_one_or_none() is not None:
            return None
        row = UserBuildingUnlock(
            user_id=user_id,
            building_id=building_id,
            unlock_level=unlock_level,
            unlocked_at=unlocked_at,
        )
        self.db.add(row)
        await self.db.commit()
        await self.db.refresh(row)
        return row
