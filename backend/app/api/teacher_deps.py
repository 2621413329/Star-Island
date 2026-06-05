import uuid
from dataclasses import dataclass
from typing import Annotated

from fastapi import Depends

from app.api.deps import DBSession, get_current_user
from app.exceptions.business import BusinessException
from app.models.user import User
from app.repositories.profile_repository import ProfileRepository
from app.repositories.role_repository import RoleRepository


@dataclass(frozen=True)
class TeacherPrincipal:
    user: User
    class_name: str


async def get_current_teacher(
    user: Annotated[User, Depends(get_current_user)],
    db: DBSession,
) -> User:
    if not await RoleRepository(db).user_has_role(user.id, "teacher"):
        raise BusinessException("需要教师账号权限", 403)
    return user


async def get_teacher_principal(
    user: Annotated[User, Depends(get_current_teacher)],
    db: DBSession,
) -> TeacherPrincipal:
    profile = await ProfileRepository(db).get_by_user_id(user.id)
    if not profile or not profile.class_name:
        raise BusinessException("教师账号未绑定班级，请重新注册", 403)
    return TeacherPrincipal(user=user, class_name=profile.class_name)
