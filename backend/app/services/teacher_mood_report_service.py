from __future__ import annotations

import uuid
from datetime import date

from app.models.daily_mood_report import DailyMoodReport
from app.repositories.daily_mood_report_repository import DailyMoodReportRepository
from app.repositories.profile_repository import DailyMomentRepository, ProfileRepository
from app.repositories.student_repository import StudentRepository
from app.services.growth_insight_service import GrowthInsightService

CONCERN_LABEL = {
    "normal": "关注等级：平稳",
    "watch": "关注等级：需关注",
    "urgent": "关注等级：优先跟进",
}


class TeacherMoodReportService:
    def __init__(
        self,
        report_repo: DailyMoodReportRepository,
        student_repo: StudentRepository,
        moment_repo: DailyMomentRepository | None = None,
        profile_repo: ProfileRepository | None = None,
    ):
        self.report_repo = report_repo
        self.student_repo = student_repo
        self.moment_repo = moment_repo
        self.profile_repo = profile_repo
        self.insight_svc = GrowthInsightService()

    async def list_today(self, report_date: date | None = None, *, class_name: str) -> list[dict]:
        from app.services.daily_mood_report_service import CONCERN_ORDER

        day = report_date or date.today()
        reports = await self.report_repo.list_by_date(day, class_name=class_name)
        reports.sort(key=lambda r: CONCERN_ORDER.get(r.concern_level, 0), reverse=True)
        return [await self._to_teacher_read(r) for r in reports]

    async def get_by_student(
        self, student_id: uuid.UUID, report_date: date | None = None, *, class_name: str
    ) -> dict | None:
        day = report_date or date.today()
        report = await self.report_repo.get_by_student_and_date(student_id, day, class_name=class_name)
        if not report:
            return None
        return await self._to_teacher_read(report)

    async def _to_teacher_read(self, report: DailyMoodReport) -> dict:
        student_name = None
        class_name = None
        if report.student_id:
            student = await self.student_repo.get_by_id(report.student_id)
            if student:
                student_name = student.name
                class_name = student.class_name
        return {
            "user_id": report.user_id,
            "student_id": report.student_id,
            "student_name": student_name,
            "class_name": class_name,
            "report_date": report.report_date.isoformat(),
            "mood_counts": report.mood_counts,
            "teacher_radar_scores": report.teacher_radar_scores,
            "category_breakdown": report.category_breakdown,
            "moment_count": report.moment_count,
            "concern_level": report.concern_level,
            "concern_label": CONCERN_LABEL.get(report.concern_level, "状态平稳"),
            "risk_flags": report.risk_flags,
            "attention_highlights": report.attention_highlights,
            "fuzzy_analysis": report.fuzzy_analysis,
            "uploaded_at": report.updated_at,
            "risk_exposures": await self._risk_exposures(report),
        }

    async def _risk_exposures(self, report: DailyMoodReport) -> list[dict]:
        if not self.moment_repo or not self.profile_repo or not report.student_id:
            return []
        profile = await self.profile_repo.get_by_student_id(report.student_id)
        if not profile:
            return []
        moments = await self.moment_repo.list_by_user_and_date(profile.user_id, report.report_date)
        dismissed = self.insight_svc.dismissed_ids(report)
        items = []
        for m in moments:
            if not self.insight_svc.moment_needs_risk_attention(m, report, dismissed):
                continue
            items.append(
                {
                    "moment_id": m.id,
                    "date": report.report_date.isoformat(),
                    "emotion_tag": m.emotion_tag,
                    "note": "",
                    "can_dismiss": True,
                }
            )
        return items
