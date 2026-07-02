import uuid
from datetime import date

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user_xp_grant import UserXpGrant


class UserXpGrantRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def sum_for_user_on_date(
        self,
        user_id: uuid.UUID,
        on_date: date,
        *,
        source: str | None = None,
        exclude_moment_id: uuid.UUID | None = None,
    ) -> int:
        stmt = select(func.coalesce(func.sum(UserXpGrant.amount), 0)).where(
            UserXpGrant.user_id == user_id,
            UserXpGrant.grant_date == on_date,
        )
        if source is not None:
            stmt = stmt.where(UserXpGrant.source == source)
        if exclude_moment_id is not None:
            stmt = stmt.where(
                (UserXpGrant.moment_id.is_(None)) | (UserXpGrant.moment_id != exclude_moment_id)
            )
        result = await self.db.execute(stmt)
        return int(result.scalar_one())

    async def sum_all_for_user(self, user_id: uuid.UUID) -> int:
        result = await self.db.execute(
            select(func.coalesce(func.sum(UserXpGrant.amount), 0)).where(
                UserXpGrant.user_id == user_id
            )
        )
        return int(result.scalar_one())

    async def create_grant(
        self,
        *,
        user_id: uuid.UUID,
        grant_date: date,
        source: str,
        amount: int,
        task_completion_id: uuid.UUID | None = None,
        moment_id: uuid.UUID | None = None,
    ) -> UserXpGrant | None:
        if amount <= 0:
            return None
        grant = UserXpGrant(
            user_id=user_id,
            grant_date=grant_date,
            source=source,
            amount=amount,
            task_completion_id=task_completion_id,
            moment_id=moment_id,
        )
        self.db.add(grant)
        await self.db.commit()
        await self.db.refresh(grant)
        return grant

    async def delete_by_task_completion(self, completion_id: uuid.UUID) -> int:
        result = await self.db.execute(
            select(UserXpGrant).where(UserXpGrant.task_completion_id == completion_id)
        )
        grants = list(result.scalars())
        removed = 0
        for grant in grants:
            removed += int(grant.amount or 0)
            await self.db.delete(grant)
        if grants:
            await self.db.commit()
        return removed

    async def delete_by_moment(self, moment_id: uuid.UUID) -> int:
        result = await self.db.execute(
            select(UserXpGrant).where(UserXpGrant.moment_id == moment_id)
        )
        grants = list(result.scalars())
        removed = 0
        for grant in grants:
            removed += int(grant.amount or 0)
            await self.db.delete(grant)
        if grants:
            await self.db.commit()
        return removed
