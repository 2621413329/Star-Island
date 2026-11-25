import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database.database import Base


class IslandPolaroid(Base):
    """一座岛升一级时留下的拍立得。正面可分享，背面只给本人。"""

    __tablename__ = "island_polaroids"
    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "island_id",
            "level",
            name="uq_island_polaroids_user_island_level",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    island_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("story_islands.id", ondelete="CASCADE"), index=True, nullable=False
    )
    island_kind: Mapped[str] = mapped_column(String(16), nullable=False)
    level: Mapped[int] = mapped_column(Integer, nullable=False)
    building_name: Mapped[str] = mapped_column(String(64), nullable=False)
    asset_key: Mapped[str] = mapped_column(String(128), default="", nullable=False)
    category_id: Mapped[str] = mapped_column(String(32), default="", nullable=False)
    companion_role: Mapped[str] = mapped_column(String(32), default="", nullable=False)
    skin_id: Mapped[str] = mapped_column(String(32), default="plain", nullable=False)
    taken_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    front_caption: Mapped[str] = mapped_column(String(80), nullable=False)
    back_summary: Mapped[str | None] = mapped_column(Text)
    back_status: Mapped[str] = mapped_column(String(16), default="fallback", nullable=False)
    captured_live: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    source_moments: Mapped[list[dict[str, Any]]] = mapped_column(JSONB, default=list, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
