import uuid

from fastapi import APIRouter, Depends

from app.api.deps import DBSession, get_current_user
from app.models.user import User
from app.repositories.profile_repository import DailyMomentRepository, ProfileRepository
from app.repositories.student_repository import StudentRepository
from app.schemas.common import ResponseModel
from app.schemas.profile import (
    DailyMomentCreate,
    DailyMomentRead,
    ProfileCompanionUpdate,
    ProfileGenderUpdate,
    ProfileMoodUpdate,
    ProfileRead,
)
from app.services.profile_service import ProfileService

router = APIRouter(prefix="/profile", tags=["学生资料"])


def get_profile_service(db: DBSession) -> ProfileService:
    return ProfileService(
        ProfileRepository(db),
        DailyMomentRepository(db),
        StudentRepository(db),
    )


@router.get("", response_model=ResponseModel[ProfileRead])
async def get_profile(db: DBSession, current_user: User = Depends(get_current_user)):
    service = get_profile_service(db)
    profile = await service.ensure_profile(current_user)
    return ResponseModel(data=profile)


@router.patch("/gender", response_model=ResponseModel[ProfileRead])
async def update_gender(
    payload: ProfileGenderUpdate,
    db: DBSession,
    current_user: User = Depends(get_current_user),
):
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    profile = await service.update_gender(current_user.id, payload)
    return ResponseModel(data=profile)


@router.patch("/companion", response_model=ResponseModel[ProfileRead])
async def update_companion(
    payload: ProfileCompanionUpdate,
    db: DBSession,
    current_user: User = Depends(get_current_user),
):
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    profile = await service.update_companion(current_user.id, payload)
    return ResponseModel(data=profile)


@router.patch("/mood", response_model=ResponseModel[ProfileRead])
async def update_mood(
    payload: ProfileMoodUpdate,
    db: DBSession,
    current_user: User = Depends(get_current_user),
):
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    profile = await service.update_mood(current_user.id, payload)
    return ResponseModel(data=profile)


@router.post("/onboarding/complete", response_model=ResponseModel[ProfileRead])
async def complete_onboarding(db: DBSession, current_user: User = Depends(get_current_user)):
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    profile = await service.complete_onboarding(current_user.id)
    return ResponseModel(data=profile)


@router.post("/moments", response_model=ResponseModel[DailyMomentRead])
async def create_moment(
    payload: DailyMomentCreate,
    db: DBSession,
    current_user: User = Depends(get_current_user),
):
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    moment = await service.create_moment(current_user.id, payload)
    return ResponseModel(data=moment)


@router.get("/moments/today", response_model=ResponseModel[list[DailyMomentRead]])
async def list_today_moments(db: DBSession, current_user: User = Depends(get_current_user)):
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    moments = await service.list_today_moments(current_user.id)
    return ResponseModel(data=moments)
