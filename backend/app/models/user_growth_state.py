import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import DateTime, ForeignKey, Integer, String, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.database import Base


class UserGrowthState(Base):
    """用户成长与情绪碎片汇总快照（等级、XP、连续打卡、情绪统计）。"""

    __tablename__ = "user_growth_states"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    growth_value: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    level: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    level_title: Mapped[str] = mapped_column(String(32), default="漂流者", nullable=False)
    streak_days: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    max_streak_days: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    next_level: Mapped[int | None] = mapped_column(Integer)
    next_level_title: Mapped[str | None] = mapped_column(String(32))
    xp_into_level: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    xp_for_next_level: Mapped[int | None] = mapped_column(Integer)
    island_stage: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    unlock_label: Mapped[str] = mapped_column(String(64), default="", nullable=False)
    today_mood: Mapped[str | None] = mapped_column(String(32))
    today_weather_label: Mapped[str] = mapped_column(String(32), default="☀ 平静", nullable=False)
    emotion_fragment_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    emotion_totals: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, nullable=False)
    island_seed: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    computed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    user = relationship("User", back_populates="growth_state")
