from pydantic import BaseModel, ConfigDict, Field


class EmotionFragmentSummaryRead(BaseModel):
    """情绪碎片汇总：每条 daily_moment 计为一片，按 emotion_tag 聚合。"""

    total_count: int = 0
    totals: dict[str, int] = Field(default_factory=dict)


class GrowthSummaryRead(BaseModel):
    growth_value: int
    level: int
    level_title: str
    streak_days: int
    max_streak_days: int
    next_level: int | None = None
    next_level_title: str | None = None
    xp_into_level: int
    xp_for_next_level: int | None = None
    island_stage: int
    unlock_label: str
    today_mood: str | None = None
    today_weather_label: str = "☀ 平静"

    model_config = ConfigDict(from_attributes=True)
