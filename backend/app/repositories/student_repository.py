import uuid
from sqlalchemy import Select, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.student import Student
class StudentRepository:
    def __init__(self, db: AsyncSession): self.db = db
    async def get_by_id(self, student_id: uuid.UUID) -> Student | None: return await self.db.get(Student, student_id)
    async def get_by_student_no(self, student_no: str) -> Student | None:
        result = await self.db.execute(select(Student).where(Student.student_no == student_no)); return result.scalar_one_or_none()
    async def list(self, page: int, page_size: int, keyword: str | None = None) -> tuple[int, list[Student]]:
        stmt: Select[tuple[Student]] = select(Student).order_by(Student.created_at.desc()); count_stmt = select(func.count()).select_from(Student)
        if keyword:
            condition = Student.name.ilike(f"%{keyword}%") | Student.student_no.ilike(f"%{keyword}%") | Student.class_name.ilike(f"%{keyword}%")
            stmt = stmt.where(condition); count_stmt = count_stmt.where(condition)
        total = await self.db.scalar(count_stmt) or 0
        result = await self.db.execute(stmt.offset((page - 1) * page_size).limit(page_size)); return total, list(result.scalars().all())
    async def create(self, student: Student) -> Student:
        self.db.add(student); await self.db.commit(); await self.db.refresh(student); return student
    async def update(self, student: Student) -> Student:
        await self.db.commit(); await self.db.refresh(student); return student
    async def delete(self, student: Student) -> None:
        await self.db.delete(student); await self.db.commit()
