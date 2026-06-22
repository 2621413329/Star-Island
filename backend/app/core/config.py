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
    # 语音 ASR 需 DashScope 能访问的公网 URL；生产环境填 API 根地址，如 https://api.example.com
    PUBLIC_API_BASE_URL: str | None = None
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
    REDIS_URL: str = Field(
        default="redis://127.0.0.1:6379/0",
        description="Redis 连接串，用于认证限流与登录失败锁定",
    )
    REDIS_MAX_CONNECTIONS: int = Field(
        default=20,
        description="Redis 连接池最大连接数",
    )
    RATE_LIMIT_ENABLED: bool = Field(
        default=True,
        description="是否启用 Redis 认证限流（开发环境无 Redis 时可设为 false）",
    )
    AUTH_LOGIN_IP_LIMIT: int = Field(
        default=10,
        description="同一 IP 每分钟允许的登录相关请求次数",
    )
    AUTH_LOGIN_IP_WINDOW_SEC: int = Field(
        default=60,
        description="登录 IP 限流窗口（秒）",
    )
    AUTH_LOGIN_USER_LIMIT: int = Field(
        default=5,
        description="同一用户名每分钟允许的登录尝试次数",
    )
    AUTH_LOGIN_USER_WINDOW_SEC: int = Field(
        default=60,
        description="登录用户名限流窗口（秒）",
    )
    AUTH_REGISTER_IP_LIMIT: int = Field(
        default=3,
        description="同一 IP 每小时允许的注册次数",
    )
    AUTH_REGISTER_IP_WINDOW_SEC: int = Field(
        default=3600,
        description="注册 IP 限流窗口（秒）",
    )
    AUTH_LOGIN_FAIL_LOCK_COUNT: int = Field(
        default=5,
        description="连续登录失败多少次后锁定账号",
    )
    AUTH_LOGIN_FAIL_LOCK_SEC: int = Field(
        default=900,
        description="登录失败锁定时间（秒），默认 15 分钟",
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
