from functools import lru_cache

from pydantic import AliasChoices, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "AI成长观察系统"
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
    QWEN_T2I_MODEL: str = "wan2.5-t2i-preview"
    QWEN_I2V_MODEL: str = "wan2.5-i2v-preview"
    QWEN_TASK_POLL_INTERVAL_SEC: int = 3
    QWEN_TASK_POLL_TIMEOUT_SEC: int = 300
    TEACHER_REGISTRATION_SECRET: str = "root"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", case_sensitive=True)


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
