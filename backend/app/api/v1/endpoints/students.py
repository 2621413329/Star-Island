import uuid

from fastapi import APIRouter, Depends, Query

from app.api.deps import DBSession, get_current_admin
from app.models.user import User
from app.repositories.student_repository import StudentRepository
from app.schemas.common import Pagination, ResponseModel
from app.schemas.student import StudentCreate, StudentRead, StudentUpdate
from app.services.student_service import StudentService

router = APIRouter(prefix="/students", tags=["学生"])


@router.post("", response_model=ResponseModel[StudentRead])
async def create_student(payload: StudentCreate, db: DBSession, _: User = Depends(get_current_admin)):
    return ResponseModel(data=await StudentService(StudentRepository(db)).create(payload))


@router.put("/{student_id}", response_model=ResponseModel[StudentRead])
async def update_student(student_id: uuid.UUID, payload: StudentUpdate, db: DBSession, _: User = Depends(get_current_admin)):
    return ResponseModel(data=await StudentService(StudentRepository(db)).update(student_id, payload))


@router.delete("/{student_id}", response_model=ResponseModel[bool])
async def delete_student(student_id: uuid.UUID, db: DBSession, _: User = Depends(get_current_admin)):
    await StudentService(StudentRepository(db)).delete(student_id)
    return ResponseModel(data=True)


@router.get("/{student_id}", response_model=ResponseModel[StudentRead])
async def get_student(student_id: uuid.UUID, db: DBSession, _: User = Depends(get_current_admin)):
    return ResponseModel(data=await StudentService(StudentRepository(db)).get(student_id))


@router.get("", response_model=ResponseModel[Pagination])
async def list_students(
    db: DBSession,
    _: User = Depends(get_current_admin),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    keyword: str | None = None,
):
    total, items = await StudentService(StudentRepository(db)).list(page, page_size, keyword)
    return ResponseModel(data=Pagination(total=total, page=page, page_size=page_size, items=items))
