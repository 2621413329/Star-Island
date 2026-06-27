from datetime import date, timedelta
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.exceptions.business import BusinessException
from app.schemas.profile import DailyMomentCreate, DailyMomentTagsUpdate
from app.services.profile_service import ProfileService


def _moment(*, moment_date: date):
    return SimpleNamespace(
        id="m1",
        user_id="u1",
        moment_date=moment_date,
        content_type="text",
        note="历史记录",
        speech_text=None,
        voice_url=None,
        event_tags=["生活"],
        emotion_tag="calm",
        primary_tag="生活",
        secondary_tags=[],
        growth_points=[],
        ai_emotion="平静",
        companion_scene={},
        companion_pose="breathing",
        visual_payload={"expression": "calm", "ai_emotion": "平静"},
        photos=[],
    )


@pytest.mark.asyncio
async def test_update_moment_allows_past_date():
    past = date.today() - timedelta(days=3)
    moment = _moment(moment_date=past)
    profile = SimpleNamespace(companion_style="chibi", today_mood=None)

    service = ProfileService(MagicMock(), MagicMock())
    service.get_profile = AsyncMock(return_value=profile)
    service.moment_repo.get_by_id_and_user = AsyncMock(return_value=moment)
    service.moment_repo.save = AsyncMock(side_effect=lambda m: m)
    service.refresh_growth_state = AsyncMock()
    service._resolve_moment_tags = AsyncMock(
        return_value=(["生活"], "calm", "生活", [], [], "平静")
    )
    service._build_companion_scene = AsyncMock(
        return_value={
            "companion_scene": {"s": 1},
            "companion_pose": "breathing",
            "visual_payload": {"expression": "calm"},
        }
    )

    payload = DailyMomentCreate(note="更新后的历史记录")
    saved = await service.update_moment("u1", "m1", payload)

    assert saved.note == "更新后的历史记录"
    service.moment_repo.save.assert_awaited_once()


@pytest.mark.asyncio
async def test_update_moment_rejects_future_date():
    future = date.today() + timedelta(days=1)
    moment = _moment(moment_date=future)
    service = ProfileService(MagicMock(), MagicMock())
    service.moment_repo.get_by_id_and_user = AsyncMock(return_value=moment)

    payload = DailyMomentCreate(note="不应成功")
    with pytest.raises(BusinessException, match="未来"):
        await service.update_moment("u1", "m1", payload)


@pytest.mark.asyncio
async def test_delete_moment_allows_past_date():
    past = date.today() - timedelta(days=2)
    moment = _moment(moment_date=past)

    service = ProfileService(MagicMock(), MagicMock())
    service.moment_repo.get_by_id_and_user = AsyncMock(return_value=moment)
    service.moment_repo.delete_by_id_and_user = AsyncMock(return_value=True)
    service.moment_photos.delete_moment_dir = MagicMock()
    service.moment_voice.delete_voice_file = MagicMock()
    service.refresh_growth_state = AsyncMock()
    service.mood_report_repo = None
    service.moment_repo.list_by_user_and_date = AsyncMock(return_value=[])

    await service.delete_moment("u1", "m1")

    service.moment_repo.delete_by_id_and_user.assert_awaited_once()


@pytest.mark.asyncio
async def test_update_moment_tags_allows_past_date():
    past = date.today() - timedelta(days=1)
    moment = _moment(moment_date=past)
    profile = SimpleNamespace(companion_style="chibi")

    service = ProfileService(MagicMock(), MagicMock())
    service.get_profile = AsyncMock(return_value=profile)
    service.moment_repo.get_by_id_and_user = AsyncMock(return_value=moment)
    service.moment_repo.save = AsyncMock(side_effect=lambda m: m)
    service.refresh_growth_state = AsyncMock()
    service._resolve_manual_moment_tags = AsyncMock(
        return_value=(["学习"], "calm", "学习", ["专注"], [], "平静")
    )
    service._build_companion_scene = AsyncMock(
        return_value={
            "companion_scene": {"s": 1},
            "companion_pose": "breathing",
            "visual_payload": {"expression": "calm"},
        }
    )

    payload = DailyMomentTagsUpdate(primary_tag="学习", secondary_tags=["专注"])
    saved = await service.update_moment_tags("u1", "m1", payload)

    assert saved.primary_tag == "学习"
    service.moment_repo.save.assert_awaited_once()
