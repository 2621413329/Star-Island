from datetime import timedelta
import uuid

from app.core.config import settings
from app.core.security import create_access_token, get_password_hash, verify_password
from app.exceptions.business import BusinessException
from app.models.profile import UserProfile
from app.models.student import Student
from app.models.user import User
from app.repositories.profile_repository import ProfileRepository
from app.repositories.role_repository import RoleRepository
from app.repositories.school_class_repository import SchoolClassRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.user_repository import UserRepository
from app.services.school_class_service import SchoolClassService
from app.schemas.auth_entry import (
    AuthEntryRequest,
    AuthEntryResponse,
    StudentAuthRequest,
    StudentRegisterRequest,
    TeacherLoginRequest,
    TeacherRegisterRequest,
)
from app.schemas.user import Token, UserCreate, UserLogin


class AuthService:
    def __init__(
        self,
        user_repo: UserRepository,
        *,
        profile_repo: ProfileRepository | None = None,
        student_repo: StudentRepository | None = None,
        role_repo: RoleRepository | None = None,
        school_class_repo: SchoolClassRepository | None = None,
    ):
        self.user_repo = user_repo
        self.profile_repo = profile_repo
        self.student_repo = student_repo
        self.role_repo = role_repo
        self.school_class_repo = school_class_repo

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
        """仅登录已存在账号；未注册请走 student-register。"""
        if not await self.user_repo.get_by_username(payload.username):
            raise BusinessException("用户名或密码错误", 401)
        token = await self.login(UserLogin(username=payload.username, password=payload.password))
        return AuthEntryResponse(token=token, is_new_user=False)

    async def student_register(self, payload: StudentRegisterRequest) -> Token:
        if not self.profile_repo or not self.student_repo:
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
        await self._create_student_profile(user, payload.class_name)
        return await self.login(UserLogin(username=payload.username, password=payload.password))

    async def teacher_register(self, payload: TeacherRegisterRequest) -> Token:
        if payload.registration_secret != settings.TEACHER_REGISTRATION_SECRET:
            raise BusinessException("注册密钥无效", 403)
        if not self.role_repo or not self.profile_repo:
            raise BusinessException("服务未配置", 500)
        if await self.user_repo.get_by_username(payload.username):
            raise BusinessException("用户名已存在", 409)
        email = f"{payload.username}@teacher.stday.local"
        user = User(
            username=payload.username,
            nickname=payload.nickname,
            email=email,
            password_hash=get_password_hash(payload.password),
        )
        user = await self.user_repo.create(user)
        await self.role_repo.assign_role(user.id, "teacher")
        class_id, resolved_name = await self._resolve_class(payload.class_name)
        await self.profile_repo.create(
            UserProfile(
                user_id=user.id,
                class_id=class_id,
                class_name=resolved_name,
                onboarding_completed=True,
            )
        )
        return await self.login(UserLogin(username=payload.username, password=payload.password))

    async def teacher_login(self, payload: TeacherLoginRequest) -> Token:
        if not self.role_repo or not self.profile_repo:
            raise BusinessException("服务未配置", 500)
        user = await self.user_repo.get_by_username(payload.username)
        if not user or not verify_password(payload.password, user.password_hash):
            raise BusinessException("用户名或密码错误", 401)
        if not await self.role_repo.user_has_role(user.id, "teacher"):
            raise BusinessException("该账号不是教师账号", 403)
        profile = await self.profile_repo.get_by_user_id(user.id)
        if not profile or not profile.class_name:
            raise BusinessException("教师账号未绑定班级，请重新注册", 403)
        return await self.login(UserLogin(username=payload.username, password=payload.password))

    async def student_login(self, payload: StudentAuthRequest) -> Token:
        user = await self.user_repo.get_by_username(payload.username)
        if not user:
            raise BusinessException("用户名或密码错误", 401)
        token = await self.login(UserLogin(username=payload.username, password=payload.password))
        await self._sync_student_class(user.id, payload.class_name)
        return token

    async def _resolve_class(self, class_name: str):
        if not self.school_class_repo:
            from app.core.school_classes import CLASS_OPTIONS

            name = class_name.strip()
            if name not in CLASS_OPTIONS:
                raise BusinessException("无效班级", 400)
            return None, name
        school_class = await SchoolClassService(self.school_class_repo).resolve_active(class_name)
        return school_class.id, school_class.name

    async def _create_student_profile(self, user: User, class_name: str) -> UserProfile:
        class_id, resolved_name = await self._resolve_class(class_name)
        student = Student(
            student_no=f"U{user.id.hex[:10]}",
            name=user.display_name,
            class_id=class_id,
            class_name=resolved_name,
            gender=None,
        )
        student = await self.student_repo.create(student)
        profile = UserProfile(user_id=user.id, student_id=student.id, onboarding_completed=False)
        return await self.profile_repo.create(profile)

    async def _sync_student_class(self, user_id: uuid.UUID, class_name: str) -> None:
        if not self.profile_repo or not self.student_repo:
            return
        profile = await self.profile_repo.get_by_user_id(user_id)
        if not profile:
            user = await self.user_repo.get_by_id(user_id)
            if user:
                await self._create_student_profile(user, class_name)
            return
        if not profile.student_id:
            user = await self.user_repo.get_by_id(user_id)
            if not user:
                return
            class_id, resolved_name = await self._resolve_class(class_name)
            student = Student(
                student_no=f"U{user.id.hex[:10]}",
                name=user.display_name,
                class_id=class_id,
                class_name=resolved_name,
                gender=profile.gender,
            )
            student = await self.student_repo.create(student)
            profile.student_id = student.id
            await self.profile_repo.save(profile)
            return
        class_id, resolved_name = await self._resolve_class(class_name)
        student = await self.student_repo.get_by_id(profile.student_id)
        if student and (
            student.class_name != resolved_name or student.class_id != class_id
        ):
            student.class_id = class_id
            student.class_name = resolved_name
            await self.student_repo.update(student)
