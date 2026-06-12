"""教师复核：误报危险信号时撤销备注暴露并刷新洞察。"""

from __future__ import annotations

import uuid
from datetime import date

from app.exceptions.business import BusinessException
from app.repositories.daily_mood_report_repository import DailyMoodReportRepository
from app.repositories.profile_repository import DailyMomentRepository, ProfileRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.teacher_alert_repository import TeacherAlertRepository
from app.services.daily_mood_report_service import DailyMoodReportService
from app.services.growth_insight_service import GrowthInsightService
from app.services.teacher_alert_service import TeacherAlertService


class GrowthRiskReviewService:
    def __init__(
        self,
        report_repo: DailyMoodReportRepository,
        moment_repo: DailyMomentRepository,
        profile_repo: ProfileRepository,
        student_repo: StudentRepository,
        alert_repo: TeacherAlertRepository,
    ):
        self.report_repo = report_repo
        self.moment_repo = moment_repo
        self.profile_repo = profile_repo
        self.student_repo = student_repo
        self.alert_repo = alert_repo
        self.insight_svc = GrowthInsightService()
        self.mood_svc = DailyMoodReportService()

    async def dismiss_critical_moment(
        self,
        student_id: uuid.UUID,
        moment_id: uuid.UUID,
        *,
        class_name: str,
    ) -> dict:
        student = await self.student_repo.get_by_id(student_id)
        if not student or student.class_name != class_name:
            raise BusinessException("学生不存在或不在本班", 404)

        profile = await self.profile_repo.get_by_student_id(student_id)
        if not profile:
            raise BusinessException("学生档案不存在", 404)

        moment = await self.moment_repo.get_by_id_and_user(moment_id, profile.user_id)
        if not moment:
            raise BusinessException("成长记录不存在", 404)

        report = await self.report_repo.get_by_student_and_date(
            student_id, moment.moment_date, class_name=class_name
        )
        if not report:
            raise BusinessException("未找到对应日期的心情报告", 404)

        if not self.insight_svc.moment_needs_risk_attention(moment, report):
            raise BusinessException("该记录未标记为危险信号，无需复核", 400)

        if str(moment_id) in self.insight_svc.dismissed_ids(report):
            raise BusinessException("该危险标记已撤销", 400)

        dismissed = list(report.dismissed_risk_moment_ids or [])
        mid = str(moment_id)
        if mid not in dismissed:
            dismissed.append(mid)
        report.dismissed_risk_moment_ids = dismissed

        day_moments = await self.moment_repo.list_by_user_and_date(profile.user_id, moment.moment_date)
        dismissed_set = self.insight_svc.dismissed_ids(report)
        flags, level = self.mood_svc.detect_risk_signals(day_moments, dismissed_ids=dismissed_set)
        report.risk_flags = flags
        report.concern_level = level
        report.growth_insight = self.insight_svc.resolve_for_report(report, day_moments)
        growth_insight = dict(report.growth_insight or {})
        ai_flagged = [
            x
            for x in (growth_insight.get("ai_flagged_moment_ids") or [])
            if str(x) != mid
        ]
        if ai_flagged:
            growth_insight["ai_flagged_moment_ids"] = ai_flagged
        else:
            growth_insight.pop("ai_flagged_moment_ids", None)
        report.growth_insight = growth_insight
        await self.report_repo.save(report)

        alert_svc = TeacherAlertService(
            self.alert_repo,
            self.report_repo,
            self.student_repo,
            self.moment_repo,
            self.profile_repo,
        )
        await alert_svc._sync_daily_alerts(moment.moment_date, class_name=class_name)

        return {
            "student_id": student_id,
            "moment_id": moment_id,
            "report_date": moment.moment_date.isoformat(),
            "risk_level": report.growth_insight.get("risk_level", "none"),
            "risk_reminder": report.growth_insight.get("risk_reminder"),
        }
