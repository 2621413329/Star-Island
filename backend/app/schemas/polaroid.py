import uuid
from datetime import date, datetime

from pydantic import BaseModel, Field


class PolaroidSourceMomentRead(BaseModel):
    id: uuid.UUID
    moment_date: date
    excerpt: str


class IslandPolaroidRead(BaseModel):
    id: uuid.UUID
    island_id: uuid.UUID
    island_kind: str
    island_name: str
    level: int
    building_name: str
    asset_key: str
    category_id: str
    companion_role: str
    skin_id: str
    taken_at: datetime
    front_caption: str
    back_summary: str | None = None
    back_status: str
    captured_live: bool
    source_moments: list[PolaroidSourceMomentRead] = Field(default_factory=list)
