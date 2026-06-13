import uuid
from datetime import date, datetime
from typing import Any

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.database import Base


class UserProfile(Base):
    __tablename__ = "user_profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    student_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("students.id", ondelete="SET NULL"), index=True
    )
    class_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("school_classes.id", ondelete="RESTRICT"), index=True
    )
    class_name: Mapped[str | None] = mapped_column(String(64), index=True)
    gender: Mapped[str | None] = mapped_column(String(16))
    companion_role_id: Mapped[str | None] = mapped_column(
        String(32), ForeignKey("companion_roles.id", ondelete="SET NULL"), index=True
    )
    companion_style: Mapped[str | None] = mapped_column(String(16))
    today_mood: Mapped[str | None] = mapped_column(String(32))
    onboarding_completed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    app_preferences: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    user = relationship("User", back_populates="profile")
    student = relationship("Student")
    school_class = relationship("SchoolClass")


class DailyMoment(Base):
    __tablename__ = "daily_moments"
    __table_args__ = (
        UniqueConstraint("user_id", "client_event_id", name="uq_daily_moments_user_client_event"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True)
    student_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("students.id", ondelete="SET NULL")
    )
    event_tags: Mapped[list[str]] = mapped_column(JSONB, default=list, nullable=False)
    emotion_tag: Mapped[str] = mapped_column(String(32), nullable=False)
    note: Mapped[str | None] = mapped_column(Text)
    client_event_id: Mapped[str | None] = mapped_column(String(96), nullable=True)
    companion_scene: Mapped[str] = mapped_column(String(128), nullable=False)
    companion_pose: Mapped[str] = mapped_column(String(32), default="breathing", nullable=False)
    visual_payload: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, nullable=False)
    moment_date: Mapped[date] = mapped_column(Date, index=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    user = relationship("User", back_populates="daily_moments")
