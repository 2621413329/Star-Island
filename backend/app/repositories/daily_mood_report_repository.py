import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.daily_mood_report import DailyMoodReport


class DailyMoodReportRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def upsert(self, report: DailyMoodReport) -> DailyMoodReport:
        existing = await self.get_by_user_and_date(report.user_id, report.report_date)
        if existing:
            for field in (
                "category_filter",
                "moment_count",
                "mood_counts",
                "radar_scores",
                "category_breakdown",
                "concern_level",
                "risk_flags",
                "attention_highlights",
                "insight_summary",
                "warm_suggestion",
                "ai_generated",
                "growth_insight",
                "growth_observation",
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
