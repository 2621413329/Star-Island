from fastapi import APIRouter, Depends
from fastapi.security import OAuth2PasswordRequestForm

from app.api.deps import DBSession, get_current_user
from app.models.user import User
from app.repositories.profile_repository import ProfileRepository
from app.repositories.user_repository import UserRepository
from app.schemas.common import ResponseModel
from app.schemas.auth_entry import AuthEntryRequest, AuthEntryResponse, UserRegisterRequest
from app.schemas.user import Token, UserCreate, UserLogin, UserRead
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["认证"])


def _auth_service(db: DBSession) -> AuthService:
    return AuthService(
        UserRepository(db),
        profile_repo=ProfileRepository(db),
    )


@router.post("/entry", response_model=ResponseModel[AuthEntryResponse])
async def auth_entry(payload: AuthEntryRequest, db: DBSession):
    """仅登录已注册账号（不自动注册）。"""
    return ResponseModel(
        data=await AuthService(UserRepository(db)).entry(payload)
    )


@router.post("/register", response_model=ResponseModel[Token])
async def user_register(payload: UserRegisterRequest, db: DBSession):
    """用户注册（含昵称），成功后返回令牌。"""
    return ResponseModel(data=await _auth_service(db).user_register(payload))


@router.post("/login", response_model=ResponseModel[Token])
async def login(payload: UserLogin, db: DBSession):
    return ResponseModel(data=await _auth_service(db).login(payload))


@router.post("/token", response_model=Token)
async def login_for_access_token(
    db: DBSession, form_data: OAuth2PasswordRequestForm = Depends()
):
    """OAuth2 表单登录，供 Swagger Authorize 与标准 OAuth2 客户端使用。"""
    payload = UserLogin(username=form_data.username, password=form_data.password)
    return await _auth_service(db).login(payload)


@router.get("/me", response_model=ResponseModel[UserRead])
async def me(current_user: User = Depends(get_current_user)):
    return ResponseModel(data=current_user)
