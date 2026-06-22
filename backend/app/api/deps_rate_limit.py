from fastapi import Depends, Request
from fastapi.security import OAuth2PasswordRequestForm

from app.core.client_ip import get_client_ip
from app.core.config import settings
from app.core.redis import get_redis_client
from app.schemas.auth_entry import AuthEntryRequest, UserRegisterRequest
from app.schemas.user import UserLogin
from app.services.rate_limit_service import RateLimitService


def _rate_limit_service() -> RateLimitService:
    return RateLimitService(get_redis_client())


async def enforce_login_rate_limit(
    request: Request,
    payload: UserLogin,
) -> None:
    if not settings.RATE_LIMIT_ENABLED:
        return

    service = _rate_limit_service()
    ip = get_client_ip(request)
    await service.enforce_login_ip_limit(ip)
    await service.enforce_login_user_limit(payload.username)


async def enforce_register_rate_limit(
    request: Request,
    payload: UserRegisterRequest,
) -> None:
    if not settings.RATE_LIMIT_ENABLED:
        return

    service = _rate_limit_service()
    ip = get_client_ip(request)
    await service.enforce_register_ip_limit(ip)


async def enforce_auth_entry_rate_limit(
    request: Request,
    payload: AuthEntryRequest,
) -> None:
    if not settings.RATE_LIMIT_ENABLED:
        return

    service = _rate_limit_service()
    ip = get_client_ip(request)
    await service.enforce_login_ip_limit(ip)
    await service.enforce_login_user_limit(payload.username)


async def enforce_token_rate_limit(
    request: Request,
    form_data: OAuth2PasswordRequestForm = Depends(),
) -> None:
    if not settings.RATE_LIMIT_ENABLED:
        return

    service = _rate_limit_service()
    ip = get_client_ip(request)
    await service.enforce_login_ip_limit(ip)
    await service.enforce_login_user_limit(form_data.username)
