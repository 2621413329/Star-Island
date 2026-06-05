from __future__ import annotations

import uuid
from datetime import date, datetime, timedelta, timezone

from app.models.daily_mood_report import DailyMoodReport
from app.models.teacher_alert import TeacherAlertInstance
from app.repositories.daily_mood_report_repository import DailyMoodReportRepository
from app.repositories.profile_repository import DailyMomentRepository, ProfileRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.teacher_alert_repository import TeacherAlertRepository
from app.services.growth_insight_service import GrowthInsightService

ALERT_PRIORITY = {"priority": 30, "ongoing": 25, "streak": 15, "observing": 10}

GROWTH_TITLE = {
    "priority": "优先关注",
    "ongoing": "持续关注",
    "observing": "观察中",
}


class TeacherAlertService:
    def __init__(
        self,
        alert_repo: TeacherAlertRepository,
        report_repo: DailyMoodReportRepository,
        student_repo: StudentRepository,
        moment_repo: DailyMomentRepository | None = None,
        profile_repo: ProfileRepository | None = None,
    ):
        self.alert_repo = alert_repo
        self.report_repo = report_repo
        self.student_repo = student_repo
        self.moment_repo = moment_repo
        self.profile_repo = profile_repo
        self.insight_svc = GrowthInsightService()

    async def sync_and_list_range(
        self,
        date_from: date,
        date_to: date,
        *,
        class_name: str,
        include_acked: bool = False,
    ) -> list[dict]:
        if date_from > date_to:
            date_from, date_to = date_to, date_from
        current = date_from
        while current <= date_to:
            await self._sync_daily_alerts(current, class_name=class_name)
            await self._sync_streak_alerts(current, class_name=class_name)
            current += timedelta(days=1)
        statuses = ["pending", "acked"] if include_acked else ["pending"]
        alerts = await self.alert_repo.list_for_range(
            date_from, date_to, class_name=class_name, statuses=statuses
        )
        return [await self._to_read(a) for a in alerts]

    async def sync_and_list(
        self,
        anchor_date: date,
        *,
        class_name: str,
        include_acked: bool = False,
    ) -> list[dict]:
        return await self.sync_and_list_range(
            anchor_date, anchor_date, class_name=class_name, include_acked=include_acked
        )

    async def ack(self, alert_id: uuid.UUID, teacher_user_id: uuid.UUID, *, class_name: str) -> dict:
        alert = await self._get_alert_for_class(alert_id, class_name)
        if alert.status == "dismissed":
            from app.exceptions.business import BusinessException

            raise BusinessException("记录已移除", 410)
        alert.status = "acked"
        alert.acked_by = teacher_user_id
        alert.acked_at = datetime.now(timezone.utc)
        alert = await self.alert_repo.save(alert)
        return {"id": alert.id, "status": "followed", "acked_at": alert.acked_at}

    async def unack(self, alert_id: uuid.UUID, *, class_name: str) -> dict:
        alert = await self._get_alert_for_class(alert_id, class_name)
        if alert.status == "dismissed":
            from app.exceptions.business import BusinessException

            raise BusinessException("记录已移除", 410)
        if alert.status != "acked":
            from app.exceptions.business import BusinessException

            raise BusinessException("该条尚未标记关注", 400)
        alert.status = "pending"
        alert.acked_by = None
        alert.acked_at = None
        alert = await self.alert_repo.save(alert)
        return {"id": alert.id, "status": "pending", "acked_at": None}

    async def dismiss(self, alert_id: uuid.UUID, *, class_name: str) -> bool:
        alert = await self._get_alert_for_class(alert_id, class_name)
        alert.status = "dismissed"
        await self.alert_repo.save(alert)
        return True

    async def _get_alert_for_class(self, alert_id: uuid.UUID, class_name: str) -> TeacherAlertInstance:
        alert = await self.alert_repo.get_by_id(alert_id)
        if not alert:
            from app.exceptions.business import BusinessException

            raise BusinessException("成长关注记录不存在", 404)
        if not await self.student_repo.belongs_to_class(alert.student_id, class_name):
            from app.exceptions.business import BusinessException

            raise BusinessException("无权操作该记录", 403)
        return alert

    async def _sync_daily_alerts(self, report_date: date, *, class_name: str) -> None:
        reports = await self.report_repo.list_by_date(report_date, class_name=class_name)
        for report in reports:
            if not report.student_id:
                continue
            meta = await self._daily_growth_meta(report, report_date)
            if not meta:
                continue
            key = f"daily:{report.student_id}:{report_date.isoformat()}"
            await self._upsert_alert(key, report.student_id, report_date, report_date, "daily", meta)

    async def _sync_streak_alerts(self, end_date: date, *, class_name: str) -> None:
        student_ids = await self._student_ids_with_reports_on(end_date, class_name=class_name)
        d2, d1 = end_date - timedelta(days=2), end_date - timedelta(days=1)
        for student_id in student_ids:
            chain = [d2, d1, end_date]
            ok = True
            for d in chain:
                report = await self.report_repo.get_by_student_and_date(
                    student_id, d, class_name=class_name
                )
                if not report or report.concern_level not in ("watch", "urgent"):
                    ok = False
                    break
            if not ok:
                continue
            student = await self.student_repo.get_by_id(student_id)
            name = student.name if student else "学生"
            insight = {
                "status": "ongoing",
                "focus_tags": ["low_mood"],
                "focus_directions": ["情绪状态"],
                "trend": "down",
                "summary": f"近3日成长状态持续波动，建议温暖跟进（{d2.month}/{d2.day}–{end_date.month}/{end_date.day}）",
                "need_attention": True,
                "risk_level": "none",
                "risk_reminder": None,
            }
            meta = {
                "title": f"{name}·持续观察",
                "summary": insight["summary"],
                "priority": ALERT_PRIORITY["streak"],
                "insight": insight,
            }
            key = f"streak:{student_id}:{end_date.isoformat()}"
            await self._upsert_alert(key, student_id, None, end_date, "streak_low_mood", meta)

    async def _upsert_alert(
        self,
        key: str,
        student_id: uuid.UUID,
        report_date: date | None,
        date_end: date,
        alert_type: str,
        meta: dict,
    ) -> None:
        ins = meta["insight"]
        await self.alert_repo.upsert_pending(
            TeacherAlertInstance(
                alert_key=key,
                student_id=student_id,
                alert_type=alert_type,
                report_date=report_date,
                date_end=date_end,
                title=meta["title"],
                summary=meta["summary"],
                payload={"growth_insight": ins},
                priority=meta["priority"],
                growth_status=ins["status"],
                focus_tags=ins.get("focus_tags"),
                focus_directions=ins.get("focus_directions"),
                trend=ins.get("trend"),
                risk_level=ins.get("risk_level") or "none",
                risk_reminder=ins.get("risk_reminder"),
                ai_summary=ins.get("summary"),
                status="pending",
            )
        )

    async def _daily_growth_meta(self, report: DailyMoodReport, report_date: date) -> dict | None:
        moments = await self._moments_for_report(report, report_date)
        ins = self.insight_svc.resolve_for_report(report, moments)
        if not ins["need_attention"] and ins["status"] == "observing":
            return None
        status = ins["status"]
        return {
            "title": GROWTH_TITLE.get(status, "成长关注"),
            "summary": ins["summary"],
            "priority": ALERT_PRIORITY.get(status, 10),
            "insight": ins,
        }

    async def _moments_for_report(self, report: DailyMoodReport, report_date: date):
        if not self.moment_repo or not self.profile_repo or not report.student_id:
            return []
        profile = await self.profile_repo.get_by_student_id(report.student_id)
        if not profile:
            return []
        return await self.moment_repo.list_by_user_and_date(profile.user_id, report_date)

    async def _student_ids_with_reports_on(self, day: date, *, class_name: str) -> list[uuid.UUID]:
        reports = await self.report_repo.list_by_date(day, class_name=class_name)
        ids: list[uuid.UUID] = []
        for r in reports:
            if r.student_id and r.student_id not in ids:
                ids.append(r.student_id)
        return ids

    async def _to_read(self, alert: TeacherAlertInstance) -> dict:
        student = await self.student_repo.get_by_id(alert.student_id)
        growth_status = alert.growth_status or "ongoing"
        follow = "followed" if alert.status == "acked" else "pending"
        return {
            "id": alert.id,
            "alert_key": alert.alert_key,
            "student_id": alert.student_id,
            "student_name": student.name if student else None,
            "class_name": student.class_name if student else None,
            "alert_type": alert.alert_type,
            "report_date": alert.report_date.isoformat() if alert.report_date else None,
            "date_end": alert.date_end.isoformat(),
            "title": alert.title or GROWTH_TITLE.get(growth_status, "成长关注"),
            "growth_status": growth_status,
            "summary": alert.ai_summary or alert.summary,
            "focus_directions": alert.focus_directions or [],
            "focus_tags": alert.focus_tags or [],
            "trend": alert.trend or "stable",
            "need_attention": growth_status in ("ongoing", "priority"),
            "risk_level": alert.risk_level or "none",
            "risk_reminder": alert.risk_reminder,
            "follow_up_status": follow,
            "status": alert.status,
            "acked_at": alert.acked_at,
            "priority": alert.priority,
            "payload": alert.payload,
        }
