import pytest
from unittest.mock import AsyncMock

from app.services.rate_limit_service import LOGIN_LOCKED_MESSAGE, RATE_LIMIT_MESSAGE, RateLimitService


@pytest.mark.asyncio
async def test_rate_limit_hit_allows_under_limit():
    redis = AsyncMock()
    redis.incr.return_value = 1

    service = RateLimitService(redis)
    await service.hit("ratelimit:test", limit=3, window_seconds=60)

    redis.incr.assert_awaited_once_with("ratelimit:test")
    redis.expire.assert_awaited_once_with("ratelimit:test", 60)


@pytest.mark.asyncio
async def test_rate_limit_hit_blocks_over_limit():
    redis = AsyncMock()
    redis.incr.return_value = 4
    redis.ttl.return_value = 30

    service = RateLimitService(redis)

    with pytest.raises(Exception) as exc_info:
        await service.hit("ratelimit:test", limit=3, window_seconds=60)

    assert exc_info.value.code == 429
    assert exc_info.value.message == RATE_LIMIT_MESSAGE


@pytest.mark.asyncio
async def test_ensure_login_not_locked_raises_when_locked():
    redis = AsyncMock()
    redis.exists.return_value = 1

    service = RateLimitService(redis)

    with pytest.raises(Exception) as exc_info:
        await service.ensure_login_not_locked("TestUser")

    assert exc_info.value.code == 429
    assert exc_info.value.message == LOGIN_LOCKED_MESSAGE
    redis.exists.assert_awaited_once_with("auth:login:lock:testuser")


@pytest.mark.asyncio
async def test_record_login_failure_sets_lock_after_threshold():
    redis = AsyncMock()
    redis.incr.return_value = 5

    service = RateLimitService(redis)
    await service.record_login_failure("alice")

    redis.setex.assert_awaited_once_with("auth:login:lock:alice", 900, "1")


@pytest.mark.asyncio
async def test_clear_login_failures_deletes_keys():
    redis = AsyncMock()

    service = RateLimitService(redis)
    await service.clear_login_failures("Bob")

    redis.delete.assert_awaited_once_with("auth:login:fail:bob", "auth:login:lock:bob")
