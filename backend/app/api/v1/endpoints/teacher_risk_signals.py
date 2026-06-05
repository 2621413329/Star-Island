import uuid
from datetime import date

from fastapi import APIRouter, Depends, Query

from app.api.deps import DBSession
from app.api.teacher_deps import TeacherPrincipal, get_teacher_principal
from app.repositories.daily_mood_report_repository import DailyMoodReportRepository
from app.repositories.profile_repository import DailyMomentRepository, ProfileRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.teacher_risk_moment_follow_repository import TeacherRiskMomentFollowRepository
from app.schemas.common import ResponseModel
from app.schemas.growth_observation import (
    CriticalRiskDetailRead,
    CriticalRiskFollowCreate,
    CriticalRiskFollowStateRead,
    CriticalRiskSignalRead,
)
from app.services.teacher_critical_risk_service import TeacherCriticalRiskService

router = APIRouter(prefix="/teacher/risk-signals", tags=["教师-危险信号"])


def _service(db: DBSession) -> TeacherCriticalRiskService:
    return TeacherCriticalRiskService(
        DailyMomentRepository(db),
        DailyMoodReportRepository(db),
        ProfileRepository(db),
        StudentRepository(db),
        TeacherRiskMomentFollowRepository(db),
        db,
    )


@router.get("", response_model=ResponseModel[list[CriticalRiskSignalRead]])
async def list_critical_risk_signals(
    db: DBSession,
    principal: TeacherPrincipal = Depends(get_teacher_principal),
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
    include_followed: bool = Query(default=True),
):
    start = date_from or date.today()
    end = date_to or date.today()
    items = await _service(db).list_signals(
        class_name=principal.class_name,
        date_from=start,
        date_to=end,
        include_followed=include_followed,
    )
    return ResponseModel(data=[CriticalRiskSignalRead(**x) for x in items])


@router.get("/pending-count", response_model=ResponseModel[int])
async def pending_critical_risk_count(
    db: DBSession,
    principal: TeacherPrincipal = Depends(get_teacher_principal),
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
):
    start = date_from or date.today()
    end = date_to or date.today()
    count = await _service(db).count_pending(
        class_name=principal.class_name, date_from=start, date_to=end
    )
    return ResponseModel(data=count)


@router.get("/{moment_id}", response_model=ResponseModel[CriticalRiskDetailRead])
async def get_critical_risk_detail(
    moment_id: uuid.UUID,
    db: DBSession,
    principal: TeacherPrincipal = Depends(get_teacher_principal),
):
    data = await _service(db).get_signal_detail(moment_id, class_name=principal.class_name)
    return ResponseModel(data=CriticalRiskDetailRead(**data))


@router.post("/{moment_id}/follow", response_model=ResponseModel[CriticalRiskFollowStateRead])
async def mark_critical_risk_followed(
    moment_id: uuid.UUID,
    body: CriticalRiskFollowCreate,
    db: DBSession,
    principal: TeacherPrincipal = Depends(get_teacher_principal),
):
    data = await _service(db).mark_followed(
        moment_id,
        class_name=principal.class_name,
        teacher_id=principal.user.id,
        note=body.note,
    )
    return ResponseModel(data=CriticalRiskFollowStateRead(**data))


@router.post("/{moment_id}/reactivate", response_model=ResponseModel[CriticalRiskFollowStateRead])
async def reactivate_critical_risk(
    moment_id: uuid.UUID,
    db: DBSession,
    principal: TeacherPrincipal = Depends(get_teacher_principal),
):
    data = await _service(db).reactivate(moment_id, class_name=principal.class_name)
    return ResponseModel(data=CriticalRiskFollowStateRead(**data))
