import os

# 测试环境默认关闭 Redis 限流，避免 CI / 本机无 Redis 时启动失败
os.environ.setdefault("RATE_LIMIT_ENABLED", "false")

import pytest

from app.core.config import get_settings


@pytest.fixture(autouse=True)
def _reset_settings_cache():
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()
