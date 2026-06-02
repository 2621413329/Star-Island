from fastapi import APIRouter, Depends

from app.api.deps import DBSession, get_current_user
from app.models.user import User
from app.repositories.observation_repository import ObservationRepository
from app.repositories.student_repository import StudentRepository
from app.schemas.common import ResponseModel
from app.schemas.observation import ObservationCreate, ObservationRead
from app.services.observation_service import ObservationService

router = APIRouter(prefix="/record", tags=["记录入口"])


@router.post("", response_model=ResponseModel[ObservationRead])
async def create_record(payload: ObservationCreate, db: DBSession, current_user: User = Depends(get_current_user)):
    service = ObservationService(ObservationRepository(db), StudentRepository(db))
    record = await service.create(payload, current_user.id)
    return ResponseModel(data=record)
