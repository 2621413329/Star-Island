from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class MoodIslandStyleRead(BaseModel):
    mood_id: str
    style_key: str
    config: dict[str, Any]
    version: str
    is_active: bool
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class MoodIslandStyleUpdate(BaseModel):
    style_key: str | None = Field(default=None, max_length=64)
    config: dict[str, Any] | None = None
    version: str | None = Field(default=None, max_length=16)
    is_active: bool | None = None
