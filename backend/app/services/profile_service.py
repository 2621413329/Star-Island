import uuid
from datetime import date

from app.exceptions.business import BusinessException
from app.models.profile import DailyMoment, UserProfile
from app.models.student import Student
from app.models.user import User
from app.repositories.profile_repository import DailyMomentRepository, ProfileRepository
from app.repositories.student_repository import StudentRepository
from app.schemas.profile import (
    DailyMomentCreate,
    ProfileCompanionUpdate,
    ProfileGenderUpdate,
    ProfileMoodUpdate,
)
from app.services.companion_action_ai_service import CompanionActionAIService
from app.services.companion_scene_service import CompanionSceneService


class ProfileService:
    def __init__(
        self,
        profile_repo: ProfileRepository,
        moment_repo: DailyMomentRepository,
        student_repo: StudentRepository,
        scene_service: CompanionSceneService | None = None,
        action_ai: CompanionActionAIService | None = None,
    ):
        self.profile_repo = profile_repo
        self.moment_repo = moment_repo
        self.student_repo = student_repo
        self.scene_service = scene_service or CompanionSceneService()
        self.action_ai = action_ai or CompanionActionAIService()

    async def ensure_profile(self, user: User) -> UserProfile:
        profile = await self.profile_repo.get_by_user_id(user.id)
        if profile:
            return profile
        student = Student(
            student_no=f"U{user.id.hex[:10]}",
            name=user.username,
            class_name="成长小岛",
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

    async def update_gender(self, user_id: uuid.UUID, payload: ProfileGenderUpdate) -> UserProfile:
        profile = await self.get_profile(user_id)
        profile.gender = payload.gender
        if profile.student_id:
            student = await self.student_repo.get_by_id(profile.student_id)
            if student:
                student.gender = payload.gender
                await self.student_repo.update(student)
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

    async def list_today_moments(self, user_id: uuid.UUID) -> list[DailyMoment]:
        return await self.moment_repo.list_by_user_and_date(user_id, date.today())
