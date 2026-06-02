from datetime import timedelta

from app.core.config import settings
from app.core.security import create_access_token, get_password_hash, verify_password
from app.exceptions.business import BusinessException
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.auth_entry import AuthEntryRequest, AuthEntryResponse
from app.schemas.user import Token, UserCreate, UserLogin


class AuthService:
    def __init__(self, user_repo: UserRepository):
        self.user_repo = user_repo

    async def register(self, payload: UserCreate) -> User:
        if await self.user_repo.get_by_username(payload.username):
            raise BusinessException("用户名已存在", 409)
        if await self.user_repo.get_by_email(str(payload.email)):
            raise BusinessException("邮箱已存在", 409)
        user = User(username=payload.username, email=str(payload.email), password_hash=get_password_hash(payload.password))
        return await self.user_repo.create(user)

    async def login(self, payload: UserLogin) -> Token:
        user = await self.user_repo.get_by_username(payload.username)
        if not user or not verify_password(payload.password, user.password_hash):
            raise BusinessException("用户名或密码错误", 401)
        if not user.is_active:
            raise BusinessException("用户已被禁用", 403)
        return Token(access_token=create_access_token(str(user.id), timedelta(minutes=settings.JWT_EXPIRE_MINUTES)))

    async def entry(self, payload: AuthEntryRequest) -> AuthEntryResponse:
        existing = await self.user_repo.get_by_username(payload.username)
        if existing:
            token = await self.login(UserLogin(username=payload.username, password=payload.password))
            return AuthEntryResponse(token=token, is_new_user=False)
        email = str(payload.email) if payload.email else f"{payload.username}@stday.local"
        await self.register(UserCreate(username=payload.username, email=email, password=payload.password))
        token = await self.login(UserLogin(username=payload.username, password=payload.password))
        return AuthEntryResponse(token=token, is_new_user=True)
