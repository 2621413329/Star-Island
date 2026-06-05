import uuid
from datetime import date, datetime
from typing import Any

from pydantic import BaseModel, Field


class TeacherAlertRead(BaseModel):
    id: uuid.UUID
    alert_key: str
    student_id: uuid.UUID
    student_name: str | None = None
    class_name: str | None = None
    alert_type: str
    report_date: str | None
    date_end: str
    title: str
    summary: str
    payload: dict[str, Any]
    priority: int
    status: str
    acked_at: datetime | None = None


class TeacherAlertAckResponse(BaseModel):
    id: uuid.UUID
    status: str
    acked_at: datetime | None = None
