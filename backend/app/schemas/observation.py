import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class ObservationBase(BaseModel):
    student_id: uuid.UUID
    event_type: str = Field(min_length=1, max_length=64, examples=["课堂表现"])
    event_title: str = Field(min_length=1, max_length=128)
    event_content: str = Field(min_length=1)
    emotion_tag: str | None = Field(default=None, max_length=64)
    growth_dimension: str | None = Field(default=None, max_length=64)


class ObservationCreate(ObservationBase):
    pass


class ObservationUpdate(BaseModel):
    student_id: uuid.UUID | None = None
    event_type: str | None = Field(default=None, min_length=1, max_length=64)
    event_title: str | None = Field(default=None, min_length=1, max_length=128)
    event_content: str | None = Field(default=None, min_length=1)
    emotion_tag: str | None = Field(default=None, max_length=64)
    growth_dimension: str | None = Field(default=None, max_length=64)


class ObservationRead(ObservationBase):
    id: uuid.UUID
    created_by: uuid.UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
