import uuid
from datetime import date, datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class ProfileRead(BaseModel):
    user_id: uuid.UUID
    student_id: uuid.UUID | None
    gender: str | None
    companion_style: str | None
    today_mood: str | None
    onboarding_completed: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ProfileGenderUpdate(BaseModel):
    gender: str = Field(pattern="^(male|female|other)$")


class ProfileCompanionUpdate(BaseModel):
    companion_style: str = Field(pattern="^(chibi|normal)$")


class ProfileMoodUpdate(BaseModel):
    today_mood: str = Field(pattern="^(happy|calm|thinking|sad|angry)$")


class ProfileOnboardingComplete(BaseModel):
    onboarding_completed: bool = True


class DailyMomentCreate(BaseModel):
    event_tags: list[str] = Field(min_length=1, max_length=8)
    emotion_tag: str = Field(pattern="^(happy|calm|thinking|sad|angry)$")
    note: str | None = Field(default=None, max_length=200)


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
