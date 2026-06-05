import uuid
from datetime import date

from fastapi import APIRouter, Depends, Query

from app.api.deps import DBSession
from app.api.teacher_deps import TeacherPrincipal, get_teacher_principal
from app.repositories.daily_mood_report_repository import DailyMoodReportRepository
from app.repositories.profile_repository import DailyMomentRepository, ProfileRepository
from app.repositories.student_repository import StudentRepository
from app.schemas.common import ResponseModel
from app.schemas.profile import TeacherDailyMoodReportRead
from app.services.teacher_mood_report_service import TeacherMoodReportService

router = APIRouter(prefix="/teacher/mood-reports", tags=["教师-今日心情"])


def get_teacher_mood_service(db: DBSession) -> TeacherMoodReportService:
    return TeacherMoodReportService(
        DailyMoodReportRepository(db),
        StudentRepository(db),
        DailyMomentRepository(db),
        ProfileRepository(db),
    )


@router.get("/today", response_model=ResponseModel[list[TeacherDailyMoodReportRead]])
async def list_today_mood_reports(
    db: DBSession,
    principal: TeacherPrincipal = Depends(get_teacher_principal),
    report_date: date | None = Query(default=None),
):
    """教师端：查看当日已上传心情报告（本班脱敏数据）。"""
    items = await get_teacher_mood_service(db).list_today(
        report_date, class_name=principal.class_name
    )
    return ResponseModel(data=[TeacherDailyMoodReportRead(**item) for item in items])


@router.get("/today/{student_id}", response_model=ResponseModel[TeacherDailyMoodReportRead])
async def get_student_today_mood_report(
    student_id: uuid.UUID,
    db: DBSession,
    principal: TeacherPrincipal = Depends(get_teacher_principal),
    report_date: date | None = Query(default=None),
):
    """教师端：按 student_id 查看本班单个学生当日心情报告。"""
    item = await get_teacher_mood_service(db).get_by_student(
        student_id, report_date, class_name=principal.class_name
    )
    if not item:
        from app.exceptions.business import BusinessException

        raise BusinessException("该学生今日尚未上传心情报告", 404)
    return ResponseModel(data=TeacherDailyMoodReportRead(**item))
