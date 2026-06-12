"""教师端：危险信号（按瞬间）列表与详情。"""

from __future__ import annotations

import uuid
from datetime import date

from sqlalchemy import select

from app.exceptions.business import BusinessException
from app.models.profile import DailyMoment
from app.models.student import Student
from app.repositories.daily_mood_report_repository import DailyMoodReportRepository
from app.repositories.profile_repository import DailyMomentRepository, ProfileRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.teacher_risk_moment_follow_repository import TeacherRiskMomentFollowRepository
from app.services.companion_display_service import format_teacher_companion_scene
from app.services.growth_insight_service import GrowthInsightService
from app.services.moment_story_service import format_moment_story_detail, moment_category_label


class TeacherCriticalRiskService:
    def __init__(
        self,
        moment_repo: DailyMomentRepository,
        report_repo: DailyMoodReportRepository,
        profile_repo: ProfileRepository,
        student_repo: StudentRepository,
        follow_repo: TeacherRiskMomentFollowRepository,
        db,
    ):
        self.moment_repo = moment_repo
        self.report_repo = report_repo
        self.profile_repo = profile_repo
        self.student_repo = student_repo
        self.follow_repo = follow_repo
        self.db = db
        self.insight_svc = GrowthInsightService()

    async def list_signals(
        self,
        *,
        class_name: str,
        date_from: date,
        date_to: date,
        include_followed: bool = True,
    ) -> list[dict]:
        if date_from > date_to:
            date_from, date_to = date_to, date_from
        stmt = (
            select(DailyMoment, Student)
            .join(Student, DailyMoment.student_id == Student.id)
            .where(
                Student.class_name == class_name,
                DailyMoment.moment_date >= date_from,
                DailyMoment.moment_date <= date_to,
            )
            .order_by(DailyMoment.moment_date.desc(), DailyMoment.created_at.desc())
        )
        result = await self.db.execute(stmt)
        rows = result.all()
        critical_rows: list[tuple[DailyMoment, Student]] = []
        report_cache: dict[tuple[uuid.UUID, date], object] = {}
        for moment, student in rows:
            if not moment.student_id:
                continue
            cache_key = (moment.student_id, moment.moment_date)
            if cache_key not in report_cache:
                report_cache[cache_key] = await self.report_repo.get_by_student_and_date(
                    moment.student_id, moment.moment_date, class_name=class_name
                )
            report = report_cache[cache_key]
            dismissed = self.insight_svc.dismissed_ids(report)
            if not self.insight_svc.moment_needs_risk_attention(moment, report, dismissed):
                continue
            critical_rows.append((moment, student))

        follow_map = await self.follow_repo.map_by_moment_ids([m.id for m, _ in critical_rows])
        items: list[dict] = []
        for moment, student in critical_rows:
            follow = follow_map.get(moment.id)
            follow_status = "pending"
            if follow and follow.status == "followed":
                follow_status = "followed"
            if not include_followed and follow_status == "followed":
                continue
            story = format_moment_story_detail(moment)
            items.append(
                {
                    "moment_id": moment.id,
                    "student_id": moment.student_id,
                    "student_name": student.name,
                    "class_name": student.class_name,
                    "report_date": moment.moment_date.isoformat(),
                    "category_label": moment_category_label(moment),
                    "story_detail": story,
                    "note_preview": "",
                    "emotion_tag": moment.emotion_tag,
                    "risk_reminder": "检测到疑似自伤表达，建议联系心理教师",
                    "follow_up_status": follow_status,
                    "follow_note": follow.note if follow else None,
                    "followed_at": follow.followed_at if follow else None,
                }
            )
        return items

    async def count_pending(
        self, *, class_name: str, date_from: date, date_to: date
    ) -> int:
        items = await self.list_signals(
            class_name=class_name,
            date_from=date_from,
            date_to=date_to,
            include_followed=False,
        )
        return len(items)

    def _follow_fields(self, moment_id: uuid.UUID, follow_map: dict) -> dict:
        follow = follow_map.get(moment_id)
        status = "pending"
        if follow and follow.status == "followed":
            status = "followed"
        return {
            "follow_up_status": status,
            "follow_note": follow.note if follow else None,
            "followed_at": follow.followed_at if follow else None,
        }

    async def get_signal_detail(
        self, moment_id: uuid.UUID, *, class_name: str
    ) -> dict:
        stmt = (
            select(DailyMoment, Student)
            .join(Student, DailyMoment.student_id == Student.id)
            .where(DailyMoment.id == moment_id, Student.class_name == class_name)
        )
        result = await self.db.execute(stmt)
        row = result.first()
        if not row:
            raise BusinessException("危险信号记录不存在或不在本班", 404)
        moment, student = row
        report = await self.report_repo.get_by_student_and_date(
            moment.student_id, moment.moment_date, class_name=class_name
        )
        dismissed = self.insight_svc.dismissed_ids(report)
        if not self.insight_svc.moment_needs_risk_attention(moment, report, dismissed):
            raise BusinessException("该记录已撤销或不是危险信号", 404)
        tags = moment.event_tags or []
        detail_tags = [t for t in tags[1:] if t]
        follow = await self.follow_repo.get_by_moment(moment_id)
        follow_map = {moment_id: follow} if follow else {}
        vp = moment.visual_payload if isinstance(moment.visual_payload, dict) else {}
        return {
            "moment_id": moment.id,
            "student_id": moment.student_id,
            "student_name": student.name,
            "class_name": student.class_name,
            "report_date": moment.moment_date.isoformat(),
            "emotion_tag": moment.emotion_tag,
            "category_label": moment_category_label(moment),
            "detail_tags": detail_tags,
            "story_detail": format_moment_story_detail(moment),
            "note": (moment.note or "").strip(),
            "companion_scene": moment.companion_scene,
            "companion_scene_label": format_teacher_companion_scene(
                companion_scene=moment.companion_scene,
                emotion_tag=moment.emotion_tag,
                category_label=moment_category_label(moment),
                visual_payload=vp,
                event_tags=tags,
            ),
            "created_at": moment.created_at,
            "can_dismiss": True,
            "risk_reminder": "检测到疑似自伤表达，建议联系心理教师",
            **self._follow_fields(moment_id, follow_map),
        }

    async def mark_followed(
        self,
        moment_id: uuid.UUID,
        *,
        class_name: str,
        teacher_id: uuid.UUID,
        note: str | None,
    ) -> dict:
        detail = await self.get_signal_detail(moment_id, class_name=class_name)
        record = await self.follow_repo.mark_followed(
            moment_id=moment_id,
            student_id=detail["student_id"],
            teacher_id=teacher_id,
            note=(note or "").strip() or None,
        )
        return {
            "moment_id": moment_id,
            "follow_up_status": record.status,
            "follow_note": record.note,
            "followed_at": record.followed_at,
        }

    async def reactivate(
        self, moment_id: uuid.UUID, *, class_name: str
    ) -> dict:
        await self.get_signal_detail(moment_id, class_name=class_name)
        record = await self.follow_repo.reactivate(moment_id)
        if not record:
            return {
                "moment_id": moment_id,
                "follow_up_status": "pending",
                "follow_note": None,
                "followed_at": None,
            }
        return {
            "moment_id": moment_id,
            "follow_up_status": record.status,
            "follow_note": record.note,
            "followed_at": record.followed_at,
        }
