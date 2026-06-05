import uuid
from datetime import date

from fastapi import APIRouter, Depends, Query

from app.api.deps import DBSession
from app.api.teacher_deps import TeacherPrincipal, get_teacher_principal
from app.repositories.daily_mood_report_repository import DailyMoodReportRepository
from app.repositories.profile_repository import DailyMomentRepository, ProfileRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.teacher_alert_repository import TeacherAlertRepository
from app.schemas.common import ResponseModel
from app.schemas.growth_observation import GrowthFocusRead
from app.schemas.teacher_alert import TeacherAlertAckResponse
from app.services.teacher_alert_service import TeacherAlertService

router = APIRouter(prefix="/teacher/alerts", tags=["教师-成长关注"])


def _alert_service(db: DBSession) -> TeacherAlertService:
    return TeacherAlertService(
        TeacherAlertRepository(db),
        DailyMoodReportRepository(db),
        StudentRepository(db),
        DailyMomentRepository(db),
        ProfileRepository(db),
    )


@router.get("", response_model=ResponseModel[list[GrowthFocusRead]])
async def list_growth_focus(
    db: DBSession,
    principal: TeacherPrincipal = Depends(get_teacher_principal),
    report_date: date | None = Query(default=None),
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
    include_acked: bool = Query(default=False),
    include_followed: bool | None = Query(default=None),
):
    """成长关注列表（本班；按日期范围）。"""
    include = include_followed if include_followed is not None else include_acked
    service = _alert_service(db)
    if date_from is not None or date_to is not None:
        start = date_from or date_to or date.today()
        end = date_to or date_from or date.today()
        items = await service.sync_and_list_range(
            start, end, class_name=principal.class_name, include_acked=include
        )
    else:
        day = report_date or date.today()
        items = await service.sync_and_list(
            day, class_name=principal.class_name, include_acked=include
        )
    return ResponseModel(data=[GrowthFocusRead(**item) for item in items])


@router.post("/{alert_id}/ack", response_model=ResponseModel[TeacherAlertAckResponse])
async def mark_growth_followed(
    alert_id: uuid.UUID,
    db: DBSession,
    principal: TeacherPrincipal = Depends(get_teacher_principal),
):
    data = await _alert_service(db).ack(alert_id, principal.user.id, class_name=principal.class_name)
    return ResponseModel(data=TeacherAlertAckResponse(id=data["id"], status=data["status"], acked_at=data["acked_at"]))


@router.post("/{alert_id}/unack", response_model=ResponseModel[TeacherAlertAckResponse])
async def unmark_growth_followed(
    alert_id: uuid.UUID,
    db: DBSession,
    principal: TeacherPrincipal = Depends(get_teacher_principal),
):
    """取消「已关注」，恢复为待关注状态。"""
    data = await _alert_service(db).unack(alert_id, class_name=principal.class_name)
    return ResponseModel(data=TeacherAlertAckResponse(id=data["id"], status=data["status"], acked_at=data["acked_at"]))


@router.delete("/{alert_id}", response_model=ResponseModel[bool])
async def dismiss_growth_focus(
    alert_id: uuid.UUID,
    db: DBSession,
    principal: TeacherPrincipal = Depends(get_teacher_principal),
):
    ok = await _alert_service(db).dismiss(alert_id, class_name=principal.class_name)
    return ResponseModel(data=ok)
