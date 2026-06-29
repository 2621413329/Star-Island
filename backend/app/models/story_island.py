import uuid
from datetime import date, datetime
from typing import Any

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Integer, String, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.database import Base


class StoryIsland(Base):
    __tablename__ = "story_islands"
    __table_args__ = (
        UniqueConstraint("user_id", "category_id", "name", name="uq_story_islands_user_category_name"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True)
    category_id: Mapped[str] = mapped_column(String(32), ForeignKey("growth_tag_categories.id", ondelete="CASCADE"), index=True)
    name: Mapped[str] = mapped_column(String(32), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    target_completion_days: Mapped[int] = mapped_column(Integer, default=90, nullable=False)
    completion_target_date: Mapped[date | None] = mapped_column(Date)
    size_kind: Mapped[str] = mapped_column(String(16), default="small", nullable=False)
    growth_value: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    cover_image_key: Mapped[str | None] = mapped_column(String(128))
    background_config: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, nullable=False)
    is_archived: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    moments = relationship("DailyMoment", back_populates="story_island")
    decor_unlocks = relationship("StoryIslandDecorUnlock", back_populates="island", cascade="all, delete-orphan")
    tasks = relationship("StoryIslandTask", back_populates="island", cascade="all, delete-orphan")


class StoryIslandDecorUnlock(Base):
    __tablename__ = "story_island_decor_unlocks"
    __table_args__ = (
        UniqueConstraint("island_id", "decor_id", name="uq_story_island_decor_unlock"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True)
    island_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("story_islands.id", ondelete="CASCADE"), index=True
    )
    decor_id: Mapped[str] = mapped_column(String(64), nullable=False)
    unlock_order: Mapped[int] = mapped_column(Integer, nullable=False)
    unlocked_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    island = relationship("StoryIsland", back_populates="decor_unlocks")


class StoryIslandTask(Base):
    __tablename__ = "story_island_tasks"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True)
    island_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("story_islands.id", ondelete="CASCADE"), index=True
    )
    title: Mapped[str] = mapped_column(String(80), nullable=False)
    is_daily: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_archived: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    island = relationship("StoryIsland", back_populates="tasks")
    completions = relationship("StoryIslandTaskCompletion", back_populates="task", cascade="all, delete-orphan")


class StoryIslandTaskCompletion(Base):
    __tablename__ = "story_island_task_completions"
    __table_args__ = (
        UniqueConstraint("task_id", "completed_on", name="uq_story_island_task_completion_day"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True)
    island_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("story_islands.id", ondelete="CASCADE"), index=True
    )
    task_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("story_island_tasks.id", ondelete="CASCADE"), index=True
    )
    completed_on: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    growth_delta: Mapped[int] = mapped_column(Integer, default=5, nullable=False)
    completed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    task = relationship("StoryIslandTask", back_populates="completions")
