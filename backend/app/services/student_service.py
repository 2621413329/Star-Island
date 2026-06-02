import uuid

from app.exceptions.business import BusinessException
from app.models.student import Student
from app.repositories.student_repository import StudentRepository
from app.schemas.student import StudentCreate, StudentUpdate


class StudentService:
    def __init__(self, student_repo: StudentRepository):
        self.student_repo = student_repo

    async def create(self, payload: StudentCreate) -> Student:
        if await self.student_repo.get_by_student_no(payload.student_no):
            raise BusinessException("学号已存在", 409)
        return await self.student_repo.create(Student(**payload.model_dump()))

    async def update(self, student_id: uuid.UUID, payload: StudentUpdate) -> Student:
        student = await self.get(student_id)
        update_data = payload.model_dump(exclude_unset=True)
        if (
            "student_no" in update_data
            and update_data["student_no"] != student.student_no
            and await self.student_repo.get_by_student_no(update_data["student_no"])
        ):
            raise BusinessException("学号已存在", 409)
        for key, value in update_data.items():
            setattr(student, key, value)
        return await self.student_repo.update(student)

    async def delete(self, student_id: uuid.UUID) -> None:
        await self.student_repo.delete(await self.get(student_id))

    async def get(self, student_id: uuid.UUID) -> Student:
        student = await self.student_repo.get_by_id(student_id)
        if not student:
            raise BusinessException("学生不存在", 404)
        return student

    async def list(self, page: int, page_size: int, keyword: str | None = None):
        return await self.student_repo.list(page, page_size, keyword)
