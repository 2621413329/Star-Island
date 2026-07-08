import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.member import UserMembership


class UserMembershipRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_user_id(self, user_id: uuid.UUID) -> UserMembership | None:
        return await self.db.get(UserMembership, user_id)

    async def create(self, membership: UserMembership) -> UserMembership:
        self.db.add(membership)
        await self.db.commit()
        await self.db.refresh(membership)
        return membership

    async def save(self, membership: UserMembership) -> UserMembership:
        await self.db.commit()
        await self.db.refresh(membership)
        return membership
