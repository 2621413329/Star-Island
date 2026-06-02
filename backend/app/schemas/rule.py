import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class RuleDSL(BaseModel):
    when: dict[str, list[Any]] = Field(default_factory=dict)
    then: dict[str, Any] = Field(default_factory=dict)


class StoryRuleCreate(BaseModel):
    name: str = Field(min_length=1, max_length=128)
    description: str | None = Field(default=None, max_length=255)
    dsl: RuleDSL
    priority: int = 100
    is_active: bool = True


class StoryRuleUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=128)
    description: str | None = Field(default=None, max_length=255)
    dsl: RuleDSL | None = None
    priority: int | None = None
    is_active: bool | None = None


class StoryRuleRead(BaseModel):
    id: uuid.UUID
    name: str
    description: str | None
    dsl: dict[str, Any]
    priority: int
    is_active: bool
    created_by: uuid.UUID | None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
