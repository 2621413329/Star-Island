import uuid
from datetime import date

from fastapi import APIRouter, Depends, File, Form, Query, UploadFile

from app.api.deps import DBSession, get_current_user
from app.models.user import User
from app.repositories.daily_mood_report_repository import DailyMoodReportRepository
from app.repositories.profile_repository import DailyMomentRepository, ProfileRepository
from app.repositories.growth_tag_repository import GrowthTagRepository
from app.repositories.user_building_unlock_repository import UserBuildingUnlockRepository
from app.repositories.user_growth_state_repository import UserGrowthStateRepository
from app.repositories.user_repository import UserRepository
from app.schemas.common import ResponseModel
from app.schemas.growth import BuildingUnlockRead, EmotionFragmentSummaryRead, GrowthSummaryRead
from app.schemas.growth_observation import WeeklySummaryRead
from app.schemas.profile import (
    CompanionRoleRead,
    DailyMomentCreate,
    DailyMomentRead,
    DailyMomentVoiceCreate,
    DailyMomentTagsUpdate,
    DailyMoodReportRead,
    DailyMoodReportUpload,
    MoodPeriodSummaryRead,
    MoodReportCheckInRead,
    PaginatedDailyMomentsRead,
    ProfileCompanionRoleUpdate,
    ProfileCompanionUpdate,
    ProfileGenderUpdate,
    ProfileMoodUpdate,
    ProfileNicknameUpdate,
    ProfileRead,
    ProfileAppPreferencesUpdate,
    SpeechTranscriptionRead,
)
from app.services.profile_service import ProfileService

router = APIRouter(prefix="/profile", tags=["个人资料"])


def get_profile_service(db: DBSession) -> ProfileService:
    return ProfileService(
        ProfileRepository(db),
        DailyMomentRepository(db),
        mood_report_repo=DailyMoodReportRepository(db),
        growth_state_repo=UserGrowthStateRepository(db),
        building_unlock_repo=UserBuildingUnlockRepository(db),
        growth_tag_repo=GrowthTagRepository(db),
        user_repo=UserRepository(db),
    )


@router.get("", response_model=ResponseModel[ProfileRead])
async def get_profile(db: DBSession, current_user: User = Depends(get_current_user)):
    service = get_profile_service(db)
    profile = await service.ensure_profile(current_user)
    return ResponseModel(data=await service.to_profile_read(profile, current_user))


@router.patch("/nickname", response_model=ResponseModel[ProfileRead])
async def update_nickname(
    payload: ProfileNicknameUpdate,
    db: DBSession,
    current_user: User = Depends(get_current_user),
):
    service = get_profile_service(db)
    profile = await service.ensure_profile(current_user)
    await service.update_nickname(current_user, payload)
    return ResponseModel(
        data=await service.to_profile_read(profile, current_user),
        message="昵称已更新",
    )


@router.get("/companion-roles", response_model=ResponseModel[list[CompanionRoleRead]])
async def list_companion_roles():
    """可选登岛伙伴角色列表。"""
    items = ProfileService.list_companion_roles()
    return ResponseModel(data=[CompanionRoleRead(**item) for item in items])


@router.patch("/companion-role", response_model=ResponseModel[ProfileRead])
async def update_companion_role(
    payload: ProfileCompanionRoleUpdate,
    db: DBSession,
    current_user: User = Depends(get_current_user),
):
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    profile = await service.update_companion_role(current_user.id, payload)
    return ResponseModel(
        data=await service.to_profile_read(profile, current_user),
        message="角色已更新",
    )


@router.patch("/gender", response_model=ResponseModel[ProfileRead])
async def update_gender(
    payload: ProfileGenderUpdate,
    db: DBSession,
    current_user: User = Depends(get_current_user),
):
    """兼容旧客户端：male/female 会映射为 companion_role_id。"""
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    profile = await service.update_gender(current_user.id, payload)
    return ResponseModel(
        data=await service.to_profile_read(profile, current_user),
        message="角色已更新",
    )


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


@router.patch("/app-preferences", response_model=ResponseModel[ProfileRead])
async def update_app_preferences(
    payload: ProfileAppPreferencesUpdate,
    db: DBSession,
    current_user: User = Depends(get_current_user),
):
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    profile = await service.update_app_preferences(current_user.id, payload)
    return ResponseModel(
        data=await service.to_profile_read(profile, current_user),
        message="偏好已保存",
    )


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


@router.get("/building-unlocks", response_model=ResponseModel[list[BuildingUnlockRead]])
async def list_building_unlocks(
    db: DBSession,
    current_user: User = Depends(get_current_user),
):
    """用户已解锁建筑及首次获得时间。"""
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    data = await service.get_building_unlocks(current_user.id)
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


@router.post("/moments/voice/transcribe", response_model=ResponseModel[SpeechTranscriptionRead])
@router.post("/speech/transcribe", response_model=ResponseModel[SpeechTranscriptionRead])
async def transcribe_speech_note(
    db: DBSession,
    current_user: User = Depends(get_current_user),
    file: UploadFile = File(..., description="语音文件（m4a）"),
    voice_duration: int = Form(..., ge=1, le=120, description="录音时长（秒）"),
):
    """文字记录按住说话：上传录音并转写为文本，不创建日常。"""
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    text = await service.transcribe_speech_note(
        current_user.id,
        file,
        voice_duration=voice_duration,
    )
    return ResponseModel(data=SpeechTranscriptionRead(text=text))


@router.post("/moments/voice", response_model=ResponseModel[DailyMomentRead])
async def create_voice_moment(
    db: DBSession,
    current_user: User = Depends(get_current_user),
    file: UploadFile = File(..., description="语音文件（m4a）"),
    voice_duration: int = Form(..., ge=1, le=120, description="录音时长（秒）"),
    client_event_id: str | None = Form(default=None),
):
    """上传语音并创建故事（异步转写供 AI 分析，默认不向用户展示转写文本）。"""
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    payload = DailyMomentVoiceCreate(
        voice_duration=voice_duration,
        client_event_id=client_event_id,
    )
    moment = await service.create_voice_moment(
        current_user.id,
        file,
        voice_duration=payload.voice_duration,
        client_event_id=payload.client_event_id,
    )
    return ResponseModel(data=moment, message="语音记录已保存")


@router.patch("/moments/{moment_id}/voice", response_model=ResponseModel[DailyMomentRead])
async def replace_voice_moment(
    moment_id: uuid.UUID,
    db: DBSession,
    current_user: User = Depends(get_current_user),
    file: UploadFile = File(..., description="语音文件（m4a）"),
    voice_duration: int = Form(..., ge=1, le=120, description="录音时长（秒）"),
):
    """替换已有语音日常的录音并重新触发转写与 AI 分析。"""
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    moment = await service.replace_voice_moment(
        current_user.id,
        moment_id,
        file,
        voice_duration=voice_duration,
    )
    return ResponseModel(data=moment, message="语音已更新")


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


@router.get("/mood-period-summary", response_model=ResponseModel[MoodPeriodSummaryRead])
async def get_mood_period_summary(
    db: DBSession,
    current_user: User = Depends(get_current_user),
    period: str = Query(default="today", pattern="^(today|week|month|year)$"),
    category_filter: str | None = Query(default=None, max_length=32),
):
    """当前筛选周期下的总体心情总结（聚合统计 + 可选 AI，约 100 字完整展示）。"""
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    data = await service.get_mood_period_summary(
        current_user.id,
        period=period,
        category_filter=category_filter,
    )
    return ResponseModel(data=MoodPeriodSummaryRead(**data))


@router.get(
    "/moments/mood-period",
    response_model=ResponseModel[PaginatedDailyMomentsRead],
)
async def list_mood_period_moments(
    db: DBSession,
    current_user: User = Depends(get_current_user),
    period: str = Query(..., pattern="^(month|year)$"),
    category_filter: str | None = Query(default=None, max_length=32),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=10, ge=1, le=50),
):
    """成长轨迹「本月 / 本年度」：服务端标签筛选 + 分页。"""
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    data = await service.list_mood_period_moments(
        current_user.id,
        period=period,
        category_filter=category_filter,
        page=page,
        page_size=page_size,
    )
    return ResponseModel(
        data=PaginatedDailyMomentsRead(
            total=data["total"],
            page=data["page"],
            page_size=data["page_size"],
            items=[DailyMomentRead.model_validate(item) for item in data["items"]],
        )
    )


@router.get("/mood-reports", response_model=ResponseModel[list[DailyMoodReportRead]])
async def list_mood_reports(
    db: DBSession,
    current_user: User = Depends(get_current_user),
    period: str = Query(default="today", pattern="^(today|week|month|year)$"),
):
    """按周期列出已上传的心情 AI 总结。"""
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    items = await service.list_mood_reports_for_period(
        current_user.id, period=period
    )
    return ResponseModel(data=[DailyMoodReportRead(**item) for item in items])


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


@router.get("/growth-observation", response_model=ResponseModel[WeeklySummaryRead])
async def get_weekly_summary(
    db: DBSession,
    current_user: User = Depends(get_current_user),
    days: int = Query(default=7, ge=3, le=30),
):
    """本周小结：基于个人心情记录的轻量提示。"""
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    data = await service.get_weekly_summary(current_user.id, days=days)
    return ResponseModel(data=WeeklySummaryRead(**data))


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
    return ResponseModel(data=moment, message="日常已更新")


@router.patch("/moments/{moment_id}/tags", response_model=ResponseModel[DailyMomentRead])
async def update_moment_tags(
    moment_id: uuid.UUID,
    payload: DailyMomentTagsUpdate,
    db: DBSession,
    current_user: User = Depends(get_current_user),
):
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    moment = await service.update_moment_tags(current_user.id, moment_id, payload)
    return ResponseModel(data=moment, message="标签已更新")


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


@router.post("/moments/{moment_id}/photos", response_model=ResponseModel[DailyMomentRead])
async def upload_moment_photo(
    moment_id: uuid.UUID,
    db: DBSession,
    current_user: User = Depends(get_current_user),
    file: UploadFile = File(..., description="故事照片"),
):
    """上传故事照片（不参与 AI 分析，仅存储）。"""
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    moment = await service.upload_moment_photo(current_user.id, moment_id, file)
    return ResponseModel(data=moment, message="照片已上传")


@router.delete(
    "/moments/{moment_id}/photos/{photo_id}",
    response_model=ResponseModel[DailyMomentRead],
)
async def delete_moment_photo(
    moment_id: uuid.UUID,
    photo_id: str,
    db: DBSession,
    current_user: User = Depends(get_current_user),
):
    service = get_profile_service(db)
    await service.ensure_profile(current_user)
    moment = await service.delete_moment_photo(current_user.id, moment_id, photo_id)
    return ResponseModel(data=moment, message="照片已删除")
