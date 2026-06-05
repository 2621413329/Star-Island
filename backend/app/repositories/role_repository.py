import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.rbac import Role, UserRole
from app.models.user import User


class RoleRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_name(self, name: str) -> Role | None:
        result = await self.db.execute(select(Role).where(Role.name == name))
        return result.scalar_one_or_none()

    async def ensure_role(self, name: str, description: str | None = None) -> Role:
        role = await self.get_by_name(name)
        if role:
            return role
        role = Role(name=name, description=description)
        self.db.add(role)
        await self.db.commit()
        await self.db.refresh(role)
        return role

    async def assign_role(self, user_id: uuid.UUID, role_name: str) -> None:
        role = await self.ensure_role(role_name)
        result = await self.db.execute(
            select(UserRole).where(UserRole.user_id == user_id, UserRole.role_id == role.id)
        )
        if result.scalar_one_or_none():
            return
        self.db.add(UserRole(user_id=user_id, role_id=role.id))
        await self.db.commit()

    async def user_has_role(self, user_id: uuid.UUID, role_name: str) -> bool:
        result = await self.db.execute(
            select(UserRole)
            .join(Role, UserRole.role_id == Role.id)
            .where(UserRole.user_id == user_id, Role.name == role_name)
        )
        return result.scalar_one_or_none() is not None

    async def list_role_names(self, user_id: uuid.UUID) -> list[str]:
        user = await self.db.get(User, user_id, options=[selectinload(User.roles).selectinload(UserRole.role)])
        if not user:
            return []
        return [ur.role.name for ur in user.roles if ur.role]
