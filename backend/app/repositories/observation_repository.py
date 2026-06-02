import uuid
from sqlalchemy import Select, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.observation import ObservationRecord
class ObservationRepository:
    def __init__(self, db: AsyncSession): self.db = db
    async def get_by_id(self, record_id: uuid.UUID) -> ObservationRecord | None: return await self.db.get(ObservationRecord, record_id)
    async def list(self, page: int, page_size: int, student_id: uuid.UUID | None = None, keyword: str | None = None) -> tuple[int, list[ObservationRecord]]:
        stmt: Select[tuple[ObservationRecord]] = select(ObservationRecord).order_by(ObservationRecord.created_at.desc()); count_stmt = select(func.count()).select_from(ObservationRecord)
        conditions = []
        if student_id: conditions.append(ObservationRecord.student_id == student_id)
        if keyword: conditions.append(ObservationRecord.event_title.ilike(f"%{keyword}%") | ObservationRecord.event_content.ilike(f"%{keyword}%") | ObservationRecord.event_type.ilike(f"%{keyword}%"))
        for condition in conditions:
            stmt = stmt.where(condition); count_stmt = count_stmt.where(condition)
        total = await self.db.scalar(count_stmt) or 0
        result = await self.db.execute(stmt.offset((page - 1) * page_size).limit(page_size)); return total, list(result.scalars().all())
    async def create(self, record: ObservationRecord) -> ObservationRecord:
        self.db.add(record); await self.db.commit(); await self.db.refresh(record); return record
    async def update(self, record: ObservationRecord) -> ObservationRecord:
        await self.db.commit(); await self.db.refresh(record); return record
    async def delete(self, record: ObservationRecord) -> None:
        await self.db.delete(record); await self.db.commit()
