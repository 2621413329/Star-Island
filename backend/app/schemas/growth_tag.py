from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class GrowthTagRead(BaseModel):
    id: str
    category_id: str
    label: str
    sort_order: int
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class GrowthTagCategoryRead(BaseModel):
    id: str
    label: str
    icon: str
    color: str
    sort_order: int
    is_active: bool
    tags: list[GrowthTagRead] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)


class GrowthTagCategoryCreate(BaseModel):
    id: str = Field(min_length=2, max_length=32, pattern=r"^[a-z][a-z0-9_]*$")
    label: str = Field(min_length=1, max_length=32)
    icon: str = Field(default="label", max_length=64)
    color: str = Field(default="#78909C", max_length=16)
    sort_order: int = 0
    is_active: bool = True


class GrowthTagCategoryUpdate(BaseModel):
    label: str | None = Field(default=None, min_length=1, max_length=32)
    icon: str | None = Field(default=None, max_length=64)
    color: str | None = Field(default=None, max_length=16)
    sort_order: int | None = None
    is_active: bool | None = None


class GrowthTagCreate(BaseModel):
    label: str = Field(min_length=1, max_length=32)
    sort_order: int = 0
    is_active: bool = True


class GrowthTagUpdate(BaseModel):
    label: str | None = Field(default=None, min_length=1, max_length=32)
    sort_order: int | None = None
    is_active: bool | None = None


class MomentAnalysisResult(BaseModel):
    primary_tag: str
    secondary_tags: list[str] = Field(default_factory=list)
    emotion: str
    growth_points: list[str] = Field(default_factory=list)
    legacy_emotion_tag: str = "calm"
