import uuid
from datetime import date, timedelta

from app.exceptions.business import BusinessException
from app.models.daily_mood_report import DailyMoodReport
from app.models.profile import DailyMoment, UserProfile
from app.models.student import Student
from app.models.user import User
from app.repositories.daily_mood_report_repository import DailyMoodReportRepository
from app.repositories.profile_repository import DailyMomentRepository, ProfileRepository
from app.repositories.student_repository import StudentRepository
from app.schemas.profile import (
    DailyMomentCreate,
    DailyMoodReportUpload,
    ProfileCompanionUpdate,
    ProfileGenderUpdate,
    ProfileMoodUpdate,
    ProfileRead,
)
from app.services.companion_action_ai_service import CompanionActionAIService
from app.services.companion_scene_service import CompanionSceneService
from app.core.school_classes import DEFAULT_CLASS_NAME
from app.services.daily_mood_report_service import DailyMoodReportService
from app.services.growth_points_service import GrowthPointsService
from app.schemas.growth import GrowthSummaryRead

STUDENT_CONCERN_LABEL = {
    "normal": "今天还不错",
    "watch": "可以慢慢来",
    "urgent": "小星会一直陪着你",
}


class ProfileService:
    def __init__(
        self,
        profile_repo: ProfileRepository,
        moment_repo: DailyMomentRepository,
        student_repo: StudentRepository,
        scene_service: CompanionSceneService | None = None,
        action_ai: CompanionActionAIService | None = None,
        mood_report_service: DailyMoodReportService | None = None,
        mood_report_repo: DailyMoodReportRepository | None = None,
    ):
        self.profile_repo = profile_repo
        self.moment_repo = moment_repo
        self.student_repo = student_repo
        self.scene_service = scene_service or CompanionSceneService()
        self.action_ai = action_ai or CompanionActionAIService()
        self.mood_report_service = mood_report_service or DailyMoodReportService()
        self.mood_report_repo = mood_report_repo
        self.growth_points = GrowthPointsService()

    async def ensure_profile(self, user: User) -> UserProfile:
        profile = await self.profile_repo.get_by_user_id(user.id)
        if profile:
            return profile
        student_no = f"U{user.id.hex[:10]}"
        student = await self.student_repo.get_by_student_no(student_no)
        if not student:
            student = Student(
                student_no=student_no,
                name=user.display_name,
                class_name=DEFAULT_CLASS_NAME,
                gender=None,
            )
            student = await self.student_repo.create(student)
        profile = UserProfile(user_id=user.id, student_id=student.id, onboarding_completed=False)
        return await self.profile_repo.create(profile)

    async def get_profile(self, user_id: uuid.UUID) -> UserProfile:
        profile = await self.profile_repo.get_by_user_id(user_id)
        if not profile:
            raise BusinessException("用户资料不存在", 404)
        return profile

    async def to_profile_read(self, profile: UserProfile, user: User | None = None) -> ProfileRead:
        class_name: str | None = None
        nickname: str | None = None
        if user is not None:
            nickname = user.display_name
        if profile.student_id:
            student = await self.student_repo.get_by_id(profile.student_id)
            if student:
                class_name = student.class_name
                if nickname is None:
                    nickname = student.name
        return ProfileRead(
            user_id=profile.user_id,
            student_id=profile.student_id,
            nickname=nickname,
            class_name=class_name,
            gender=profile.gender,
            companion_style=profile.companion_style,
            today_mood=profile.today_mood,
            onboarding_completed=profile.onboarding_completed,
            created_at=profile.created_at,
            updated_at=profile.updated_at,
        )

    async def update_gender(self, user_id: uuid.UUID, payload: ProfileGenderUpdate) -> UserProfile:
        profile = await self.get_profile(user_id)
        profile.gender = payload.gender
        if profile.student_id:
            student = await self.student_repo.get_by_id(profile.student_id)
            if student:
                student.gender = payload.gender
                await self.student_repo.update(student)
        # 新用户首次选性别：固定透明伙伴形象，默认心情，直接进入系统（不再选 Q 版/正常版）。
        if not profile.onboarding_completed:
            profile.companion_style = profile.companion_style or "chibi"
            profile.today_mood = profile.today_mood or "calm"
            profile.onboarding_completed = True
        return await self.profile_repo.save(profile)

    async def update_companion(self, user_id: uuid.UUID, payload: ProfileCompanionUpdate) -> UserProfile:
        profile = await self.get_profile(user_id)
        profile.companion_style = payload.companion_style
        return await self.profile_repo.save(profile)

    async def update_mood(self, user_id: uuid.UUID, payload: ProfileMoodUpdate) -> UserProfile:
        profile = await self.get_profile(user_id)
        profile.today_mood = payload.today_mood
        return await self.profile_repo.save(profile)

    async def complete_onboarding(self, user_id: uuid.UUID) -> UserProfile:
        profile = await self.get_profile(user_id)
        if not profile.gender or not profile.companion_style or not profile.today_mood:
            raise BusinessException("请先完成性别、伙伴形象与今日心情选择", 400)
        profile.onboarding_completed = True
        return await self.profile_repo.save(profile)

    async def create_moment(self, user_id: uuid.UUID, payload: DailyMomentCreate) -> DailyMoment:
        profile = await self.get_profile(user_id)
        if not profile.companion_style:
            raise BusinessException("请先选择成长伙伴形象", 400)

        scene = self.scene_service.build(
            companion_style=profile.companion_style,
            emotion_tag=payload.emotion_tag,
            event_tags=payload.event_tags,
            note=payload.note,
        )
        scene = await self.action_ai.enrich(
            companion_style=profile.companion_style,
            emotion_tag=payload.emotion_tag,
            event_tags=payload.event_tags,
            note=payload.note,
            base_scene=scene,
        )
        visual = scene.get("visual_payload") or {}
        if scene.get("action_type"):
            visual["action_type"] = scene["action_type"]
        if scene.get("waiting_lines"):
            visual["waiting_lines"] = scene["waiting_lines"]
        if scene.get("performance_ms"):
            visual["performance_ms"] = scene["performance_ms"]
        scene["visual_payload"] = visual
        moment = DailyMoment(
            user_id=user_id,
            student_id=profile.student_id,
            event_tags=payload.event_tags,
            emotion_tag=payload.emotion_tag,
            note=payload.note,
            companion_scene=scene["companion_scene"],
            companion_pose=scene["companion_pose"],
            visual_payload=scene["visual_payload"],
            moment_date=date.today(),
        )
        return await self.moment_repo.create(moment)

    def _ensure_moment_editable_today(self, moment: DailyMoment) -> None:
        if moment.moment_date != date.today():
            raise BusinessException("仅今日故事可以修改或删除", 403)

    async def update_moment(
        self, user_id: uuid.UUID, moment_id: uuid.UUID, payload: DailyMomentCreate
    ) -> DailyMoment:
        moment = await self.moment_repo.get_by_id_and_user(moment_id, user_id)
        if not moment:
            raise BusinessException("今日事件不存在或无权修改", 404)
        self._ensure_moment_editable_today(moment)
        profile = await self.get_profile(user_id)
        if not profile.companion_style:
            raise BusinessException("请先选择成长伙伴形象", 400)

        scene = self.scene_service.build(
            companion_style=profile.companion_style,
            emotion_tag=payload.emotion_tag,
            event_tags=payload.event_tags,
            note=payload.note,
        )
        scene = await self.action_ai.enrich(
            companion_style=profile.companion_style,
            emotion_tag=payload.emotion_tag,
            event_tags=payload.event_tags,
            note=payload.note,
            base_scene=scene,
        )
        visual = scene.get("visual_payload") or {}
        if scene.get("action_type"):
            visual["action_type"] = scene["action_type"]
        if scene.get("waiting_lines"):
            visual["waiting_lines"] = scene["waiting_lines"]
        if scene.get("performance_ms"):
            visual["performance_ms"] = scene["performance_ms"]
        scene["visual_payload"] = visual

        moment.event_tags = payload.event_tags
        moment.emotion_tag = payload.emotion_tag
        moment.note = payload.note
        moment.companion_scene = scene["companion_scene"]
        moment.companion_pose = scene["companion_pose"]
        moment.visual_payload = scene["visual_payload"]
        return await self.moment_repo.save(moment)

    async def list_today_moments(self, user_id: uuid.UUID) -> list[DailyMoment]:
        return await self.moment_repo.list_by_user_and_date(user_id, date.today())

    async def list_moments(self, user_id: uuid.UUID, *, days: int = 90) -> list[DailyMoment]:
        since = date.today() - timedelta(days=max(1, min(days, 365)))
        return await self.moment_repo.list_by_user_since(user_id, since)

    async def list_moments_for_date(self, user_id: uuid.UUID, moment_date: date) -> list[DailyMoment]:
        return await self.moment_repo.list_by_user_and_date(user_id, moment_date)

    async def list_moment_dates(self, user_id: uuid.UUID, *, days: int = 90) -> list[date]:
        since = date.today() - timedelta(days=max(1, min(days, 365)))
        return await self.moment_repo.list_distinct_dates_since(user_id, since)

    async def get_growth_summary(self, user_id: uuid.UUID, *, days: int = 365) -> GrowthSummaryRead:
        profile = await self.get_profile(user_id)
        since = date.today() - timedelta(days=max(30, min(days, 730)))
        moments = await self.moment_repo.list_by_user_since(user_id, since)
        reports: list = []
        if self.mood_report_repo:
            reports = await self.mood_report_repo.list_by_user_since(user_id, since)
        summary = self.growth_points.compute(
            moments=moments,
            reports=reports,
            today=date.today(),
            profile_today_mood=profile.today_mood,
        )
        return GrowthSummaryRead(
            growth_value=summary.growth_value,
            level=summary.level,
            level_title=summary.level_title,
            streak_days=summary.streak_days,
            max_streak_days=summary.max_streak_days,
            next_level=summary.next_level,
            next_level_title=summary.next_level_title,
            xp_into_level=summary.xp_into_level,
            xp_for_next_level=summary.xp_for_next_level,
            island_stage=summary.island_stage,
            unlock_label=summary.unlock_label,
            today_mood=summary.today_mood,
            today_weather_label=summary.today_weather_label,
        )

    async def get_mood_report_check_in(
        self, user_id: uuid.UUID, *, days: int = 365
    ) -> dict:
        today = date.today()
        if not self.mood_report_repo:
            return self._empty_mood_check_in(today)
        since = date.today() - timedelta(days=max(30, min(days, 730)))
        reports = await self.mood_report_repo.list_by_user_since(user_id, since)
        report_dates = sorted({r.report_date for r in reports})
        today_report = await self.mood_report_repo.get_by_user_and_date(user_id, today)
        today_moments = await self.moment_repo.list_by_user_and_date(user_id, today)
        current_count = len(today_moments)
        reported_count = today_report.moment_count if today_report else 0
        has_pending = current_count > reported_count
        all_synced = (
            today_report is not None and current_count > 0 and not has_pending
        )
        report_set = set(report_dates)
        return {
            "current_streak": self._mood_report_current_streak(report_dates, today),
            "max_streak": self._mood_report_max_streak(report_dates),
            "total_check_in_days": len(report_dates),
            "checked_in_today": today_report is not None,
            "today_moment_count": current_count,
            "reported_moment_count": reported_count,
            "has_pending_stories": has_pending,
            "all_synced_today": all_synced,
            "week_days": self._build_check_in_week_days(report_set, today),
        }

    @staticmethod
    def _build_check_in_week_days(report_dates: set[date], today: date) -> list[dict]:
        weekday_zh = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
        days_since_sunday = (today.weekday() + 1) % 7
        week_start = today - timedelta(days=days_since_sunday)
        week: list[dict] = []
        for i in range(7):
            d = week_start + timedelta(days=i)
            week.append(
                {
                    "date": d.isoformat(),
                    "weekday_label": weekday_zh[d.weekday()],
                    "checked_in": d in report_dates,
                    "is_today": d == today,
                    "is_future": d > today,
                }
            )
        return week

    @staticmethod
    def _empty_mood_check_in(today: date) -> dict:
        return {
            "current_streak": 0,
            "max_streak": 0,
            "total_check_in_days": 0,
            "checked_in_today": False,
            "today_moment_count": 0,
            "reported_moment_count": 0,
            "has_pending_stories": False,
            "all_synced_today": False,
            "week_days": ProfileService._build_check_in_week_days(set(), today),
        }

    @staticmethod
    def _mood_report_max_streak(days: list[date]) -> int:
        if not days:
            return 0
        unique = sorted(set(days))
        best = cur = 1
        for i in range(1, len(unique)):
            if unique[i] - unique[i - 1] == timedelta(days=1):
                cur += 1
                best = max(best, cur)
            else:
                cur = 1
        return best

    @staticmethod
    def _mood_report_current_streak(days: list[date], today: date) -> int:
        day_set = set(days)
        if not day_set:
            return 0
        cursor = today
        if cursor not in day_set:
            cursor = today - timedelta(days=1)
            if cursor not in day_set:
                return 0
        streak = 0
        while cursor in day_set:
            streak += 1
            cursor -= timedelta(days=1)
        return streak

    async def upload_daily_mood_report(
        self, user_id: uuid.UUID, payload: DailyMoodReportUpload
    ) -> dict:
        if not self.mood_report_repo:
            raise BusinessException("心情报告服务未就绪", 500)
        profile = await self.get_profile(user_id)
        if not profile.student_id:
            raise BusinessException("学生档案未绑定，无法上传今日心情", 400)
        moments = await self.list_today_moments(user_id)
        data = await self.mood_report_service.generate_report(
            moments=moments,
            category_filter=payload.category_filter,
            profile_mood=profile.today_mood,
        )
        entity = DailyMoodReport(
            user_id=user_id,
            student_id=profile.student_id,
            report_date=date.today(),
            category_filter=payload.category_filter,
            moment_count=data["moment_count"],
            mood_counts=data["mood_counts"],
            radar_scores=data["radar_scores"],
            teacher_radar_scores=data["teacher_radar_scores"],
            category_breakdown=data["category_breakdown"],
            concern_level=data["concern_level"],
            risk_flags=data["risk_flags"],
            attention_highlights=data["attention_highlights"],
            fuzzy_analysis=data["fuzzy_analysis"],
            student_insight=data["student_insight"],
            warm_suggestion=data["warm_suggestion"],
            ai_generated=data["ai_generated"],
            growth_insight=data.get("growth_insight") or {},
        )
        await self.mood_report_repo.upsert(entity)
        return {
            "report_date": data["report_date"],
            "category_filter": data["category_filter"],
            "mood_counts": data["mood_counts"],
            "radar_scores": data["radar_scores"],
            "moment_count": data["moment_count"],
            "insight_summary": data["student_insight"],
            "warm_suggestion": data["warm_suggestion"],
            "concern_label": STUDENT_CONCERN_LABEL.get(data["concern_level"], "状态平稳"),
            "ai_generated": data["ai_generated"],
            "analysis_source": data.get("analysis_source", "unknown"),
            "uploaded_at": data["uploaded_at"],
        }

    async def delete_moment(self, user_id: uuid.UUID, moment_id: uuid.UUID) -> None:
        moment = await self.moment_repo.get_by_id_and_user(moment_id, user_id)
        if not moment:
            raise BusinessException("今日事件不存在或无权删除", 404)
        self._ensure_moment_editable_today(moment)
        deleted = await self.moment_repo.delete_by_id_and_user(moment_id, user_id)
        if not deleted:
            raise BusinessException("今日事件不存在或无权删除", 404)
