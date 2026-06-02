import uuid
from datetime import datetime

from sqlalchemy import Select, and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.story import Story, StoryGenerationRun


class StoryRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, story_id: uuid.UUID) -> Story | None:
        return await self.db.get(Story, story_id)

    async def list_by_student(self, student_id: uuid.UUID, start_at: datetime, end_at: datetime) -> list[Story]:
        result = await self.db.execute(
            select(Story)
            .where(and_(Story.student_id == student_id, Story.created_at >= start_at, Story.created_at < end_at))
            .order_by(Story.created_at.desc())
        )
        return list(result.scalars().all())

    async def list(self, page: int, page_size: int, student_id: uuid.UUID | None = None) -> tuple[int, list[Story]]:
        stmt: Select[tuple[Story]] = select(Story).order_by(Story.created_at.desc())
        count_stmt = select(func.count()).select_from(Story)
        if student_id:
            stmt = stmt.where(Story.student_id == student_id)
            count_stmt = count_stmt.where(Story.student_id == student_id)
        total = await self.db.scalar(count_stmt) or 0
        result = await self.db.execute(stmt.offset((page - 1) * page_size).limit(page_size))
        return total, list(result.scalars().all())

    async def create_with_run(self, story: Story, run: StoryGenerationRun) -> Story:
        self.db.add(story)
        await self.db.flush()
        run.story_id = story.id
        self.db.add(run)
        await self.db.commit()
        await self.db.refresh(story)
        return story
