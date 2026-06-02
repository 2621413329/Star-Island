import uuid
from typing import Annotated

from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_access_token
from app.database.database import get_db
from app.exceptions.business import BusinessException
from app.models.user import User
from app.repositories.user_repository import UserRepository

DBSession = Annotated[AsyncSession, Depends(get_db)]
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token")


async def get_current_user(token: Annotated[str, Depends(oauth2_scheme)], db: DBSession) -> User:
    subject = decode_access_token(token)
    if not subject:
        raise BusinessException("认证凭证无效", 401)
    try:
        user_id = uuid.UUID(subject)
    except ValueError as exc:
        raise BusinessException("认证凭证无效", 401) from exc
    user = await UserRepository(db).get_by_id(user_id)
    if not user:
        raise BusinessException("用户不存在", 401)
    if not user.is_active:
        raise BusinessException("用户已被禁用", 403)
    return user
