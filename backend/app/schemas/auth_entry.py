from pydantic import BaseModel, EmailStr, Field, field_validator

from app.core.school_classes import DEFAULT_CLASS_NAME
from app.schemas.user import Token


class AuthEntryRequest(BaseModel):
    username: str = Field(min_length=3, max_length=64)
    password: str = Field(min_length=6, max_length=128)
    email: EmailStr | None = None


class AuthEntryResponse(BaseModel):
    token: Token
    is_new_user: bool


class StudentAuthRequest(BaseModel):
    """学生端登录字段（用户名 + 密码 + 班级同步）。"""

    username: str = Field(min_length=3, max_length=64)
    password: str = Field(min_length=6, max_length=128)
    class_name: str = Field(default=DEFAULT_CLASS_NAME, min_length=1, max_length=64)

    @field_validator("class_name")
    @classmethod
    def validate_class_name(cls, value: str) -> str:
        name = value.strip()
        if not name:
            raise ValueError("请选择班级")
        return name


class StudentRegisterRequest(BaseModel):
    """学生端注册：登录用用户名，展示用昵称。"""

    username: str = Field(min_length=3, max_length=64)
    password: str = Field(min_length=6, max_length=128)
    nickname: str = Field(min_length=1, max_length=32)
    class_name: str = Field(default=DEFAULT_CLASS_NAME, min_length=1, max_length=64)

    @field_validator("nickname")
    @classmethod
    def validate_nickname(cls, value: str) -> str:
        name = value.strip()
        if not name:
            raise ValueError("昵称不能为空")
        return name

    @field_validator("class_name")
    @classmethod
    def validate_register_class_name(cls, value: str) -> str:
        name = value.strip()
        if not name:
            raise ValueError("请选择班级")
        return name


class ClassListResponse(BaseModel):
    default_class: str
    classes: list[str]


class TeacherRegisterRequest(BaseModel):
    username: str = Field(min_length=3, max_length=64)
    password: str = Field(min_length=6, max_length=128)
    nickname: str = Field(min_length=1, max_length=32)
    registration_secret: str = Field(min_length=1, max_length=128)
    class_name: str = Field(default=DEFAULT_CLASS_NAME, min_length=1, max_length=64)

    @field_validator("nickname")
    @classmethod
    def validate_teacher_nickname(cls, value: str) -> str:
        name = value.strip()
        if not name:
            raise ValueError("昵称不能为空")
        return name

    @field_validator("class_name")
    @classmethod
    def validate_class_name(cls, value: str) -> str:
        name = value.strip()
        if not name:
            raise ValueError("请选择班级")
        return name


class TeacherLoginRequest(BaseModel):
    username: str = Field(min_length=3, max_length=64)
    password: str = Field(min_length=6, max_length=128)


class TeacherProfileRead(BaseModel):
    username: str
    nickname: str
    class_name: str
