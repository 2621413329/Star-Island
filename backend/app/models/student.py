import uuid
from datetime import date, datetime
from sqlalchemy import Date, DateTime, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.database import Base

class Student(Base):
    __tablename__ = "students"
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_no: Mapped[str] = mapped_column(String(64), unique=True, index=True, nullable=False)
    name: Mapped[str] = mapped_column(String(64), index=True, nullable=False)
    gender: Mapped[str | None] = mapped_column(String(16))
    birthday: Mapped[date | None] = mapped_column(Date)
    class_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("school_classes.id", ondelete="RESTRICT"), index=True
    )
    class_name: Mapped[str] = mapped_column(String(64), index=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    school_class = relationship("SchoolClass", back_populates="students")
    observations = relationship("ObservationRecord", back_populates="student", cascade="all, delete-orphan")
