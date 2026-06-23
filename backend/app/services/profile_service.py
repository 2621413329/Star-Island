import uuid
from datetime import date, timedelta
from types import SimpleNamespace

from app.exceptions.business import BusinessException
from app.models.daily_mood_report import DailyMoodReport
from app.models.profile import DailyMoment, UserProfile
from app.models.user import User
from app.models.user_growth_state import UserGrowthState
from app.repositories.daily_mood_report_repository import DailyMoodReportRepository
from app.repositories.growth_tag_repository import GrowthTagRepository
from app.repositories.profile_repository import DailyMomentRepository, ProfileRepository
from app.repositories.user_building_unlock_repository import UserBuildingUnlockRepository
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
    DailyMomentTagsUpdate,
)
from app.core.moment_content import CONTENT_TYPE_TEXT, CONTENT_TYPE_VOICE, get_story_content, is_voice_moment
from app.services.companion_scene_service import CompanionSceneService
from app.services.companion_action_ai_service import CompanionActionAIService
from app.core.companion_prop_labels import ensure_visual_prop_label
from app.core.companion_roles import (
    COMPANION_ROLE_SEEDS,
    is_valid_companion_role_id,
    migrate_gender_to_role_id,
    render_key_for_role,
    resolve_companion_role_id,
)
from app.services.daily_mood_report_service import DailyMoodReportService
from app.services.mood_period_summary_service import MoodPeriodSummaryService
from app.services.growth_observation_analysis_service import (
    DISCLAIMER,
    GrowthObservationAnalysisService,
)
from app.services.building_unlock_service import BuildingUnlockService
from app.services.moment_analysis_service import MomentAnalysisService
from app.services.moment_photo_service import MomentPhotoService
from app.services.moment_voice_service import MomentVoiceService
from app.services.moment_voice_pipeline import schedule_voice_transcription
from app.services.growth_points_service import GrowthPointsService, aggregate_emotion_fragments
from app.schemas.growth import BuildingUnlockRead, EmotionFragmentSummaryRead, GrowthSummaryRead

USER_CONCERN_LABEL = {
    "normal": "今天还不错",
    "watch": "可以慢慢来",
    "urgent": "小星会一直陪着你",
}


class ProfileService:
    def __init__(
        self,
        profile_repo: ProfileRepository,
        moment_repo: DailyMomentRepository,
        scene_service: CompanionSceneService | None = None,
        mood_report_service: DailyMoodReportService | None = None,
        mood_report_repo: DailyMoodReportRepository | None = None,
        growth_state_repo: UserGrowthStateRepository | None = None,
        building_unlock_repo: UserBuildingUnlockRepository | None = None,
        growth_tag_repo: GrowthTagRepository | None = None,
        user_repo: UserRepository | None = None,
    ):
        self.profile_repo = profile_repo
        self.moment_repo = moment_repo
        self.user_repo = user_repo
        self.scene_service = scene_service or CompanionSceneService()
        self.mood_report_service = mood_report_service or DailyMoodReportService()
        self.mood_period_summary_service = MoodPeriodSummaryService()
        self.mood_report_repo = mood_report_repo
        self.observation_svc = GrowthObservationAnalysisService()
        self.growth_state_repo = growth_state_repo
        self.building_unlock_repo = building_unlock_repo
        self.growth_points = GrowthPointsService()
        self.building_unlock_service = (
            BuildingUnlockService(building_unlock_repo) if building_unlock_repo else None
        )
        self.growth_tag_repo = growth_tag_repo
        self.moment_analysis = MomentAnalysisService()
        self.companion_action = CompanionActionAIService()
        self.moment_photos = MomentPhotoService()
        self.moment_voice = MomentVoiceService()

    async def ensure_profile(self, user: User) -> UserProfile:
        profile = await self.profile_repo.get_by_user_id(user.id)
        if profile:
            return profile
        profile = UserProfile(user_id=user.id, onboarding_completed=False)
        return await self.profile_repo.create(profile)

    async def get_profile(self, user_id: uuid.UUID) -> UserProfile:
        profile = await self.profile_repo.get_by_user_id(user_id)
        if not profile:
            raise BusinessException("用户资料不存在", 404)
        return profile

    async def _resolve_nickname(self, user_id: uuid.UUID) -> str | None:
        if self.user_repo is None:
            return None
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            return None
        nick = (user.nickname or "").strip()
        return nick or None

    async def _build_companion_scene(
        self,
        user_id: uuid.UUID,
        profile: UserProfile,
        *,
        emotion_tag: str,
        event_tags: list[str],
        note: str | None,
    ) -> dict:
        base = self.scene_service.build(
            companion_style=profile.companion_style or "chibi",
            emotion_tag=emotion_tag,
            event_tags=event_tags,
            note=note,
        )
        return await self.companion_action.enrich(
            companion_style=profile.companion_style or "chibi",
            emotion_tag=emotion_tag,
            event_tags=event_tags,
            note=note,
            base_scene=base,
        )

    async def to_profile_read(self, profile: UserProfile, user: User | None = None) -> ProfileRead:
        nickname: str | None = user.display_name if user is not None else None
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
            nickname=nickname,
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
        old_nickname = (user.nickname or "").strip()
        user.nickname = payload.nickname
        await self.user_repo.save(user)
        await self._migrate_dialogue_nickname_templates(user.id, old_nickname)
        return profile

    async def _migrate_dialogue_nickname_templates(
        self, user_id: uuid.UUID, old_nickname: str
    ) -> None:
        if not old_nickname:
            return
        from app.core.companion_dialogue import normalize_dialogue_templates

        moments = await self.moment_repo.list_by_user(user_id)
        for moment in moments:
            visual = dict(moment.visual_payload or {})
            raw_lines = visual.get("story_summary_lines")
            if not isinstance(raw_lines, list) or not raw_lines:
                continue
            original = [str(line) for line in raw_lines]
            migrated = normalize_dialogue_templates(
                original,
                legacy_nickname=old_nickname,
            )
            if migrated == original:
                continue
            visual["story_summary_lines"] = migrated
            moment.visual_payload = visual
            await self.moment_repo.save(moment)

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

    async def _resolve_moment_tags(
        self, payload: DailyMomentCreate
    ) -> tuple[list[str], str, str | None, list[str], list[str], str | None]:
        if payload.primary_tag:
            return await self._resolve_manual_moment_tags(payload)

        if not self.growth_tag_repo:
            raise BusinessException("标签服务未就绪", 503)
        categories = await self.growth_tag_repo.list_categories(active_only=True)
        analysis = await self.moment_analysis.analyze(payload.note, categories)
        event_tags = self.moment_analysis.build_event_tags(analysis)
        return (
            event_tags,
            analysis.legacy_emotion_tag,
            analysis.primary_tag,
            analysis.secondary_tags,
            analysis.growth_points,
            analysis.emotion,
        )

    async def _resolve_manual_moment_tags(
        self, payload: DailyMomentCreate
    ) -> tuple[list[str], str, str | None, list[str], list[str], str | None]:
        if not self.growth_tag_repo:
            raise BusinessException("标签服务未就绪", 503)
        from app.services.moment_analysis_service import AI_EMOTION_TO_LEGACY

        primary = (payload.primary_tag or "").strip()
        if not primary:
            raise BusinessException("请选择一级标签", 400)
        categories = await self.growth_tag_repo.list_categories(active_only=True)
        catalog = self.moment_analysis.build_catalog(categories)
        if primary not in catalog.primary_labels:
            raise BusinessException("无效的一级标签", 400)

        allowed = catalog.secondary_by_primary.get(primary, set())
        secondary: list[str] = []
        for item in payload.secondary_tags or []:
            label = str(item).strip()
            if label in allowed and label not in secondary:
                secondary.append(label)

        ai_emotion = (payload.ai_emotion or "").strip() or None
        if payload.emotion_tag:
            legacy = payload.emotion_tag
            ai_emotion = None
        elif ai_emotion:
            legacy = AI_EMOTION_TO_LEGACY.get(ai_emotion, "calm")
        else:
            legacy = "calm"

        event_tags = [primary, *secondary]
        return event_tags, legacy, primary, secondary, [], ai_emotion

    @staticmethod
    def _finalize_moment_scene(
        scene: dict,
        *,
        primary_tag: str | None,
        secondary_tags: list[str],
        growth_points: list[str],
        ai_emotion: str | None,
    ) -> dict:
        visual = dict(scene.get("visual_payload") or {})
        if primary_tag:
            visual["primary_tag"] = primary_tag
        if secondary_tags:
            visual["secondary_tags"] = secondary_tags
        if growth_points:
            visual["growth_points"] = growth_points
        if ai_emotion:
            visual["ai_emotion"] = ai_emotion
        else:
            visual.pop("ai_emotion", None)
        ensure_visual_prop_label(visual)
        return {**scene, "visual_payload": visual}

    @staticmethod
    def _sync_scene_expression_to_emotion(scene: dict, emotion_tag: str) -> dict:
        visual = dict(scene.get("visual_payload") or {})
        visual["expression"] = CompanionActionAIService.expression_for_emotion_tag(
            emotion_tag
        )
        visual["emotion_tag"] = emotion_tag
        visual["island_mood"] = emotion_tag
        return {**scene, "visual_payload": visual}

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

        (
            event_tags,
            emotion_tag,
            primary_tag,
            secondary_tags,
            growth_points,
            ai_emotion,
        ) = await self._resolve_moment_tags(payload)

        scene = await self._build_companion_scene(
            user_id,
            profile,
            emotion_tag=emotion_tag,
            event_tags=event_tags,
            note=payload.note,
        )
        scene = self._finalize_moment_scene(
            scene,
            primary_tag=primary_tag,
            secondary_tags=secondary_tags,
            growth_points=growth_points,
            ai_emotion=ai_emotion,
        )
        moment = DailyMoment(
            user_id=user_id,
            event_tags=event_tags,
            emotion_tag=emotion_tag,
            primary_tag=primary_tag,
            secondary_tags=secondary_tags,
            growth_points=growth_points,
            ai_emotion=ai_emotion,
            note=payload.note,
            content_type=CONTENT_TYPE_TEXT,
            client_event_id=payload.client_event_id,
            companion_scene=scene["companion_scene"],
            companion_pose=scene["companion_pose"],
            visual_payload=scene["visual_payload"],
            photos=[],
            moment_date=date.today(),
        )
        created = await self.moment_repo.create(moment)
        if ai_emotion and not profile.today_mood:
            profile.today_mood = emotion_tag
            await self.profile_repo.save(profile)
        await self.refresh_growth_state(user_id)
        return created

    async def create_voice_moment(
        self,
        user_id: uuid.UUID,
        upload,
        *,
        voice_duration: int,
        client_event_id: str | None = None,
    ) -> DailyMoment:
        profile = await self.get_profile(user_id)
        if not profile.companion_style:
            raise BusinessException("请先选择成长伙伴形象", 400)

        if client_event_id:
            existing = await self.moment_repo.get_by_client_event_id(
                user_id, client_event_id
            )
            if existing:
                await self.refresh_growth_state(user_id)
                return existing

        meta = await self.moment_voice.save_upload(
            user_id=user_id,
            upload=upload,
            voice_duration=voice_duration,
        )

        event_tags = ["生活"]
        emotion_tag = "calm"
        primary_tag = "生活"
        secondary_tags: list[str] = []
        growth_points: list[str] = []
        ai_emotion = "平静"

        scene = self.scene_service.build(
            companion_style=profile.companion_style,
            emotion_tag=emotion_tag,
            event_tags=event_tags,
            note=None,
        )
        scene = self._finalize_moment_scene(
            scene,
            primary_tag=primary_tag,
            secondary_tags=secondary_tags,
            growth_points=growth_points,
            ai_emotion=ai_emotion,
        )
        visual = dict(scene.get("visual_payload") or {})
        visual["voice_analysis_pending"] = True
        scene = {**scene, "visual_payload": visual}

        moment = DailyMoment(
            user_id=user_id,
            event_tags=event_tags,
            emotion_tag=emotion_tag,
            primary_tag=primary_tag,
            secondary_tags=secondary_tags,
            growth_points=growth_points,
            ai_emotion=ai_emotion,
            note=None,
            content_type=CONTENT_TYPE_VOICE,
            voice_url=meta["url_path"],
            voice_duration=meta["voice_duration"],
            voice_size=meta["size_bytes"],
            speech_text=None,
            speech_status="pending",
            client_event_id=client_event_id,
            companion_scene=scene["companion_scene"],
            companion_pose=scene["companion_pose"],
            visual_payload=scene["visual_payload"],
            photos=[],
            moment_date=date.today(),
        )
        created = await self.moment_repo.create(moment)
        await schedule_voice_transcription(
            moment_id=created.id,
            user_id=user_id,
            audio_path=meta["file_path"],
            voice_url=meta["url_path"],
        )
        await self.refresh_growth_state(user_id)
        return created

    async def replace_voice_moment(
        self,
        user_id: uuid.UUID,
        moment_id: uuid.UUID,
        upload,
        *,
        voice_duration: int,
    ) -> DailyMoment:
        moment = await self.moment_repo.get_by_id_and_user(moment_id, user_id)
        if not moment:
            raise BusinessException("今日事件不存在或无权修改", 404)
        if moment.content_type != CONTENT_TYPE_VOICE:
            raise BusinessException("仅语音日常支持重新录制", 400)
        self._ensure_moment_editable_today(moment)
        profile = await self.get_profile(user_id)
        if not profile.companion_style:
            raise BusinessException("请先选择成长伙伴形象", 400)

        self.moment_voice.delete_voice_file(moment.voice_url)
        meta = await self.moment_voice.save_upload(
            user_id=user_id,
            upload=upload,
            voice_duration=voice_duration,
            on_date=moment.moment_date,
        )

        event_tags = ["生活"]
        emotion_tag = "calm"
        primary_tag = "生活"
        secondary_tags: list[str] = []
        growth_points: list[str] = []
        ai_emotion = "平静"

        scene = self.scene_service.build(
            companion_style=profile.companion_style,
            emotion_tag=emotion_tag,
            event_tags=event_tags,
            note=None,
        )
        scene = self._finalize_moment_scene(
            scene,
            primary_tag=primary_tag,
            secondary_tags=secondary_tags,
            growth_points=growth_points,
            ai_emotion=ai_emotion,
        )
        visual = dict(scene.get("visual_payload") or {})
        visual["voice_analysis_pending"] = True
        scene = {**scene, "visual_payload": visual}

        moment.voice_url = meta["url_path"]
        moment.voice_duration = meta["voice_duration"]
        moment.voice_size = meta["size_bytes"]
        moment.speech_text = None
        moment.speech_status = "pending"
        moment.event_tags = event_tags
        moment.emotion_tag = emotion_tag
        moment.primary_tag = primary_tag
        moment.secondary_tags = secondary_tags
        moment.growth_points = growth_points
        moment.ai_emotion = ai_emotion
        moment.companion_scene = scene["companion_scene"]
        moment.companion_pose = scene["companion_pose"]
        moment.visual_payload = scene["visual_payload"]

        saved = await self.moment_repo.save(moment)
        await schedule_voice_transcription(
            moment_id=saved.id,
            user_id=user_id,
            audio_path=meta["file_path"],
            voice_url=meta["url_path"],
        )
        await self.refresh_growth_state(user_id)
        return saved

    def _ensure_moment_editable_today(self, moment: DailyMoment) -> None:
        if moment.moment_date != date.today():
            raise BusinessException("仅今日日常可以修改或删除", 403)

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

        (
            event_tags,
            emotion_tag,
            primary_tag,
            secondary_tags,
            growth_points,
            ai_emotion,
        ) = await self._resolve_moment_tags(payload)

        scene_note = get_story_content(moment) if is_voice_moment(moment) else payload.note
        scene = await self._build_companion_scene(
            user_id,
            profile,
            emotion_tag=emotion_tag,
            event_tags=event_tags,
            note=scene_note or None,
        )
        scene = self._finalize_moment_scene(
            scene,
            primary_tag=primary_tag,
            secondary_tags=secondary_tags,
            growth_points=growth_points,
            ai_emotion=ai_emotion,
        )
        if payload.emotion_tag:
            scene = self._sync_scene_expression_to_emotion(scene, emotion_tag)

        moment.event_tags = event_tags
        moment.emotion_tag = emotion_tag
        moment.primary_tag = primary_tag
        moment.secondary_tags = secondary_tags
        moment.growth_points = growth_points
        moment.ai_emotion = ai_emotion
        if not is_voice_moment(moment):
            moment.note = payload.note
        moment.companion_scene = scene["companion_scene"]
        moment.companion_pose = scene["companion_pose"]
        moment.visual_payload = scene["visual_payload"]
        saved = await self.moment_repo.save(moment)
        await self.refresh_growth_state(user_id)
        return saved

    async def update_moment_tags(
        self,
        user_id: uuid.UUID,
        moment_id: uuid.UUID,
        payload: DailyMomentTagsUpdate,
    ) -> DailyMoment:
        moment = await self.moment_repo.get_by_id_and_user(moment_id, user_id)
        if not moment:
            raise BusinessException("今日事件不存在或无权修改", 404)
        self._ensure_moment_editable_today(moment)
        profile = await self.get_profile(user_id)
        if not profile.companion_style:
            raise BusinessException("请先选择成长伙伴形象", 400)

        manual = DailyMomentCreate(
            note=get_story_content(moment) or "（语音记录）",
            primary_tag=payload.primary_tag,
            secondary_tags=payload.secondary_tags,
            ai_emotion=payload.ai_emotion,
            emotion_tag=payload.emotion_tag,
        )
        (
            event_tags,
            emotion_tag,
            primary_tag,
            secondary_tags,
            growth_points,
            ai_emotion,
        ) = await self._resolve_manual_moment_tags(manual)

        scene_note = get_story_content(moment) or None
        scene = await self._build_companion_scene(
            user_id,
            profile,
            emotion_tag=emotion_tag,
            event_tags=event_tags,
            note=scene_note,
        )
        scene = self._finalize_moment_scene(
            scene,
            primary_tag=primary_tag,
            secondary_tags=secondary_tags,
            growth_points=growth_points,
            ai_emotion=ai_emotion,
        )

        moment.event_tags = event_tags
        moment.emotion_tag = emotion_tag
        moment.primary_tag = primary_tag
        moment.secondary_tags = secondary_tags
        moment.growth_points = growth_points
        moment.ai_emotion = ai_emotion
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

    async def get_building_unlocks(self, user_id: uuid.UUID) -> list[BuildingUnlockRead]:
        if not self.building_unlock_service:
            return []
        await self.refresh_growth_state(user_id)
        rows = await self.building_unlock_service.list_for_user(user_id)
        return [
            BuildingUnlockRead(
                building_id=row.building_id,
                unlock_level=row.unlock_level,
                unlocked_at=row.unlocked_at,
            )
            for row in rows
        ]

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
        saved = await self.growth_state_repo.upsert(state)
        if self.building_unlock_service:
            await self.building_unlock_service.sync_for_user(
                user_id=user_id,
                growth_value=summary.growth_value,
                moments=all_moments,
                reports=reports,
                profile_today_mood=profile.today_mood,
            )
        return saved

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
    def _mood_report_to_read(report: DailyMoodReport) -> dict:
        return {
            "report_date": report.report_date.isoformat(),
            "category_filter": report.category_filter,
            "mood_counts": report.mood_counts or {},
            "radar_scores": report.radar_scores or {},
            "moment_count": report.moment_count,
            "insight_summary": report.insight_summary,
            "warm_suggestion": report.warm_suggestion,
            "concern_label": USER_CONCERN_LABEL.get(
                report.concern_level, "状态平稳"
            ),
            "ai_generated": report.ai_generated,
            "analysis_source": "stored",
            "uploaded_at": report.updated_at.isoformat(),
            "weekly_hint": "",
            "weekly_trend_label": "",
        }

    async def get_mood_period_summary(
        self,
        user_id: uuid.UUID,
        *,
        period: str = "today",
        category_filter: str | None = None,
    ) -> dict:
        today = date.today()
        fetch_days = {
            "today": 1,
            "week": 7,
            "month": 31,
            "year": 365,
        }.get(period, 1)
        since = today - timedelta(days=max(1, fetch_days))
        moments = await self.moment_repo.list_by_user_since(user_id, since)
        return await self.mood_period_summary_service.build_summary(
            moments,
            period=period,
            category_filter=category_filter,
            today=today,
        )

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
        return [self._mood_report_to_read(r) for r in visible]

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
        observation = await self.observation_svc.analyze_period_with_ai(
            reports_for_obs,
            recent_moments,
            anchor_date=date.today(),
            days=7,
        )
        entity = DailyMoodReport(
            user_id=user_id,
            report_date=date.today(),
            category_filter=payload.category_filter,
            moment_count=data["moment_count"],
            mood_counts=data["mood_counts"],
            radar_scores=data["radar_scores"],
            category_breakdown=data["category_breakdown"],
            concern_level=data["concern_level"],
            risk_flags=data["risk_flags"],
            attention_highlights=data["attention_highlights"],
            insight_summary=data["insight_summary"],
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
            "insight_summary": data["insight_summary"],
            "warm_suggestion": data["warm_suggestion"],
            "concern_label": USER_CONCERN_LABEL.get(data["concern_level"], "状态平稳"),
            "ai_generated": data["ai_generated"],
            "analysis_source": data.get("analysis_source", "unknown"),
            "uploaded_at": data["uploaded_at"],
            "weekly_hint": observation.get("weekly_hint") or "",
            "weekly_trend_label": (observation.get("emotion_trend") or {}).get("label") or "",
        }

    async def get_weekly_summary(self, user_id: uuid.UUID, *, days: int = 7) -> dict:
        if not self.mood_report_repo:
            return {
                "weekly_hint": "继续记录，小星会更懂你的节奏～",
                "trend_label": "稳定",
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
        )
        return {
            "weekly_hint": observation.get("weekly_hint") or "",
            "trend_label": (observation.get("emotion_trend") or {}).get("label") or "稳定",
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
        self.moment_photos.delete_moment_dir(user_id, moment_id)
        self.moment_voice.delete_voice_file(moment.voice_url)
        await self.refresh_growth_state(user_id)
        await self._sync_mood_report_after_moment_delete(user_id)

    async def _sync_mood_report_after_moment_delete(self, user_id: uuid.UUID) -> None:
        if not self.mood_report_repo:
            return
        today = date.today()
        remaining = await self.moment_repo.list_by_user_and_date(user_id, today)
        if remaining:
            return
        await self.mood_report_repo.delete_by_user_and_date(user_id, today)

    async def upload_moment_photo(
        self,
        user_id: uuid.UUID,
        moment_id: uuid.UUID,
        upload,
    ) -> DailyMoment:
        moment = await self.moment_repo.get_by_id_and_user(moment_id, user_id)
        if not moment:
            raise BusinessException("今日事件不存在或无权修改", 404)
        self._ensure_moment_editable_today(moment)
        photos = list(moment.photos or [])
        meta = await self.moment_photos.save_upload(
            user_id=user_id,
            moment_id=moment_id,
            upload=upload,
            existing_count=len(photos),
        )
        photos.append(meta)
        moment.photos = photos
        return await self.moment_repo.save(moment)

    async def delete_moment_photo(
        self,
        user_id: uuid.UUID,
        moment_id: uuid.UUID,
        photo_id: str,
    ) -> DailyMoment:
        moment = await self.moment_repo.get_by_id_and_user(moment_id, user_id)
        if not moment:
            raise BusinessException("今日事件不存在或无权修改", 404)
        self._ensure_moment_editable_today(moment)
        photos = list(moment.photos or [])
        kept: list[dict] = []
        removed_filename: str | None = None
        for item in photos:
            if str(item.get("id")) == photo_id:
                removed_filename = str(item.get("filename") or "")
                continue
            kept.append(item)
        if removed_filename is None:
            raise BusinessException("照片不存在", 404)
        self.moment_photos.delete_photo_file(
            user_id=user_id,
            moment_id=moment_id,
            filename=removed_filename,
        )
        moment.photos = kept
        return await self.moment_repo.save(moment)
