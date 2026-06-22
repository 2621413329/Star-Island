from fastapi import APIRouter, Depends
from fastapi.security import OAuth2PasswordRequestForm

from app.api.deps import DBSession, get_current_user
from app.api.deps_rate_limit import (
    enforce_auth_entry_rate_limit,
    enforce_login_rate_limit,
    enforce_register_rate_limit,
    enforce_token_rate_limit,
)
from app.core.config import settings
from app.core.redis import get_redis_client
from app.models.user import User
from app.repositories.profile_repository import ProfileRepository
from app.repositories.user_repository import UserRepository
from app.schemas.common import ResponseModel
from app.schemas.auth_entry import AuthEntryRequest, AuthEntryResponse, UserRegisterRequest
from app.schemas.user import Token, UserCreate, UserLogin, UserRead
from app.services.auth_service import AuthService
from app.services.rate_limit_service import RateLimitService

router = APIRouter(prefix="/auth", tags=["认证"])


def _rate_limit_service() -> RateLimitService | None:
    if not settings.RATE_LIMIT_ENABLED:
        return None
    return RateLimitService(get_redis_client())


def _auth_service(db: DBSession) -> AuthService:
    return AuthService(
        UserRepository(db),
        profile_repo=ProfileRepository(db),
        rate_limit_service=_rate_limit_service(),
    )


@router.post("/entry", response_model=ResponseModel[AuthEntryResponse])
async def auth_entry(
    payload: AuthEntryRequest,
    db: DBSession,
    _: None = Depends(enforce_auth_entry_rate_limit),
):
    """仅登录已注册账号（不自动注册）。"""
    return ResponseModel(
        data=await AuthService(
            UserRepository(db),
            rate_limit_service=_rate_limit_service(),
        ).entry(payload)
    )


@router.post("/register", response_model=ResponseModel[Token])
async def user_register(
    payload: UserRegisterRequest,
    db: DBSession,
    _: None = Depends(enforce_register_rate_limit),
):
    """用户注册（含昵称），成功后返回令牌。"""
    return ResponseModel(data=await _auth_service(db).user_register(payload))


@router.post("/login", response_model=ResponseModel[Token])
async def login(
    payload: UserLogin,
    db: DBSession,
    _: None = Depends(enforce_login_rate_limit),
):
    return ResponseModel(data=await _auth_service(db).login(payload))


@router.post("/token", response_model=Token)
async def login_for_access_token(
    db: DBSession,
    form_data: OAuth2PasswordRequestForm = Depends(),
    _: None = Depends(enforce_token_rate_limit),
):
    """OAuth2 表单登录，供 Swagger Authorize 与标准 OAuth2 客户端使用。"""
    payload = UserLogin(username=form_data.username, password=form_data.password)
    return await _auth_service(db).login(payload)


@router.get("/me", response_model=ResponseModel[UserRead])
async def me(current_user: User = Depends(get_current_user)):
    return ResponseModel(data=current_user)
