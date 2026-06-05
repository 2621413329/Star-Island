import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.daily_mood_report import DailyMoodReport
from app.models.student import Student


class DailyMoodReportRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def upsert(self, report: DailyMoodReport) -> DailyMoodReport:
        existing = await self.get_by_user_and_date(report.user_id, report.report_date)
        if existing:
            for field in (
                "student_id",
                "category_filter",
                "moment_count",
                "mood_counts",
                "radar_scores",
                "teacher_radar_scores",
                "category_breakdown",
                "concern_level",
                "risk_flags",
                "attention_highlights",
                "fuzzy_analysis",
                "student_insight",
                "warm_suggestion",
                "ai_generated",
                "growth_insight",
                "dismissed_risk_moment_ids",
            ):
                setattr(existing, field, getattr(report, field))
            await self.db.commit()
            await self.db.refresh(existing)
            return existing
        self.db.add(report)
        await self.db.commit()
        await self.db.refresh(report)
        return report

    async def get_by_user_and_date(self, user_id: uuid.UUID, report_date: date) -> DailyMoodReport | None:
        result = await self.db.execute(
            select(DailyMoodReport).where(
                DailyMoodReport.user_id == user_id,
                DailyMoodReport.report_date == report_date,
            )
        )
        return result.scalar_one_or_none()

    async def list_by_date(self, report_date: date, *, class_name: str | None = None) -> list[DailyMoodReport]:
        stmt = select(DailyMoodReport).where(DailyMoodReport.report_date == report_date)
        if class_name:
            stmt = stmt.join(Student, DailyMoodReport.student_id == Student.id).where(
                Student.class_name == class_name
            )
        stmt = stmt.order_by(DailyMoodReport.updated_at.desc())
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_student_and_date(
        self, student_id: uuid.UUID, report_date: date, *, class_name: str | None = None
    ) -> DailyMoodReport | None:
        stmt = select(DailyMoodReport).where(
            DailyMoodReport.student_id == student_id,
            DailyMoodReport.report_date == report_date,
        )
        if class_name:
            stmt = stmt.join(Student, DailyMoodReport.student_id == Student.id).where(
                Student.class_name == class_name
            )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_student_since(
        self, student_id: uuid.UUID, since: date, *, class_name: str | None = None
    ) -> list[DailyMoodReport]:
        stmt = select(DailyMoodReport).where(
            DailyMoodReport.student_id == student_id,
            DailyMoodReport.report_date >= since,
        )
        if class_name:
            stmt = stmt.join(Student, DailyMoodReport.student_id == Student.id).where(
                Student.class_name == class_name
            )
        stmt = stmt.order_by(DailyMoodReport.report_date.desc())
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def list_by_user_since(self, user_id: uuid.UUID, since: date) -> list[DailyMoodReport]:
        result = await self.db.execute(
            select(DailyMoodReport)
            .where(
                DailyMoodReport.user_id == user_id,
                DailyMoodReport.report_date >= since,
            )
            .order_by(DailyMoodReport.report_date.desc())
        )
        return list(result.scalars().all())

    async def save(self, report: DailyMoodReport) -> DailyMoodReport:
        await self.db.commit()
        await self.db.refresh(report)
        return report
