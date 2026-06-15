import uuid
from datetime import date, datetime
from typing import Any

from sqlalchemy import Date, DateTime, ForeignKey, String, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database.database import Base


class DailyMoodReport(Base):
    """用户今日心情上报。"""

    __tablename__ = "daily_mood_reports"
    __table_args__ = (
        UniqueConstraint("user_id", "report_date", name="uq_daily_mood_reports_user_date"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    report_date: Mapped[date] = mapped_column(Date, index=True, nullable=False)
    category_filter: Mapped[str | None] = mapped_column(String(16))
    moment_count: Mapped[int] = mapped_column(default=0, nullable=False)
    mood_counts: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, nullable=False)
    radar_scores: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, nullable=False)
    category_breakdown: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, nullable=False)
    concern_level: Mapped[str] = mapped_column(String(16), default="normal", nullable=False)
    risk_flags: Mapped[list[str]] = mapped_column(JSONB, default=list, nullable=False)
    attention_highlights: Mapped[list[str]] = mapped_column(JSONB, default=list, nullable=False)
    insight_summary: Mapped[str] = mapped_column(String(512), nullable=False)
    warm_suggestion: Mapped[str] = mapped_column(String(512), nullable=False)
    ai_generated: Mapped[bool] = mapped_column(default=False, nullable=False)
    growth_insight: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, nullable=False)
    growth_observation: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, nullable=False)
    dismissed_risk_moment_ids: Mapped[list[str]] = mapped_column(JSONB, default=list, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
