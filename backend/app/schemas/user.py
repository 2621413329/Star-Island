import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict, EmailStr, Field
class UserCreate(BaseModel):
    username: str = Field(min_length=3, max_length=64)
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)
class UserLogin(BaseModel):
    username: str
    password: str
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
class UserRead(BaseModel):
    id: uuid.UUID
    username: str
    email: EmailStr
    is_active: bool
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)
