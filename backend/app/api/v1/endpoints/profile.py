import uuid
from datetime import date

from fastapi import APIRouter, Depends, Query

from app.api.deps import DBSession, get_current_user
from app.models.user import User
from app.repositories.daily_mood_report_repository import DailyMoodReportRepository
from app.repositories.profile_repository import DailyMomentRepository, ProfileRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.user_growth_state_repository import UserGrowthStateRepository
from app.schemas.common import ResponseModel
from app.schemas.growth import EmotionFragmentSummaryRead, GrowthSummaryRead
from app.schemas.profile import (
    DailyMomentCreate,
    DailyMomentRead,
    DailyMoodReportRead,
    DailyMoodReportUpload,
    MoodReportCheckInRead,
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
        mood_report_repo=DailyMoodReportRepository(db),
        growth_state_repo=UserGrowthStateRepository(db),
    )


@router.get("", response_model=ResponseModel[ProfileRead])
async def get_profile(db: DBSession, current_user: User = Depends(get_current_user)):
    service = get_profile_service(db)
    profile = await service.ensure_profile(current_user)
    return ResponseModel(data=await service.to_profile_read(profile, current_user))


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


@router.get("/emotion-fragments", response_model=ResponseModel[EmotionFragmentSummaryRead])
async def get_emotion_fragments(
    db: DBSession,
    current_user: User = Depends(get_current_user),
):
    """情绪碎片汇总：每条 daily_moment 为一片，统计总数与各情绪占比。"""
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    state = await service.refresh_growth_state(current_user.id)
    if not state:
        return ResponseModel(data=EmotionFragmentSummaryRead())
    return ResponseModel(
        data=EmotionFragmentSummaryRead(
            total_count=state.emotion_fragment_count,
            totals=dict(state.emotion_totals or {}),
        )
    )


@router.get("/growth-summary", response_model=ResponseModel[GrowthSummaryRead])
async def get_growth_summary(
    db: DBSession,
    current_user: User = Depends(get_current_user),
    days: int = Query(default=365, ge=30, le=730),
):
    """成长值、等级、连续天数与岛屿阶段（按规则汇总，防刷分）。"""
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    data = await service.get_growth_summary(current_user.id, days=days)
    return ResponseModel(data=data)


@router.get("/moments/dates", response_model=ResponseModel[list[str]])
async def list_moment_dates(
    db: DBSession,
    current_user: User = Depends(get_current_user),
    days: int = Query(default=90, ge=1, le=365),
):
    """有故事记录的日期列表（ISO 日期，新 → 旧）。"""
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    dates = await service.list_moment_dates(current_user.id, days=days)
    return ResponseModel(data=[d.isoformat() for d in dates])


@router.get("/moments/today", response_model=ResponseModel[list[DailyMomentRead]])
async def list_today_moments(db: DBSession, current_user: User = Depends(get_current_user)):
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    moments = await service.list_today_moments(current_user.id)
    return ResponseModel(data=moments)


@router.get("/moments", response_model=ResponseModel[list[DailyMomentRead]])
async def list_moments(
    db: DBSession,
    current_user: User = Depends(get_current_user),
    moment_date: date | None = Query(default=None, alias="date", description="指定某一天；缺省为今天"),
    days: int | None = Query(default=None, ge=1, le=365, description="最近 N 天（与 date 互斥）"),
):
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    if moment_date is not None:
        moments = await service.list_moments_for_date(current_user.id, moment_date)
    elif days is not None:
        moments = await service.list_moments(current_user.id, days=days)
    else:
        moments = await service.list_today_moments(current_user.id)
    return ResponseModel(data=moments)


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


@router.get("/mood-report/check-in", response_model=ResponseModel[MoodReportCheckInRead])
async def get_mood_report_check_in(
    db: DBSession,
    current_user: User = Depends(get_current_user),
    days: int = Query(default=365, ge=30, le=730),
):
    """连续上传心情打卡：按每日 mood-report 统计。"""
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    data = await service.get_mood_report_check_in(current_user.id, days=days)
    return ResponseModel(data=MoodReportCheckInRead(**data))


@router.post("/mood-report/upload", response_model=ResponseModel[DailyMoodReportRead])
async def upload_daily_mood_report(
    payload: DailyMoodReportUpload,
    db: DBSession,
    current_user: User = Depends(get_current_user),
):
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    report = await service.upload_daily_mood_report(current_user.id, payload)
    return ResponseModel(data=DailyMoodReportRead(**report), message="已为你记下今天的情绪概况")


@router.get("/growth-observation", response_model=ResponseModel[StudentGrowthObservationRead])
async def get_student_growth_observation(
    db: DBSession,
    current_user: User = Depends(get_current_user),
    days: int = Query(default=7, ge=3, le=30),
):
    """学生端本周成长观察轻量摘要（不含风险等级与教师用语）。"""
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    data = await service.get_student_growth_observation(current_user.id, days=days)
    return ResponseModel(data=StudentGrowthObservationRead(**data))


@router.patch("/moments/{moment_id}", response_model=ResponseModel[DailyMomentRead])
async def update_moment(
    moment_id: uuid.UUID,
    payload: DailyMomentCreate,
    db: DBSession,
    current_user: User = Depends(get_current_user),
):
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    moment = await service.update_moment(current_user.id, moment_id, payload)
    return ResponseModel(data=moment, message="故事已更新")


@router.delete("/moments/{moment_id}", response_model=ResponseModel[None])
async def delete_moment(
    moment_id: uuid.UUID,
    db: DBSession,
    current_user: User = Depends(get_current_user),
):
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    await service.delete_moment(current_user.id, moment_id)
    return ResponseModel(data=None, message="删除成功")
