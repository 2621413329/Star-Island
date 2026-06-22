from redis.asyncio import Redis

from app.core.config import settings
from app.exceptions.business import BusinessException

RATE_LIMIT_MESSAGE = "请求过于频繁，请稍后再试"
LOGIN_LOCKED_MESSAGE = "登录失败次数过多，请稍后再试"


class RateLimitService:
    def __init__(self, redis: Redis):
        self.redis = redis

    async def hit(self, key: str, limit: int, window_seconds: int) -> None:
        count = await self.redis.incr(key)
        if count == 1:
            await self.redis.expire(key, window_seconds)
        else:
            ttl = await self.redis.ttl(key)
            if ttl == -1:
                await self.redis.expire(key, window_seconds)

        if count > limit:
            raise BusinessException(RATE_LIMIT_MESSAGE, 429)

    async def enforce_login_ip_limit(self, ip: str) -> None:
        await self.hit(
            f"ratelimit:auth:login:ip:{ip}",
            settings.AUTH_LOGIN_IP_LIMIT,
            settings.AUTH_LOGIN_IP_WINDOW_SEC,
        )

    async def enforce_login_user_limit(self, username: str) -> None:
        normalized = username.strip().lower()
        await self.hit(
            f"ratelimit:auth:login:user:{normalized}",
            settings.AUTH_LOGIN_USER_LIMIT,
            settings.AUTH_LOGIN_USER_WINDOW_SEC,
        )

    async def enforce_register_ip_limit(self, ip: str) -> None:
        await self.hit(
            f"ratelimit:auth:register:ip:{ip}",
            settings.AUTH_REGISTER_IP_LIMIT,
            settings.AUTH_REGISTER_IP_WINDOW_SEC,
        )

    async def ensure_login_not_locked(self, username: str) -> None:
        normalized = username.strip().lower()
        locked = await self.redis.exists(f"auth:login:lock:{normalized}")
        if locked:
            raise BusinessException(LOGIN_LOCKED_MESSAGE, 429)

    async def record_login_failure(self, username: str) -> None:
        normalized = username.strip().lower()
        fail_key = f"auth:login:fail:{normalized}"
        lock_key = f"auth:login:lock:{normalized}"

        count = await self.redis.incr(fail_key)
        if count == 1:
            await self.redis.expire(fail_key, settings.AUTH_LOGIN_FAIL_LOCK_SEC)

        if count >= settings.AUTH_LOGIN_FAIL_LOCK_COUNT:
            await self.redis.setex(lock_key, settings.AUTH_LOGIN_FAIL_LOCK_SEC, "1")

    async def clear_login_failures(self, username: str) -> None:
        normalized = username.strip().lower()
        await self.redis.delete(
            f"auth:login:fail:{normalized}",
            f"auth:login:lock:{normalized}",
        )
