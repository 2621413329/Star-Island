import uuid

from fastapi import APIRouter, Depends, Query

from app.api.deps import DBSession
from app.api.teacher_deps import TeacherPrincipal, get_teacher_principal
from app.repositories.daily_mood_report_repository import DailyMoodReportRepository
from app.repositories.profile_repository import DailyMomentRepository, ProfileRepository
from app.repositories.student_repository import StudentRepository
from app.repositories.teacher_alert_repository import TeacherAlertRepository
from app.repositories.teacher_follow_up_repository import TeacherFollowUpRepository
from app.schemas.common import ResponseModel
from app.schemas.growth_observation import (
    GrowthArchiveRead,
    RiskDismissRead,
    TeacherFollowUpCreate,
    TeacherFollowUpRead,
)
from app.services.growth_archive_service import GrowthArchiveService
from app.services.growth_risk_review_service import GrowthRiskReviewService

router = APIRouter(prefix="/teacher/students", tags=["教师-成长观察"])


def _archive_service(db: DBSession) -> GrowthArchiveService:
    return GrowthArchiveService(
        DailyMoodReportRepository(db),
        DailyMomentRepository(db),
        ProfileRepository(db),
        StudentRepository(db),
        TeacherFollowUpRepository(db),
    )


def _risk_review_service(db: DBSession) -> GrowthRiskReviewService:
    return GrowthRiskReviewService(
        DailyMoodReportRepository(db),
        DailyMomentRepository(db),
        ProfileRepository(db),
        StudentRepository(db),
        TeacherAlertRepository(db),
    )


@router.post(
    "/{student_id}/risk-exposures/{moment_id}/dismiss",
    response_model=ResponseModel[RiskDismissRead],
)
async def dismiss_risk_exposure(
    student_id: uuid.UUID,
    moment_id: uuid.UUID,
    db: DBSession,
    principal: TeacherPrincipal = Depends(get_teacher_principal),
):
    """教师复核：确认非危险信号后撤销备注暴露并刷新洞察。"""
    data = await _risk_review_service(db).dismiss_critical_moment(
        student_id, moment_id, class_name=principal.class_name
    )
    return ResponseModel(data=RiskDismissRead(**data))


@router.get("/{student_id}/growth-archive", response_model=ResponseModel[GrowthArchiveRead])
async def get_growth_archive(
    student_id: uuid.UUID,
    db: DBSession,
    principal: TeacherPrincipal = Depends(get_teacher_principal),
    days: int = Query(default=7, ge=1, le=90),
):
    data = await _archive_service(db).get_archive(
        student_id, class_name=principal.class_name, days=days
    )
    return ResponseModel(data=GrowthArchiveRead(**data))


@router.post("/{student_id}/follow-ups", response_model=ResponseModel[TeacherFollowUpRead])
async def create_follow_up(
    student_id: uuid.UUID,
    payload: TeacherFollowUpCreate,
    db: DBSession,
    principal: TeacherPrincipal = Depends(get_teacher_principal),
):
    data = await _archive_service(db).add_follow_up(
        student_id,
        principal.user.id,
        class_name=principal.class_name,
        action=payload.action,
        note=payload.note,
    )
    return ResponseModel(data=TeacherFollowUpRead(**data))
