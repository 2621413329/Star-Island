import uuid
from datetime import datetime

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.island_polaroid import IslandPolaroid


class IslandPolaroidRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_for_island(self, user_id: uuid.UUID, island_id: uuid.UUID) -> list[IslandPolaroid]:
        result = await self.db.execute(
            select(IslandPolaroid)
            .where(
                IslandPolaroid.user_id == user_id,
                IslandPolaroid.island_id == island_id,
            )
            .order_by(IslandPolaroid.level.desc())
        )
        return list(result.scalars().all())

    async def get_by_id(self, polaroid_id: uuid.UUID, user_id: uuid.UUID) -> IslandPolaroid | None:
        result = await self.db.execute(
            select(IslandPolaroid).where(
                IslandPolaroid.id == polaroid_id,
                IslandPolaroid.user_id == user_id,
            )
        )
        return result.scalar_one_or_none()

    async def get_level(
        self,
        user_id: uuid.UUID,
        island_id: uuid.UUID,
        level: int,
    ) -> IslandPolaroid | None:
        result = await self.db.execute(
            select(IslandPolaroid).where(
                IslandPolaroid.user_id == user_id,
                IslandPolaroid.island_id == island_id,
                IslandPolaroid.level == level,
            )
        )
        return result.scalar_one_or_none()

    async def save(self, row: IslandPolaroid) -> IslandPolaroid:
        self.db.add(row)
        await self.db.commit()
        await self.db.refresh(row)
        return row

    async def delete_levels_above(self, user_id: uuid.UUID, island_id: uuid.UUID, level: int) -> None:
        await self.db.execute(
            delete(IslandPolaroid).where(
                IslandPolaroid.user_id == user_id,
                IslandPolaroid.island_id == island_id,
                IslandPolaroid.level > level,
            )
        )
        await self.db.commit()
