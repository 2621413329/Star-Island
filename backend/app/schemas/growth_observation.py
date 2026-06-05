import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class GrowthInsightRead(BaseModel):
    status: str
    focus_tags: list[str] = []
    focus_directions: list[str] = []
    trend: str = "stable"
    summary: str = ""
    need_attention: bool = False
    risk_level: str = "none"
    risk_reminder: str | None = None


class AttentionTagRead(BaseModel):
    code: str
    label: str
    count: int = 1


class GrowthFocusRead(BaseModel):
    id: uuid.UUID
    student_id: uuid.UUID
    student_name: str | None = None
    class_name: str | None = None
    report_date: str | None = None
    date_end: str
    title: str
    growth_status: str
    summary: str
    focus_directions: list[str] = []
    focus_tags: list[str] = []
    trend: str = "stable"
    need_attention: bool = False
    risk_level: str = "none"
    risk_reminder: str | None = None
    follow_up_status: str
    acked_at: datetime | None = None
    alert_type: str


class TrendPointRead(BaseModel):
    date: str
    mood_score: float
    record_count: int


class GrowthTimelineItemRead(BaseModel):
    moment_id: uuid.UUID | None = None
    date: str
    emotion_tag: str
    category_tag: str | None = None
    category_label: str | None = None
    story_detail: str | None = None
    note: str | None = None
    note_exposed: bool = False
    can_dismiss: bool = False
    ai_tags: list[str] = []


class DangerSignalRecordRead(BaseModel):
    moment_id: uuid.UUID
    date: str
    category_tag: str | None = None
    category_label: str
    story_detail: str
    note: str
    emotion_tag: str
    can_dismiss: bool = True


class CriticalRiskFollowCreate(BaseModel):
    note: str | None = Field(default=None, max_length=2000)


class CriticalRiskFollowStateRead(BaseModel):
    moment_id: uuid.UUID
    follow_up_status: str
    follow_note: str | None = None
    followed_at: datetime | None = None


class CriticalRiskSignalRead(BaseModel):
    moment_id: uuid.UUID
    student_id: uuid.UUID
    student_name: str
    class_name: str
    report_date: str
    category_label: str
    story_detail: str
    note_preview: str
    emotion_tag: str
    risk_reminder: str
    follow_up_status: str = "pending"
    follow_note: str | None = None
    followed_at: datetime | None = None


class CriticalRiskDetailRead(BaseModel):
    moment_id: uuid.UUID
    student_id: uuid.UUID
    student_name: str
    class_name: str
    report_date: str
    emotion_tag: str
    category_label: str
    detail_tags: list[str] = []
    story_detail: str
    note: str
    companion_scene: str
    companion_scene_label: str = ""
    created_at: datetime
    can_dismiss: bool = True
    risk_reminder: str
    follow_up_status: str = "pending"
    follow_note: str | None = None
    followed_at: datetime | None = None


class RiskExposureRead(BaseModel):
    moment_id: uuid.UUID
    date: str
    emotion_tag: str
    note: str
    can_dismiss: bool = True


class RiskDismissRead(BaseModel):
    student_id: uuid.UUID
    moment_id: uuid.UUID
    report_date: str
    risk_level: str
    risk_reminder: str | None = None


class TeacherFollowUpRead(BaseModel):
    id: uuid.UUID
    action: str
    note: str | None = None
    created_at: datetime


class TeacherFollowUpCreate(BaseModel):
    action: str = Field(pattern="^(communicated|contacted_parent|referred_counselor|observing)$")
    note: str | None = Field(default=None, max_length=2000)


class GrowthDayRecordRead(BaseModel):
    date: str
    ai_summary: str
    insight: GrowthInsightRead
    moment_count: int = 0
    mood_counts: dict[str, int] = {}
    category_breakdown: dict[str, int] = {}
    mood_score: float | None = None
    has_report: bool = False
    danger_records: list[DangerSignalRecordRead] = []
    entries: list[GrowthTimelineItemRead] = []


class GrowthArchiveRead(BaseModel):
    student_id: uuid.UUID
    student_name: str
    class_name: str
    ai_summary: str
    insight: GrowthInsightRead
    trend_metric_label: str = ""
    trend_points: list[TrendPointRead]
    mood_counts: dict[str, int]
    category_breakdown: dict[str, int]
    mood_counts_by_category: dict[str, dict[str, int]] = {}
    attention_tags: list[AttentionTagRead]
    daily_records: list[GrowthDayRecordRead] = []
    timeline: list[GrowthTimelineItemRead] = []
    risk_exposures: list[RiskExposureRead] = []
    follow_ups: list[TeacherFollowUpRead]
