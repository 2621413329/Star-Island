import uuid
from datetime import date, datetime
from pydantic import BaseModel, ConfigDict, Field
class StudentBase(BaseModel):
    student_no: str = Field(min_length=1, max_length=64)
    name: str = Field(min_length=1, max_length=64)
    gender: str | None = Field(default=None, max_length=16)
    birthday: date | None = None
    class_name: str = Field(min_length=1, max_length=64)
class StudentCreate(StudentBase):
    pass
class StudentUpdate(BaseModel):
    student_no: str | None = Field(default=None, min_length=1, max_length=64)
    name: str | None = Field(default=None, min_length=1, max_length=64)
    gender: str | None = Field(default=None, max_length=16)
    birthday: date | None = None
    class_name: str | None = Field(default=None, min_length=1, max_length=64)
class StudentRead(StudentBase):
    id: uuid.UUID
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)
