from datetime import timedelta
import shutil
import uuid
from pathlib import Path

from loguru import logger
from sqlalchemy import text
from sqlalchemy.exc import ProgrammingError, SQLAlchemyError

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
            logger.warning("auth login failed username={}", payload.username)
            raise BusinessException("用户名或密码错误", 401)
        if not user.is_active:
            logger.warning("auth login disabled user_id={} username={}", user.id, user.username)
            raise BusinessException("用户已被禁用", 403)

        if self.rate_limit_service:
            await self.rate_limit_service.clear_login_failures(payload.username)

        logger.info("auth login success user_id={} username={}", user.id, user.username)
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
        logger.info("auth register success user_id={} username={}", user.id, user.username)
        return await self.login(
            UserLogin(username=payload.username, password=payload.password)
        )

    async def delete_account(self, user: User) -> dict:
        """永久注销账号：删除用户媒体目录与数据库账号及相关业务数据。"""
        user_id = user.id
        username = user.username
        media_root = settings.user_media_root_path / str(user_id)

        await self._clear_legacy_user_refs(user_id)
        self._remove_user_media(media_root)

        try:
            await self.user_repo.delete(user)
        except SQLAlchemyError as exc:
            logger.exception(
                "auth delete account db failed user_id={} username={}",
                user_id,
                username,
            )
            raise BusinessException("账号注销失败，请稍后重试", 500) from exc

        logger.info("auth delete account success user_id={} username={}", user_id, username)
        return {"deleted": True, "user_id": str(user_id)}

    async def _clear_legacy_user_refs(self, user_id: uuid.UUID) -> None:
        """兼容历史 stories / story_rules 外键（无 ON DELETE）。"""
        statements = (
            text("UPDATE story_rules SET created_by = NULL WHERE created_by = :uid"),
            text("DELETE FROM stories WHERE created_by = :uid"),
        )
        for statement in statements:
            try:
                await self.user_repo.db.execute(statement, {"uid": user_id})
                await self.user_repo.db.commit()
            except ProgrammingError:
                await self.user_repo.db.rollback()
            except SQLAlchemyError:
                await self.user_repo.db.rollback()
                logger.warning(
                    "auth delete account legacy cleanup skipped user_id={}",
                    user_id,
                )

    @staticmethod
    def _remove_user_media(media_root: Path) -> None:
        try:
            if media_root.exists():
                shutil.rmtree(media_root, ignore_errors=True)
        except OSError:
            logger.warning("auth delete account media cleanup failed path={}", media_root)

