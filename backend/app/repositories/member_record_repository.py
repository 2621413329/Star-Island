import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.member import MemberRecord


class MemberRecordRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, record_id: uuid.UUID) -> MemberRecord | None:
        return await self.db.get(MemberRecord, record_id)

    async def get_by_transaction_id(self, transaction_id: str) -> MemberRecord | None:
        result = await self.db.execute(
            select(MemberRecord).where(MemberRecord.transaction_id == transaction_id)
        )
        return result.scalar_one_or_none()

    async def get_latest_by_user_id(self, user_id: uuid.UUID) -> MemberRecord | None:
        result = await self.db.execute(
            select(MemberRecord)
            .where(MemberRecord.user_id == user_id)
            .order_by(MemberRecord.start_time.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()

    async def get_latest_by_original_transaction_id(
        self,
        original_transaction_id: str,
    ) -> MemberRecord | None:
        result = await self.db.execute(
            select(MemberRecord)
            .where(MemberRecord.original_transaction_id == original_transaction_id)
            .order_by(MemberRecord.start_time.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()

    async def list_by_user_id(
        self,
        user_id: uuid.UUID,
        *,
        source: str | None = None,
        limit: int = 100,
    ) -> list[MemberRecord]:
        stmt = (
            select(MemberRecord)
            .where(MemberRecord.user_id == user_id)
            .order_by(MemberRecord.created_at.desc())
            .limit(limit)
        )
        if source is not None:
            stmt = stmt.where(MemberRecord.source == source)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def list_active_by_user_id(self, user_id: uuid.UUID) -> list[MemberRecord]:
        result = await self.db.execute(
            select(MemberRecord)
            .where(
                MemberRecord.user_id == user_id,
                MemberRecord.status == "active",
            )
            .order_by(MemberRecord.end_time.desc().nulls_first(), MemberRecord.start_time.desc())
        )
        return list(result.scalars().all())

    async def list_all(
        self,
        *,
        user_id: uuid.UUID | None = None,
        source: str | None = None,
        limit: int = 200,
    ) -> list[MemberRecord]:
        stmt = select(MemberRecord).order_by(MemberRecord.created_at.desc()).limit(limit)
        if user_id is not None:
            stmt = stmt.where(MemberRecord.user_id == user_id)
        if source is not None:
            stmt = stmt.where(MemberRecord.source == source)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def create(self, record: MemberRecord) -> MemberRecord:
        self.db.add(record)
        await self.db.commit()
        await self.db.refresh(record)
        return record

    async def save(self, record: MemberRecord) -> MemberRecord:
        await self.db.commit()
        await self.db.refresh(record)
        return record
