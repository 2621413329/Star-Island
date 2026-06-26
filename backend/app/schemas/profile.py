import uuid
from datetime import date, datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.config.emotion_catalog import EMOTION_ID_PATTERN
from app.schemas.growth import EmotionFragmentSummaryRead, GrowthSummaryRead


class ProfileRead(BaseModel):
    user_id: uuid.UUID
    nickname: str | None = None
    gender: str | None
    companion_role_id: str | None = None
    companion_style: str | None
    today_mood: str | None
    onboarding_completed: bool
    app_preferences: dict[str, Any] = Field(default_factory=dict)
    created_at: datetime
    updated_at: datetime
    growth: GrowthSummaryRead | None = None
    emotion_fragments: EmotionFragmentSummaryRead | None = None

    model_config = ConfigDict(from_attributes=True)


class ProfileAppPreferencesUpdate(BaseModel):
    growth_island_rules_acknowledged: bool | None = None
    last_daily_mood_pick_date: str | None = Field(default=None, max_length=10)
    last_daily_story_prompt_date: str | None = Field(default=None, max_length=10)
    wake_time: str | None = Field(default=None, pattern=r"^\d{2}:\d{2}$")
    lunch_time: str | None = Field(default=None, pattern=r"^\d{2}:\d{2}$")
    work_end_time: str | None = Field(default=None, pattern=r"^\d{2}:\d{2}$")
    sleep_time: str | None = Field(default=None, pattern=r"^\d{2}:\d{2}$")
    reminder_morning_enabled: bool | None = None
    reminder_noon_enabled: bool | None = None
    reminder_evening_enabled: bool | None = None
    reminders_enabled: bool | None = None
    custom_reminders: list[dict[str, Any]] | None = None


class ProfileNicknameUpdate(BaseModel):
    nickname: str = Field(min_length=1, max_length=32)

    @field_validator("nickname")
    @classmethod
    def validate_nickname(cls, value: str) -> str:
        name = value.strip()
        if not name:
            raise ValueError("昵称不能为空")
        return name


class ProfileGenderUpdate(BaseModel):
    """已废弃：请使用 [ProfileCompanionRoleUpdate]。仍接受 male/female 并映射为角色 id。"""

    gender: str = Field(pattern="^(male|female|other)$")


class ProfileCompanionRoleUpdate(BaseModel):
    companion_role_id: str = Field(min_length=2, max_length=32)


class CompanionRoleRead(BaseModel):
    id: str
    display_name: str
    render_key: str

    model_config = ConfigDict(from_attributes=True)


class ProfileCompanionUpdate(BaseModel):
    companion_style: str = Field(pattern="^(chibi|normal)$")


class ProfileMoodUpdate(BaseModel):
    today_mood: str = Field(pattern=EMOTION_ID_PATTERN)


class ProfileOnboardingComplete(BaseModel):
    onboarding_completed: bool = True


MOMENT_NOTE_MAX_LENGTH = 500


class DailyMomentCreate(BaseModel):
    note: str = Field(min_length=1, max_length=MOMENT_NOTE_MAX_LENGTH)
    client_event_id: str | None = Field(default=None, min_length=8, max_length=96)
    moment_date: date | None = Field(
        default=None,
        description="补录日期；缺省为今天，不可晚于今天",
    )
    # 已废弃：服务端不再接受客户端预填标签，统一走 AI 分析
    event_tags: list[str] | None = Field(default=None, max_length=8)
    emotion_tag: str | None = Field(default=None, pattern="^(happy|calm|thinking|sad|angry)$")
    # 手动维护标签（用户编辑标签页提交时跳过 AI 打标）
    primary_tag: str | None = Field(default=None, max_length=32)
    secondary_tags: list[str] | None = Field(default=None, max_length=6)
    ai_emotion: str | None = Field(default=None, max_length=16)


class DailyMomentTagsUpdate(BaseModel):
    primary_tag: str = Field(min_length=1, max_length=32)
    secondary_tags: list[str] = Field(default_factory=list, max_length=6)
    ai_emotion: str | None = Field(default=None, max_length=16)
    emotion_tag: str | None = Field(default=None, pattern="^(happy|calm|thinking|sad|angry)$")


class WeekCheckInDayRead(BaseModel):
    date: str
    weekday_label: str
    checked_in: bool = False
    is_today: bool = False
    is_future: bool = False


class MoodReportCheckInRead(BaseModel):
    """心情上报打卡：按每日 mood-report 上传日期统计。"""

    current_streak: int = 0
    max_streak: int = 0
    total_check_in_days: int = 0
    checked_in_today: bool = False
    today_moment_count: int = 0
    reported_moment_count: int = 0
    has_pending_stories: bool = False
    all_synced_today: bool = False
    week_days: list[WeekCheckInDayRead] = Field(default_factory=list)


class DailyMoodReportUpload(BaseModel):
    category_filter: str | None = None


class MoodPeriodSummaryRead(BaseModel):
    """成长轨迹页：当前筛选周期下的总体心情总结（≤100字）。"""

    period: str
    category_filter: str | None = None
    summary: str
    ai_generated: bool = False
    total_moments: int = 0
    mood_counts: dict[str, int] = Field(default_factory=dict)
    dominant_mood: str | None = None


class DailyMoodReportRead(BaseModel):
    """心情上报结果（个人可见）。"""

    report_date: str
    category_filter: str | None
    mood_counts: dict[str, int]
    radar_scores: dict[str, float]
    moment_count: int
    insight_summary: str
    warm_suggestion: str
    concern_label: str
    ai_generated: bool
    analysis_source: str = "unknown"
    uploaded_at: str
    weekly_hint: str = ""
    weekly_trend_label: str = ""


class DailyMomentRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    event_tags: list[str]
    emotion_tag: str
    primary_tag: str | None = None
    secondary_tags: list[str] = Field(default_factory=list)
    growth_points: list[str] = Field(default_factory=list)
    ai_emotion: str | None = None
    note: str | None
    content_type: str = "text"
    voice_url: str | None = None
    voice_duration: int | None = None
    voice_size: int | None = None
    speech_status: str | None = None
    speech_text: str | None = None
    client_event_id: str | None = None
    companion_scene: str
    companion_pose: str
    visual_payload: dict[str, Any]
    photos: list[dict[str, Any]] = Field(default_factory=list)
    moment_date: date
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PaginatedDailyMomentsRead(BaseModel):
    """成长轨迹「本月 / 本年度」日常列表（服务端筛选 + 分页）。"""

    total: int
    page: int
    page_size: int
    items: list[DailyMomentRead]


class DailyMomentVoiceCreate(BaseModel):
    voice_duration: int = Field(ge=1, le=120)
    client_event_id: str | None = Field(default=None, min_length=8, max_length=96)
