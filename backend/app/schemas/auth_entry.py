from pydantic import BaseModel, EmailStr, Field

from app.schemas.user import Token


class AuthEntryRequest(BaseModel):
    username: str = Field(min_length=3, max_length=64)
    password: str = Field(min_length=6, max_length=128)
    email: EmailStr | None = None


class AuthEntryResponse(BaseModel):
    token: Token
    is_new_user: bool
