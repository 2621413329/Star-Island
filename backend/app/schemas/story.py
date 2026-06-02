import uuid
from datetime import date, datetime
from typing import Any

from pydantic import BaseModel, ConfigDict


class StoryGenerateRequest(BaseModel):
    observation_record_id: uuid.UUID


class StoryRead(BaseModel):
    id: uuid.UUID
    student_id: uuid.UUID
    source_record_id: uuid.UUID
    rule_id: uuid.UUID | None
    template_id: uuid.UUID | None
    title: str
    body: str
    emotion_flow: list[dict[str, Any]]
    sections: list[dict[str, Any]]
    scene_prompt: str | None
    image_style: str | None
    visual_payload: dict[str, Any]
    status: str
    created_by: uuid.UUID
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class StoryTimelineItem(BaseModel):
    type: str
    id: uuid.UUID
    student_id: uuid.UUID
    title: str
    content: str
    occurred_at: datetime


class StoryQuery(BaseModel):
    student_id: uuid.UUID
    target_date: date | None = None
