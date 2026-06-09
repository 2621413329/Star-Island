import uuid
from datetime import date, datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.growth import EmotionFragmentSummaryRead, GrowthSummaryRead


class ProfileRead(BaseModel):
    user_id: uuid.UUID
    student_id: uuid.UUID | None
    nickname: str | None = None
    class_name: str | None = None
    gender: str | None
    companion_style: str | None
    today_mood: str | None
    onboarding_completed: bool
    created_at: datetime
    updated_at: datetime
    growth: GrowthSummaryRead | None = None
    emotion_fragments: EmotionFragmentSummaryRead | None = None

    model_config = ConfigDict(from_attributes=True)


class ProfileGenderUpdate(BaseModel):
    gender: str = Field(pattern="^(male|female|other)$")


class ProfileCompanionUpdate(BaseModel):
    companion_style: str = Field(pattern="^(chibi|normal)$")


class ProfileMoodUpdate(BaseModel):
    today_mood: str = Field(pattern="^(happy|calm|thinking|sad|angry)$")


class ProfileOnboardingComplete(BaseModel):
    onboarding_completed: bool = True


MOMENT_NOTE_MAX_LENGTH = 500


class DailyMomentCreate(BaseModel):
    event_tags: list[str] = Field(min_length=1, max_length=8)
    emotion_tag: str = Field(pattern="^(happy|calm|thinking|sad|angry)$")
    note: str | None = Field(default=None, max_length=MOMENT_NOTE_MAX_LENGTH)


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


class DailyMoodReportRead(BaseModel):
    """学生端上传结果：不含原文备注与教师专用脱敏字段。"""

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


class TeacherDailyMoodReportRead(BaseModel):
    """教师端：客观统计与观察记录，不可见学生原文与柔和文案。"""

    user_id: uuid.UUID
    student_id: uuid.UUID | None
    student_name: str | None
    class_name: str | None = None
    report_date: str
    mood_counts: dict[str, int]
    teacher_radar_scores: dict[str, float]
    category_breakdown: dict[str, int]
    moment_count: int
    concern_level: str
    concern_label: str
    risk_flags: list[str]
    attention_highlights: list[str]
    fuzzy_analysis: str
    uploaded_at: datetime
    risk_exposures: list[dict] = []


class DailyMomentRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    student_id: uuid.UUID | None
    event_tags: list[str]
    emotion_tag: str
    note: str | None
    companion_scene: str
    companion_pose: str
    visual_payload: dict[str, Any]
    moment_date: date
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
