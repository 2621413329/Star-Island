from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from redis.asyncio import Redis
from redis.asyncio.connection import ConnectionPool

from app.core.config import settings

_redis_pool: ConnectionPool | None = None
_redis_client: Redis | None = None


def _build_pool() -> ConnectionPool:
    return ConnectionPool.from_url(
        settings.REDIS_URL,
        decode_responses=True,
        max_connections=settings.REDIS_MAX_CONNECTIONS,
    )


async def init_redis() -> Redis:
    global _redis_pool, _redis_client
    if _redis_client is not None:
        return _redis_client

    _redis_pool = _build_pool()
    _redis_client = Redis(connection_pool=_redis_pool)
    await _redis_client.ping()
    return _redis_client


async def close_redis() -> None:
    global _redis_pool, _redis_client
    if _redis_client is not None:
        await _redis_client.aclose()
        _redis_client = None
    if _redis_pool is not None:
        await _redis_pool.aclose()
        _redis_pool = None


def get_redis_client() -> Redis:
    if _redis_client is None:
        raise RuntimeError("Redis 未初始化，请确认应用已启动且 RATE_LIMIT_ENABLED=true")
    return _redis_client


@asynccontextmanager
async def redis_lifespan() -> AsyncIterator[Redis | None]:
    if not settings.RATE_LIMIT_ENABLED:
        yield None
        return

    client = await init_redis()
    try:
        yield client
    finally:
        await close_redis()
