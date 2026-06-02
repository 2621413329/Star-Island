from fastapi import APIRouter, Depends
from fastapi.security import OAuth2PasswordRequestForm

from app.api.deps import DBSession, get_current_user
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.common import ResponseModel
from app.schemas.auth_entry import AuthEntryRequest, AuthEntryResponse
from app.schemas.user import Token, UserCreate, UserLogin, UserRead
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["认证"])


@router.post("/entry", response_model=ResponseModel[AuthEntryResponse])
async def auth_entry(payload: AuthEntryRequest, db: DBSession):
    """登录即注册：用户名存在则登录，否则自动注册。"""
    return ResponseModel(data=await AuthService(UserRepository(db)).entry(payload))


@router.post("/register", response_model=ResponseModel[UserRead])
async def register(payload: UserCreate, db: DBSession):
    return ResponseModel(data=await AuthService(UserRepository(db)).register(payload))


@router.post("/login", response_model=ResponseModel[Token])
async def login(payload: UserLogin, db: DBSession):
    return ResponseModel(data=await AuthService(UserRepository(db)).login(payload))


@router.post("/token", response_model=Token)
async def login_for_access_token(db: DBSession, form_data: OAuth2PasswordRequestForm = Depends()):
    """OAuth2 表单登录，供 Swagger Authorize 与标准 OAuth2 客户端使用。"""
    payload = UserLogin(username=form_data.username, password=form_data.password)
    return await AuthService(UserRepository(db)).login(payload)


@router.get("/me", response_model=ResponseModel[UserRead])
async def me(current_user: User = Depends(get_current_user)):
    return ResponseModel(data=current_user)
