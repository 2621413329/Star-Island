from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class I18nConfigRead(BaseModel):
    default_language: str
    supported_languages: list[str]


class I18nStringRead(BaseModel):
    id: str
    key: str
    locale: str
    value: str
    status: str
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class I18nStringCreate(BaseModel):
    key: str = Field(min_length=1, max_length=128)
    locale: str = Field(min_length=2, max_length=16)
    value: str = Field(min_length=1, max_length=1024)
    status: str = Field(default="active", pattern="^(active|draft)$")


class I18nStringUpdate(BaseModel):
    value: str | None = Field(default=None, min_length=1, max_length=1024)
    status: str | None = Field(default=None, pattern="^(active|draft)$")
