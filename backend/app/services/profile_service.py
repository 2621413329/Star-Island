import uuid
from datetime import date, timedelta
from types import SimpleNamespace

from app.exceptions.business import BusinessException
from app.models.daily_mood_report import DailyMoodReport
from app.models.profile import DailyMoment, UserProfile
from app.models.student import Student
from app.models.user import User
from app.models.user_growth_state import UserGrowthState
from app.repositories.daily_mood_report_repository import DailyMoodReportRepository
from app.repositories.profile_repository import DailyMomentRepository, ProfileRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.user_growth_state_repository import UserGrowthStateRepository
from app.repositories.user_repository import UserRepository
from app.schemas.profile import (
    DailyMomentCreate,
    DailyMoodReportUpload,
    ProfileCompanionUpdate,
    ProfileCompanionRoleUpdate,
    ProfileGenderUpdate,
    ProfileMoodUpdate,
    ProfileNicknameUpdate,
    ProfileAppPreferencesUpdate,
    ProfileRead,
)
from app.services.companion_action_ai_service import CompanionActionAIService
from app.services.companion_scene_service import CompanionSceneService
from app.core.companion_roles import (
    COMPANION_ROLE_SEEDS,
    is_valid_companion_role_id,
    migrate_gender_to_role_id,
    render_key_for_role,
    resolve_companion_role_id,
)
from app.core.school_classes import DEFAULT_CLASS_NAME
from app.core.companion_prop_labels import ensure_visual_prop_label
from app.services.daily_mood_report_service import DailyMoodReportService
from app.services.growth_observation_analysis_service import (
    DISCLAIMER,
    GrowthObservationAnalysisService,
)
from app.services.growth_points_service import GrowthPointsService, aggregate_emotion_fragments
from app.schemas.growth import EmotionFragmentSummaryRead, GrowthSummaryRead

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
        growth_state_repo: UserGrowthStateRepository | None = None,
        user_repo: UserRepository | None = None,
    ):
        self.profile_repo = profile_repo
        self.moment_repo = moment_repo
        self.student_repo = student_repo
        self.user_repo = user_repo
        self.scene_service = scene_service or CompanionSceneService()
        self.action_ai = action_ai or CompanionActionAIService()
        self.mood_report_service = mood_report_service or DailyMoodReportService()
        self.mood_report_repo = mood_report_repo
        self.observation_svc = GrowthObservationAnalysisService()
        self.growth_state_repo = growth_state_repo
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
                class_id=None,
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
        growth_read: GrowthSummaryRead | None = None
        fragment_read: EmotionFragmentSummaryRead | None = None
        if self.growth_state_repo:
            state = await self.growth_state_repo.get_by_user_id(profile.user_id)
            if state is None:
                state = await self.refresh_growth_state(profile.user_id)
            if state:
                growth_read = self._growth_state_to_read(state)
                fragment_read = EmotionFragmentSummaryRead(
                    total_count=state.emotion_fragment_count,
                    totals=dict(state.emotion_totals or {}),
                )
        return ProfileRead(
            user_id=profile.user_id,
            student_id=profile.student_id,
            nickname=nickname,
            class_name=class_name,
            gender=render_key_for_role(profile.companion_role_id) or profile.gender,
            companion_role_id=profile.companion_role_id,
            companion_style=profile.companion_style,
            today_mood=profile.today_mood,
            onboarding_completed=profile.onboarding_completed,
            app_preferences=dict(profile.app_preferences or {}),
            created_at=profile.created_at,
            updated_at=profile.updated_at,
            growth=growth_read,
            emotion_fragments=fragment_read,
        )

    async def update_nickname(self, user: User, payload: ProfileNicknameUpdate) -> UserProfile:
        if self.user_repo is None:
            raise BusinessException("用户服务未配置", 500)
        profile = await self.get_profile(user.id)
        user.nickname = payload.nickname
        await self.user_repo.save(user)
        if profile.student_id:
            student = await self.student_repo.get_by_id(profile.student_id)
            if student:
                student.name = payload.nickname
                await self.student_repo.update(student)
        return profile

    async def update_companion_role(
        self, user_id: uuid.UUID, payload: ProfileCompanionRoleUpdate
    ) -> UserProfile:
        role_id = payload.companion_role_id.strip()
        if not is_valid_companion_role_id(role_id):
            raise BusinessException("无效的角色 id", 400)
        profile = await self.get_profile(user_id)
        profile.companion_role_id = role_id
        if not profile.onboarding_completed:
            profile.companion_style = profile.companion_style or "chibi"
            profile.onboarding_completed = True
        return await self.profile_repo.save(profile)

    async def update_gender(self, user_id: uuid.UUID, payload: ProfileGenderUpdate) -> UserProfile:
        role_id = migrate_gender_to_role_id(payload.gender)
        if not role_id:
            raise BusinessException("无效的角色选择", 400)
        return await self.update_companion_role(
            user_id, ProfileCompanionRoleUpdate(companion_role_id=role_id)
        )

    @staticmethod
    def list_companion_roles() -> list[dict]:
        return [
            {
                "id": item["id"],
                "display_name": item["display_name"],
                "render_key": item["render_key"],
            }
            for item in sorted(COMPANION_ROLE_SEEDS, key=lambda x: x["sort_order"])
            if item.get("is_active", True)
        ]

    async def update_companion(self, user_id: uuid.UUID, payload: ProfileCompanionUpdate) -> UserProfile:
        profile = await self.get_profile(user_id)
        profile.companion_style = payload.companion_style
        return await self.profile_repo.save(profile)

    async def update_mood(self, user_id: uuid.UUID, payload: ProfileMoodUpdate) -> UserProfile:
        profile = await self.get_profile(user_id)
        profile.today_mood = payload.today_mood
        profile = await self.profile_repo.save(profile)
        await self.refresh_growth_state(user_id)
        return profile

    async def complete_onboarding(self, user_id: uuid.UUID) -> UserProfile:
        profile = await self.get_profile(user_id)
        if not resolve_companion_role_id(
            companion_role_id=profile.companion_role_id,
            legacy_gender=profile.gender,
        ) or not profile.companion_style or not profile.today_mood:
            raise BusinessException("请先完成角色、伙伴形象与今日心情选择", 400)
        profile.onboarding_completed = True
        return await self.profile_repo.save(profile)

    async def update_app_preferences(
        self, user_id: uuid.UUID, payload: ProfileAppPreferencesUpdate
    ) -> UserProfile:
        profile = await self.get_profile(user_id)
        prefs = dict(profile.app_preferences or {})
        data = payload.model_dump(exclude_unset=True)
        prefs.update(data)
        profile.app_preferences = prefs
        return await self.profile_repo.save(profile)

    async def create_moment(self, user_id: uuid.UUID, payload: DailyMomentCreate) -> DailyMoment:
        profile = await self.get_profile(user_id)
        if not profile.companion_style:
            raise BusinessException("请先选择成长伙伴形象", 400)

        if payload.client_event_id:
            existing = await self.moment_repo.get_by_client_event_id(
                user_id, payload.client_event_id
            )
            if existing:
                await self.refresh_growth_state(user_id)
                return existing

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
        ensure_visual_prop_label(visual)
        scene["visual_payload"] = visual
        moment = DailyMoment(
            user_id=user_id,
            student_id=profile.student_id,
            event_tags=payload.event_tags,
            emotion_tag=payload.emotion_tag,
            note=payload.note,
            client_event_id=payload.client_event_id,
            companion_scene=scene["companion_scene"],
            companion_pose=scene["companion_pose"],
            visual_payload=scene["visual_payload"],
            moment_date=date.today(),
        )
        created = await self.moment_repo.create(moment)
        await self.refresh_growth_state(user_id)
        return created

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
        ensure_visual_prop_label(visual)
        scene["visual_payload"] = visual

        moment.event_tags = payload.event_tags
        moment.emotion_tag = payload.emotion_tag
        moment.note = payload.note
        moment.companion_scene = scene["companion_scene"]
        moment.companion_pose = scene["companion_pose"]
        moment.visual_payload = scene["visual_payload"]
        saved = await self.moment_repo.save(moment)
        await self.refresh_growth_state(user_id)
        return saved

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
        state = await self.refresh_growth_state(user_id, days=days)
        if state:
            return self._growth_state_to_read(state)
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

    @staticmethod
    def _growth_state_to_read(state: UserGrowthState) -> GrowthSummaryRead:
        return GrowthSummaryRead(
            growth_value=state.growth_value,
            level=state.level,
            level_title=state.level_title,
            streak_days=state.streak_days,
            max_streak_days=state.max_streak_days,
            next_level=state.next_level,
            next_level_title=state.next_level_title,
            xp_into_level=state.xp_into_level,
            xp_for_next_level=state.xp_for_next_level,
            island_stage=state.island_stage,
            unlock_label=state.unlock_label,
            today_mood=state.today_mood,
            today_weather_label=state.today_weather_label,
        )

    @staticmethod
    def _island_seed_for_user(user_id: uuid.UUID) -> int:
        return int(user_id.int % 1_000_000_000)

    async def refresh_growth_state(
        self, user_id: uuid.UUID, *, days: int = 365
    ) -> UserGrowthState | None:
        if not self.growth_state_repo:
            return None
        profile = await self.get_profile(user_id)
        since = date.today() - timedelta(days=max(30, min(days, 730)))
        moments = await self.moment_repo.list_by_user_since(user_id, since)
        all_moments = await self.moment_repo.list_by_user(user_id)
        reports: list = []
        if self.mood_report_repo:
            reports = await self.mood_report_repo.list_by_user_since(user_id, since)
        summary = self.growth_points.compute(
            moments=moments,
            reports=reports,
            today=date.today(),
            profile_today_mood=profile.today_mood,
        )
        fragment_count, emotion_totals = aggregate_emotion_fragments(all_moments)
        existing = await self.growth_state_repo.get_by_user_id(user_id)
        island_seed = (
            existing.island_seed
            if existing and existing.island_seed
            else self._island_seed_for_user(user_id)
        )
        state = UserGrowthState(
            user_id=user_id,
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
            emotion_fragment_count=fragment_count,
            emotion_totals=emotion_totals,
            island_seed=island_seed,
        )
        return await self.growth_state_repo.upsert(state)

    @staticmethod
    def _mood_period_start(period: str, today: date) -> date:
        if period == "week":
            return today - timedelta(days=today.weekday())
        if period == "month":
            return today.replace(day=1)
        if period == "year":
            return today.replace(month=1, day=1)
        return today

    @staticmethod
    def _mood_report_to_student_read(report: DailyMoodReport) -> dict:
        return {
            "report_date": report.report_date.isoformat(),
            "category_filter": report.category_filter,
            "mood_counts": report.mood_counts or {},
            "radar_scores": report.radar_scores or {},
            "moment_count": report.moment_count,
            "insight_summary": report.student_insight,
            "warm_suggestion": report.warm_suggestion,
            "concern_label": STUDENT_CONCERN_LABEL.get(
                report.concern_level, "状态平稳"
            ),
            "ai_generated": report.ai_generated,
            "analysis_source": "stored",
            "uploaded_at": report.updated_at.isoformat(),
            "weekly_hint": "",
            "weekly_trend_label": "",
        }

    async def list_mood_reports_for_period(
        self, user_id: uuid.UUID, *, period: str = "today"
    ) -> list[dict]:
        if not self.mood_report_repo:
            return []
        today = date.today()
        since = self._mood_period_start(period, today)
        reports = await self.mood_report_repo.list_by_user_since(user_id, since)
        visible = [r for r in reports if r.report_date <= today]
        visible.sort(key=lambda r: r.report_date, reverse=True)
        return [self._mood_report_to_student_read(r) for r in visible]

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
        since = date.today() - timedelta(days=6)
        recent_reports = await self.mood_report_repo.list_by_user_since(user_id, since)
        recent_moments = await self.moment_repo.list_by_user_since(user_id, since)
        data = await self.mood_report_service.generate_report(
            moments=moments,
            category_filter=payload.category_filter,
            profile_mood=profile.today_mood,
        )
        mood_counts_today: dict[str, int] = {}
        for m in moments:
            mood_counts_today[m.emotion_tag] = mood_counts_today.get(m.emotion_tag, 0) + 1
        reports_for_obs = [r for r in recent_reports if r.report_date != date.today()]
        reports_for_obs.append(
            SimpleNamespace(
                report_date=date.today(),
                concern_level=data["concern_level"],
                mood_counts=mood_counts_today,
                category_breakdown=data["category_breakdown"],
                risk_flags=data["risk_flags"],
                growth_insight=data.get("growth_insight") or {},
                dismissed_risk_moment_ids=[],
                moment_count=len(moments),
            )
        )
        danger_hit = any(
            self.observation_svc.insight_svc.moment_note_is_critical(m)
            for m in moments
        )
        observation = await self.observation_svc.analyze_period_with_ai(
            reports_for_obs,
            recent_moments,
            anchor_date=date.today(),
            days=7,
            skip_ai=danger_hit,
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
            growth_observation=observation,
        )
        await self.mood_report_repo.upsert(entity)
        await self.refresh_growth_state(user_id)
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
            "weekly_hint": observation.get("student_weekly_hint") or "",
            "weekly_trend_label": (observation.get("emotion_trend") or {}).get("label") or "",
        }

    async def get_student_growth_observation(
        self, user_id: uuid.UUID, *, days: int = 7
    ) -> dict:
        if not self.mood_report_repo:
            return {
                "weekly_hint": "继续记录，小星会更懂你的节奏～",
                "trend_label": "稳定",
                "stress_directions": [],
                "disclaimer": DISCLAIMER,
            }
        since = date.today() - timedelta(days=max(days - 1, 0))
        reports = await self.mood_report_repo.list_by_user_since(user_id, since)
        moments = await self.moment_repo.list_by_user_since(user_id, since)
        observation = await self.observation_svc.analyze_period_with_ai(
            reports,
            moments,
            anchor_date=date.today(),
            days=days,
            skip_ai=False,
        )
        return {
            "weekly_hint": observation.get("student_weekly_hint") or "",
            "trend_label": (observation.get("emotion_trend") or {}).get("label") or "稳定",
            "stress_directions": [
                s.get("label") for s in (observation.get("stress_sources") or [])[:3]
            ],
            "disclaimer": observation.get("disclaimer") or "",
        }

    async def delete_moment(self, user_id: uuid.UUID, moment_id: uuid.UUID) -> None:
        moment = await self.moment_repo.get_by_id_and_user(moment_id, user_id)
        if not moment:
            raise BusinessException("今日事件不存在或无权删除", 404)
        self._ensure_moment_editable_today(moment)
        deleted = await self.moment_repo.delete_by_id_and_user(moment_id, user_id)
        if not deleted:
            raise BusinessException("今日事件不存在或无权删除", 404)
        await self.refresh_growth_state(user_id)
