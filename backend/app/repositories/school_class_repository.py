import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.school_class import SchoolClass


class SchoolClassRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, class_id: uuid.UUID) -> SchoolClass | None:
        return await self.db.get(SchoolClass, class_id)

    async def get_by_name(self, name: str) -> SchoolClass | None:
        result = await self.db.execute(
            select(SchoolClass).where(SchoolClass.name == name.strip())
        )
        return result.scalar_one_or_none()

    async def list_active(self) -> list[SchoolClass]:
        result = await self.db.execute(
            select(SchoolClass)
            .where(SchoolClass.is_active.is_(True))
            .order_by(SchoolClass.name.asc())
        )
        return list(result.scalars().all())

    async def create(self, school_class: SchoolClass) -> SchoolClass:
        self.db.add(school_class)
        await self.db.commit()
        await self.db.refresh(school_class)
        return school_class
