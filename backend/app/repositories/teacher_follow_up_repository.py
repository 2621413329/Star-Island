import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.teacher_follow_up import TeacherFollowUp


class TeacherFollowUpRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, record: TeacherFollowUp) -> TeacherFollowUp:
        self.db.add(record)
        await self.db.commit()
        await self.db.refresh(record)
        return record

    async def list_by_student(self, student_id: uuid.UUID, *, limit: int = 20) -> list[TeacherFollowUp]:
        result = await self.db.execute(
            select(TeacherFollowUp)
            .where(TeacherFollowUp.student_id == student_id)
            .order_by(TeacherFollowUp.created_at.desc())
            .limit(limit)
        )
        return list(result.scalars().all())
