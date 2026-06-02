import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.database import Base


class Story(Base):
    __tablename__ = "stories"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), index=True)
    source_record_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("observation_records.id", ondelete="CASCADE"), index=True
    )
    rule_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("story_rules.id"))
    template_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("story_templates.id"))
    title: Mapped[str] = mapped_column(String(128), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    emotion_flow: Mapped[list[dict[str, Any]]] = mapped_column(JSONB, default=list, nullable=False)
    sections: Mapped[list[dict[str, Any]]] = mapped_column(JSONB, default=list, nullable=False)
    scene_prompt: Mapped[str | None] = mapped_column(Text)
    image_style: Mapped[str | None] = mapped_column(String(64))
    visual_payload: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, nullable=False)
    status: Mapped[str] = mapped_column(String(32), default="generated", index=True, nullable=False)
    created_by: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    student = relationship("Student")
    source_record = relationship("ObservationRecord")
    rule = relationship("StoryRule", back_populates="stories")
    template = relationship("StoryTemplate", back_populates="stories")
    runs = relationship("StoryGenerationRun", back_populates="story", cascade="all, delete-orphan")


class StoryGenerationRun(Base):
    __tablename__ = "story_generation_runs"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    story_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("stories.id", ondelete="SET NULL"))
    record_snapshot: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    matched_rules: Mapped[list[dict[str, Any]]] = mapped_column(JSONB, default=list, nullable=False)
    plan: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, nullable=False)
    prompt: Mapped[str | None] = mapped_column(Text)
    llm_response: Mapped[str | None] = mapped_column(Text)
    error_message: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), default="success", index=True, nullable=False)
    latency_ms: Mapped[int | None] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    story = relationship("Story", back_populates="runs")
