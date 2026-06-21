from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.schemas.profile import DailyMomentTagsUpdate
from app.services.profile_service import ProfileService


@pytest.mark.asyncio
async def test_update_moment_tags_for_voice_without_note(monkeypatch):
    moment = SimpleNamespace(
        id="m1",
        user_id="u1",
        moment_date=__import__("datetime").date.today(),
        content_type="voice",
        note=None,
        speech_text="今天练习了篮球",
        event_tags=["生活"],
        emotion_tag="calm",
        primary_tag="生活",
        secondary_tags=[],
        growth_points=[],
        ai_emotion="平静",
        companion_scene={},
        companion_pose={},
        visual_payload={},
    )
    profile = SimpleNamespace(companion_style="chibi", today_mood=None)

    service = ProfileService(MagicMock(), MagicMock())
    service.get_profile = AsyncMock(return_value=profile)
    service.moment_repo.get_by_id_and_user = AsyncMock(return_value=moment)
    service.moment_repo.save = AsyncMock(side_effect=lambda m: m)
    service.refresh_growth_state = AsyncMock()
    service._resolve_manual_moment_tags = AsyncMock(
        return_value=(["运动"], "happy", "运动", ["篮球"], [], "开心")
    )
    service.scene_service.build = MagicMock(
        return_value={
            "companion_scene": {"s": 1},
            "companion_pose": "idle",
            "visual_payload": {},
        }
    )

    payload = DailyMomentTagsUpdate(
        primary_tag="运动",
        secondary_tags=["篮球"],
        ai_emotion="开心",
    )
    saved = await service.update_moment_tags("u1", "m1", payload)

    assert saved.primary_tag == "运动"
    service._resolve_manual_moment_tags.assert_awaited_once()
    service.refresh_growth_state.assert_awaited_once()
