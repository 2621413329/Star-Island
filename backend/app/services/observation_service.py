import uuid

from app.exceptions.business import BusinessException
from app.models.observation import ObservationRecord
from app.repositories.observation_repository import ObservationRepository
from app.repositories.student_repository import StudentRepository
from app.schemas.observation import ObservationCreate, ObservationUpdate


class ObservationService:
    def __init__(self, observation_repo: ObservationRepository, student_repo: StudentRepository):
        self.observation_repo = observation_repo
        self.student_repo = student_repo

    async def create(self, payload: ObservationCreate, created_by: uuid.UUID) -> ObservationRecord:
        if not await self.student_repo.get_by_id(payload.student_id):
            raise BusinessException("学生不存在", 404)
        record = ObservationRecord(**payload.model_dump(), created_by=created_by)
        return await self.observation_repo.create(record)

    async def update(self, record_id: uuid.UUID, payload: ObservationUpdate) -> ObservationRecord:
        record = await self.get(record_id)
        update_data = payload.model_dump(exclude_unset=True)
        if "student_id" in update_data and not await self.student_repo.get_by_id(update_data["student_id"]):
            raise BusinessException("学生不存在", 404)
        for key, value in update_data.items():
            setattr(record, key, value)
        return await self.observation_repo.update(record)

    async def delete(self, record_id: uuid.UUID) -> None:
        await self.observation_repo.delete(await self.get(record_id))

    async def get(self, record_id: uuid.UUID) -> ObservationRecord:
        record = await self.observation_repo.get_by_id(record_id)
        if not record:
            raise BusinessException("观察记录不存在", 404)
        return record

    async def list(self, page: int, page_size: int, student_id: uuid.UUID | None = None, keyword: str | None = None):
        return await self.observation_repo.list(page, page_size, student_id, keyword)
