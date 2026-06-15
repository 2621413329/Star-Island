from pydantic import BaseModel, Field


class WeeklySummaryRead(BaseModel):
    weekly_hint: str = ""
    trend_label: str = "稳定"
    disclaimer: str = ""
