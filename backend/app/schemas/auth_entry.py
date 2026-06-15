from pydantic import BaseModel, EmailStr, Field, field_validator

from app.schemas.user import Token


class AuthEntryRequest(BaseModel):
    username: str = Field(min_length=3, max_length=64)
    password: str = Field(min_length=6, max_length=128)
    email: EmailStr | None = None


class AuthEntryResponse(BaseModel):
    token: Token
    is_new_user: bool


class UserRegisterRequest(BaseModel):
    """用户注册：登录用用户名，展示用昵称。"""

    username: str = Field(min_length=3, max_length=64)
    password: str = Field(min_length=6, max_length=128)
    nickname: str = Field(min_length=1, max_length=32)

    @field_validator("nickname")
    @classmethod
    def validate_nickname(cls, value: str) -> str:
        name = value.strip()
        if not name:
            raise ValueError("昵称不能为空")
        return name
