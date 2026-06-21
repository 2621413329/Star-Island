from functools import lru_cache

from pydantic import AliasChoices, Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "成长小岛"
    DEBUG: bool = False
    DATABASE_URL: str = Field(..., description="SQLAlchemy async database URL")
    JWT_SECRET_KEY: str = Field(..., description="JWT signing secret")
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 60 * 24
    QWEN_API_KEY: str | None = None
    QWEN_BASE_URL: str = "https://dashscope.aliyuncs.com/compatible-mode/v1"
    QWEN_DASHSCOPE_BASE_URL: str = "https://dashscope.aliyuncs.com/api/v1"
    QWEN_CHAT_MODEL: str = "qwen-plus"
    # 短交互 AI：今日心情分析、成长记录小人演出等（与故事 QWEN_CHAT_MODEL 分离）
    QWEN_FAST_MODEL: str = Field(
        default="qwen-flash",
        validation_alias=AliasChoices("QWEN_FAST_MODEL", "QWEN_MOOD_REPORT_MODEL"),
    )
    QWEN_EMBEDDING_MODEL: str = "text-embedding-v4"
    QWEN_ASR_MODEL: str = "paraformer-v2"
    QWEN_T2I_MODEL: str = "wan2.5-t2i-preview"
    QWEN_I2V_MODEL: str = "wan2.5-i2v-preview"
    QWEN_TASK_POLL_INTERVAL_SEC: int = 3
    QWEN_TASK_POLL_TIMEOUT_SEC: int = 300
    USER_MEDIA_ROOT: str = Field(
        default="data/user_media",
        description="用户上传媒体根目录（按 user_id/moments 分目录）",
    )
    DEFAULT_LANGUAGE: str = Field(
        default="zh_CN",
        description="应用默认语言（发布配置：国内 zh_CN，海外 en_US）",
    )

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", case_sensitive=True)

    @model_validator(mode="after")
    def validate_production_secrets(self) -> "Settings":
        if self.DEBUG:
            return self
        if not self.DATABASE_URL.strip():
            raise ValueError("DATABASE_URL must be configured when DEBUG=false")
        weak_jwt_values = {
            "please-change-this-secret-key-in-production",
            "change-me",
            "secret",
        }
        if self.JWT_SECRET_KEY in weak_jwt_values or len(self.JWT_SECRET_KEY) < 32:
            raise ValueError("JWT_SECRET_KEY must be a strong random value when DEBUG=false")
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
