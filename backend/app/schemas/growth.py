from pydantic import BaseModel, ConfigDict


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
