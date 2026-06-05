from fastapi import APIRouter, Depends
from fastapi.security import OAuth2PasswordRequestForm

from app.api.deps import DBSession, get_current_user
from app.api.teacher_deps import TeacherPrincipal, get_teacher_principal
from app.core.school_classes import CLASS_OPTIONS, DEFAULT_CLASS_NAME
from app.models.user import User
from app.repositories.profile_repository import ProfileRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.user_repository import UserRepository
from app.schemas.common import ResponseModel
from app.repositories.role_repository import RoleRepository
from app.schemas.auth_entry import (
    AuthEntryRequest,
    AuthEntryResponse,
    ClassListResponse,
    StudentAuthRequest,
    StudentRegisterRequest,
    TeacherLoginRequest,
    TeacherProfileRead,
    TeacherRegisterRequest,
)
from app.schemas.user import Token, UserCreate, UserLogin, UserRead
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["认证"])


def _auth_service(db: DBSession) -> AuthService:
    return AuthService(
        UserRepository(db),
        profile_repo=ProfileRepository(db),
        student_repo=StudentRepository(db),
        role_repo=RoleRepository(db),
    )


@router.get("/classes", response_model=ResponseModel[ClassListResponse])
async def list_classes():
    return ResponseModel(
        data=ClassListResponse(default_class=DEFAULT_CLASS_NAME, classes=list(CLASS_OPTIONS))
    )


@router.post("/entry", response_model=ResponseModel[AuthEntryResponse])
async def auth_entry(payload: AuthEntryRequest, db: DBSession):
    """仅登录已注册账号（不自动注册）。"""
    return ResponseModel(data=await AuthService(UserRepository(db)).entry(payload))


@router.post("/teacher-register", response_model=ResponseModel[Token])
async def teacher_register(payload: TeacherRegisterRequest, db: DBSession):
    """教师端注册（需注册密钥）。"""
    return ResponseModel(data=await _auth_service(db).teacher_register(payload))


@router.post("/teacher-login", response_model=ResponseModel[Token])
async def teacher_login(payload: TeacherLoginRequest, db: DBSession):
    """教师端登录。"""
    return ResponseModel(data=await _auth_service(db).teacher_login(payload))


@router.get("/teacher/me", response_model=ResponseModel[TeacherProfileRead])
async def teacher_me(principal: TeacherPrincipal = Depends(get_teacher_principal)):
    return ResponseModel(
        data=TeacherProfileRead(
            username=principal.user.username,
            nickname=principal.user.display_name,
            class_name=principal.class_name,
        )
    )


@router.post("/student-register", response_model=ResponseModel[Token])
async def student_register(payload: StudentRegisterRequest, db: DBSession):
    """学生端注册（含班级与昵称），成功后返回令牌。"""
    return ResponseModel(data=await _auth_service(db).student_register(payload))


@router.post("/student-login", response_model=ResponseModel[Token])
async def student_login(payload: StudentAuthRequest, db: DBSession):
    """学生端登录（含班级同步），用户名或密码错误时 401。"""
    return ResponseModel(data=await _auth_service(db).student_login(payload))


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
    return await _auth_service(db).login(payload)


@router.get("/me", response_model=ResponseModel[UserRead])
async def me(current_user: User = Depends(get_current_user)):
    return ResponseModel(data=current_user)
