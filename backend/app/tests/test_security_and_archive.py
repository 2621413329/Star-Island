from datetime import date, datetime, timezone
from types import SimpleNamespace
from uuid import uuid4

import pytest

from app.api import deps
from app.exceptions.business import BusinessException
from app.models.profile import DailyMoment
from app.models.user import User
from app.services.growth_archive_service import GrowthArchiveService
from app.services.moment_story_service import format_moment_story_detail


class _RoleRepositoryStub:
    is_admin = False

    def __init__(self, db):
        self.db = db

    async def user_has_role(self, user_id, role_name: str) -> bool:
        return role_name == "admin" and self.is_admin


@pytest.mark.asyncio
async def test_get_current_admin_rejects_non_admin(monkeypatch):
    monkeypatch.setattr(deps, "RoleRepository", _RoleRepositoryStub)
    _RoleRepositoryStub.is_admin = False
    user = User(id=uuid4(), username="student", email="s@example.com", password_hash="x")

    with pytest.raises(BusinessException) as exc:
        await deps.get_current_admin(user, db=None)

    assert exc.value.code == 403
    assert "管理员" in exc.value.message


@pytest.mark.asyncio
async def test_get_current_admin_allows_admin(monkeypatch):
    monkeypatch.setattr(deps, "RoleRepository", _RoleRepositoryStub)
    _RoleRepositoryStub.is_admin = True
    user = User(id=uuid4(), username="admin", email="a@example.com", password_hash="x")

    result = await deps.get_current_admin(user, db=None)

    assert result is user


def test_moment_story_detail_hides_note_by_default():
    moment = DailyMoment(event_tags=["学习", "课堂"], emotion_tag="sad", note="不想活")

    assert format_moment_story_detail(moment) == "学业-课堂"
    assert format_moment_story_detail(moment, include_note=True) == "学业-课堂：不想活"


class _StudentRepo:
    def __init__(self, student):
        self.student = student

    async def get_by_id(self, student_id):
        return self.student if student_id == self.student.id else None


class _ReportRepo:
    async def list_by_student_since(self, student_id, since, *, class_name):
        return []


class _MomentRepo:
    def __init__(self, moments):
        self.moments = moments

    async def list_by_user_since(self, user_id, since):
        return self.moments


class _ProfileRepo:
    def __init__(self, profile):
        self.profile = profile

    async def get_by_student_id(self, student_id):
        return self.profile if student_id == self.profile.student_id else None


class _FollowUpRepo:
    def __init__(self, follow_ups):
        self.follow_ups = follow_ups

    async def list_by_student(self, student_id, *, limit=20):
        return self.follow_ups[:limit]


@pytest.mark.asyncio
async def test_growth_archive_returns_timeline_risks_and_follow_ups_without_exposing_notes():
    student_id = uuid4()
    user_id = uuid4()
    moment_id = uuid4()
    student = SimpleNamespace(id=student_id, name="小明", class_name="家人测试班")
    profile = SimpleNamespace(user_id=user_id, student_id=student_id)
    moment = SimpleNamespace(
        id=moment_id,
        user_id=user_id,
        student_id=student_id,
        event_tags=["学习", "课堂"],
        emotion_tag="sad",
        note="今天活不下去",
        companion_scene="study",
        companion_pose="breathing",
        visual_payload={},
        moment_date=date.today(),
        created_at=datetime.now(timezone.utc),
    )
    follow_up = SimpleNamespace(
        id=uuid4(),
        action="observing",
        note="已联系班主任持续观察",
        created_at=datetime.now(timezone.utc),
    )
    service = GrowthArchiveService(
        _ReportRepo(),
        _MomentRepo([moment]),
        _ProfileRepo(profile),
        _StudentRepo(student),
        _FollowUpRepo([follow_up]),
    )

    archive = await service.get_archive(student_id, class_name="家人测试班")

    assert archive["timeline"]
    assert archive["risk_exposures"]
    assert archive["follow_ups"][0]["id"] == follow_up.id
    assert archive["timeline"][0]["story_detail"] == "学业-课堂"
    assert archive["timeline"][0]["note"] is None
    assert archive["timeline"][0]["note_exposed"] is False
    assert archive["risk_exposures"][0]["note"] == ""
    assert archive["daily_records"][0]["danger_records"][0]["note"] == ""
