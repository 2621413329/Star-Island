import uuid

from fastapi import APIRouter, Depends, Query

from app.api.deps import DBSession, get_current_user
from app.models.user import User
from app.repositories.observation_repository import ObservationRepository
from app.repositories.student_repository import StudentRepository
from app.schemas.common import Pagination, ResponseModel
from app.schemas.observation import ObservationCreate, ObservationRead, ObservationUpdate
from app.services.observation_service import ObservationService

router = APIRouter(prefix="/observations", tags=["成长观察"])


def get_service(db: DBSession) -> ObservationService:
    return ObservationService(ObservationRepository(db), StudentRepository(db))


@router.post("", response_model=ResponseModel[ObservationRead])
async def create_observation(payload: ObservationCreate, db: DBSession, current_user: User = Depends(get_current_user)):
    return ResponseModel(data=await get_service(db).create(payload, current_user.id))


@router.put("/{record_id}", response_model=ResponseModel[ObservationRead])
async def update_observation(record_id: uuid.UUID, payload: ObservationUpdate, db: DBSession, _: User = Depends(get_current_user)):
    return ResponseModel(data=await get_service(db).update(record_id, payload))


@router.delete("/{record_id}", response_model=ResponseModel[bool])
async def delete_observation(record_id: uuid.UUID, db: DBSession, _: User = Depends(get_current_user)):
    await get_service(db).delete(record_id)
    return ResponseModel(data=True)


@router.get("/{record_id}", response_model=ResponseModel[ObservationRead])
async def get_observation(record_id: uuid.UUID, db: DBSession, _: User = Depends(get_current_user)):
    return ResponseModel(data=await get_service(db).get(record_id))


@router.get("", response_model=ResponseModel[Pagination])
async def list_observations(
    db: DBSession,
    _: User = Depends(get_current_user),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    student_id: uuid.UUID | None = None,
    keyword: str | None = None,
):
    total, items = await get_service(db).list(page, page_size, student_id, keyword)
    return ResponseModel(data=Pagination(total=total, page=page, page_size=page_size, items=items))
