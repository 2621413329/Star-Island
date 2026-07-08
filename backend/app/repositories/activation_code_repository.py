import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.member import ActivationCode


class ActivationCodeRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, code_id: uuid.UUID) -> ActivationCode | None:
        return await self.db.get(ActivationCode, code_id)

    async def get_by_code(self, code: str) -> ActivationCode | None:
        result = await self.db.execute(
            select(ActivationCode).where(ActivationCode.code == code.strip().upper())
        )
        return result.scalar_one_or_none()

    async def list_all(
        self,
        *,
        status: str | None = None,
        batch_no: str | None = None,
        limit: int = 200,
    ) -> list[ActivationCode]:
        stmt = select(ActivationCode).order_by(ActivationCode.created_at.desc()).limit(limit)
        if status is not None:
            stmt = stmt.where(ActivationCode.status == status)
        if batch_no is not None:
            stmt = stmt.where(ActivationCode.batch_no == batch_no)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def create(self, activation_code: ActivationCode) -> ActivationCode:
        self.db.add(activation_code)
        await self.db.commit()
        await self.db.refresh(activation_code)
        return activation_code

    async def create_many(self, activation_codes: list[ActivationCode]) -> list[ActivationCode]:
        self.db.add_all(activation_codes)
        await self.db.commit()
        for code in activation_codes:
            await self.db.refresh(code)
        return activation_codes

    async def save(self, activation_code: ActivationCode) -> ActivationCode:
        await self.db.commit()
        await self.db.refresh(activation_code)
        return activation_code
