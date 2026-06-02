import uuid
from datetime import datetime
from sqlalchemy import DateTime, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.database import Base

class ObservationRecord(Base):
    __tablename__ = "observation_records"
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), index=True)
    event_type: Mapped[str] = mapped_column(String(64), index=True, nullable=False)
    event_title: Mapped[str] = mapped_column(String(128), nullable=False)
    event_content: Mapped[str] = mapped_column(Text, nullable=False)
    emotion_tag: Mapped[str | None] = mapped_column(String(64))
    growth_dimension: Mapped[str | None] = mapped_column(String(64), index=True)
    created_by: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    student = relationship("Student", back_populates="observations")
    creator = relationship("User", back_populates="observations")
