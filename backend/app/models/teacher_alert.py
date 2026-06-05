import uuid
from datetime import date, datetime
from typing import Any

from sqlalchemy import Date, DateTime, ForeignKey, Integer, String, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database.database import Base


class TeacherAlertInstance(Base):
    __tablename__ = "teacher_alert_instances"
    __table_args__ = (UniqueConstraint("alert_key", name="uq_teacher_alert_key"),)

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    alert_key: Mapped[str] = mapped_column(String(128), nullable=False, index=True)
    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), index=True, nullable=False
    )
    alert_type: Mapped[str] = mapped_column(String(32), nullable=False)
    report_date: Mapped[date | None] = mapped_column(Date, index=True)
    date_end: Mapped[date] = mapped_column(Date, index=True, nullable=False)
    title: Mapped[str] = mapped_column(String(64), nullable=False)
    summary: Mapped[str] = mapped_column(String(256), nullable=False)
    payload: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, nullable=False)
    priority: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    status: Mapped[str] = mapped_column(String(16), default="pending", nullable=False, index=True)
    growth_status: Mapped[str | None] = mapped_column(String(16))
    focus_tags: Mapped[list[str] | None] = mapped_column(JSONB)
    focus_directions: Mapped[list[str] | None] = mapped_column(JSONB)
    trend: Mapped[str | None] = mapped_column(String(16))
    risk_level: Mapped[str] = mapped_column(String(16), default="none", nullable=False)
    risk_reminder: Mapped[str | None] = mapped_column(String(256))
    ai_summary: Mapped[str | None] = mapped_column(String(512))
    acked_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    acked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
