from datetime import timedelta
import uuid

from app.core.config import settings
from app.core.security import create_access_token, get_password_hash, verify_password
from app.exceptions.business import BusinessException
from app.models.profile import UserProfile
from app.models.user import User
from app.repositories.profile_repository import ProfileRepository
from app.repositories.user_repository import UserRepository
from app.schemas.auth_entry import (
    AuthEntryRequest,
    AuthEntryResponse,
    UserRegisterRequest,
)
from app.schemas.user import Token, UserCreate, UserLogin
from app.services.rate_limit_service import RateLimitService


class AuthService:
    def __init__(
        self,
        user_repo: UserRepository,
        *,
        profile_repo: ProfileRepository | None = None,
        rate_limit_service: RateLimitService | None = None,
    ):
        self.user_repo = user_repo
        self.profile_repo = profile_repo
        self.rate_limit_service = rate_limit_service

    async def register(self, payload: UserCreate) -> User:
        if await self.user_repo.get_by_username(payload.username):
            raise BusinessException("用户名已存在", 409)
        if await self.user_repo.get_by_email(str(payload.email)):
            raise BusinessException("邮箱已存在", 409)
        user = User(
            username=payload.username,
            email=str(payload.email),
            password_hash=get_password_hash(payload.password),
        )
        return await self.user_repo.create(user)

    async def login(self, payload: UserLogin) -> Token:
        if self.rate_limit_service:
            await self.rate_limit_service.ensure_login_not_locked(payload.username)

        user = await self.user_repo.get_by_username(payload.username)
        if not user or not verify_password(payload.password, user.password_hash):
            if self.rate_limit_service:
                await self.rate_limit_service.record_login_failure(payload.username)
            raise BusinessException("用户名或密码错误", 401)
        if not user.is_active:
            raise BusinessException("用户已被禁用", 403)

        if self.rate_limit_service:
            await self.rate_limit_service.clear_login_failures(payload.username)

        return Token(
            access_token=create_access_token(
                str(user.id), timedelta(minutes=settings.JWT_EXPIRE_MINUTES)
            )
        )

    async def entry(self, payload: AuthEntryRequest) -> AuthEntryResponse:
        """仅登录已存在账号。"""
        if not await self.user_repo.get_by_username(payload.username):
            raise BusinessException("用户名或密码错误", 401)
        token = await self.login(
            UserLogin(username=payload.username, password=payload.password)
        )
        return AuthEntryResponse(token=token, is_new_user=False)

    async def user_register(self, payload: UserRegisterRequest) -> Token:
        if not self.profile_repo:
            raise BusinessException("服务未配置", 500)
        if await self.user_repo.get_by_username(payload.username):
            raise BusinessException("用户名已存在", 409)
        email = f"{payload.username}@stday.local"
        user = User(
            username=payload.username,
            nickname=payload.nickname,
            email=email,
            password_hash=get_password_hash(payload.password),
        )
        user = await self.user_repo.create(user)
        await self.profile_repo.create(
            UserProfile(user_id=user.id, onboarding_completed=False)
        )
        return await self.login(
            UserLogin(username=payload.username, password=payload.password)
        )
