import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.teacher_alert import TeacherAlertInstance
from app.models.student import Student


class TeacherAlertRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, alert_id: uuid.UUID) -> TeacherAlertInstance | None:
        return await self.db.get(TeacherAlertInstance, alert_id)

    async def get_by_key(self, alert_key: str) -> TeacherAlertInstance | None:
        result = await self.db.execute(
            select(TeacherAlertInstance).where(TeacherAlertInstance.alert_key == alert_key)
        )
        return result.scalar_one_or_none()

    async def upsert_pending(self, alert: TeacherAlertInstance) -> TeacherAlertInstance:
        existing = await self.get_by_key(alert.alert_key)
        if existing:
            if existing.status == "dismissed":
                return existing
            preserve_status = existing.status
            existing.alert_type = alert.alert_type
            existing.report_date = alert.report_date
            existing.date_end = alert.date_end
            existing.title = alert.title
            existing.summary = alert.summary
            existing.payload = alert.payload
            existing.priority = alert.priority
            existing.growth_status = alert.growth_status
            existing.focus_tags = alert.focus_tags
            existing.focus_directions = alert.focus_directions
            existing.trend = alert.trend
            existing.risk_level = alert.risk_level
            existing.risk_reminder = alert.risk_reminder
            existing.ai_summary = alert.ai_summary
            existing.status = preserve_status
            await self.db.commit()
            await self.db.refresh(existing)
            return existing
        self.db.add(alert)
        await self.db.commit()
        await self.db.refresh(alert)
        return alert

    async def list_for_date(
        self,
        date_end: date,
        *,
        statuses: list[str] | None = None,
    ) -> list[TeacherAlertInstance]:
        return await self.list_for_range(date_end, date_end, statuses=statuses)

    async def list_for_range(
        self,
        date_from: date,
        date_to: date,
        *,
        class_name: str | None = None,
        statuses: list[str] | None = None,
    ) -> list[TeacherAlertInstance]:
        stmt = select(TeacherAlertInstance).where(
            TeacherAlertInstance.date_end >= date_from,
            TeacherAlertInstance.date_end <= date_to,
        )
        if class_name:
            stmt = stmt.join(Student, TeacherAlertInstance.student_id == Student.id).where(
                Student.class_name == class_name
            )
        if statuses:
            stmt = stmt.where(TeacherAlertInstance.status.in_(statuses))
        stmt = stmt.order_by(
            TeacherAlertInstance.priority.desc(),
            TeacherAlertInstance.date_end.desc(),
            TeacherAlertInstance.created_at.desc(),
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def save(self, alert: TeacherAlertInstance) -> TeacherAlertInstance:
        await self.db.commit()
        await self.db.refresh(alert)
        return alert
