import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.teacher_risk_moment_follow import TeacherRiskMomentFollow


class TeacherRiskMomentFollowRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_moment(self, moment_id: uuid.UUID) -> TeacherRiskMomentFollow | None:
        result = await self.db.execute(
            select(TeacherRiskMomentFollow).where(TeacherRiskMomentFollow.moment_id == moment_id)
        )
        return result.scalar_one_or_none()

    async def map_by_moment_ids(
        self, moment_ids: list[uuid.UUID]
    ) -> dict[uuid.UUID, TeacherRiskMomentFollow]:
        if not moment_ids:
            return {}
        result = await self.db.execute(
            select(TeacherRiskMomentFollow).where(TeacherRiskMomentFollow.moment_id.in_(moment_ids))
        )
        rows = result.scalars().all()
        return {r.moment_id: r for r in rows}

    async def mark_followed(
        self,
        *,
        moment_id: uuid.UUID,
        student_id: uuid.UUID,
        teacher_id: uuid.UUID,
        note: str | None,
    ) -> TeacherRiskMomentFollow:
        now = datetime.now(timezone.utc)
        existing = await self.get_by_moment(moment_id)
        if existing:
            existing.note = note
            existing.status = "followed"
            existing.followed_at = now
            existing.teacher_id = teacher_id
            await self.db.commit()
            await self.db.refresh(existing)
            return existing
        record = TeacherRiskMomentFollow(
            moment_id=moment_id,
            student_id=student_id,
            teacher_id=teacher_id,
            note=note,
            status="followed",
            followed_at=now,
        )
        self.db.add(record)
        await self.db.commit()
        await self.db.refresh(record)
        return record

    async def reactivate(self, moment_id: uuid.UUID) -> TeacherRiskMomentFollow | None:
        existing = await self.get_by_moment(moment_id)
        if not existing:
            return None
        existing.status = "pending"
        existing.followed_at = None
        await self.db.commit()
        await self.db.refresh(existing)
        return existing
