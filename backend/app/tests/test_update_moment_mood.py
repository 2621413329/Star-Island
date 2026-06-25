from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.schemas.profile import DailyMomentCreate
from app.services.profile_service import ProfileService


@pytest.mark.asyncio
async def test_update_moment_ai_emotion_sets_label_and_keeps_ai_field():
    moment = SimpleNamespace(
        id="m1",
        user_id="u1",
        moment_date=__import__("datetime").date.today(),
        content_type="text",
        note="今天很开心",
        speech_text=None,
        event_tags=["生活"],
        emotion_tag="calm",
        primary_tag="生活",
        secondary_tags=[],
        growth_points=[],
        ai_emotion="平静",
        companion_scene={},
        companion_pose="breathing",
        visual_payload={"expression": "calm", "ai_emotion": "平静"},
    )
    profile = SimpleNamespace(companion_style="chibi", today_mood=None)

    service = ProfileService(MagicMock(), MagicMock())
    service.get_profile = AsyncMock(return_value=profile)
    service.moment_repo.get_by_id_and_user = AsyncMock(return_value=moment)
    service.moment_repo.save = AsyncMock(side_effect=lambda m: m)
    service.refresh_growth_state = AsyncMock()
    service._resolve_moment_tags = AsyncMock(
        return_value=(["生活"], "happy", "生活", [], [], "开心")
    )
    service._build_companion_scene = AsyncMock(
        return_value={
            "companion_scene": {"s": 1},
            "companion_pose": "breathing",
            "visual_payload": {"expression": "happy"},
        }
    )

    payload = DailyMomentCreate(
        note="今天很开心",
        primary_tag="生活",
        secondary_tags=[],
        ai_emotion="开心",
    )
    saved = await service.update_moment("u1", "m1", payload)

    assert saved.emotion_tag == "happy"
    assert saved.ai_emotion == "开心"
    assert saved.visual_payload["ai_emotion"] == "开心"
    service._build_companion_scene.assert_awaited_once()
    call_kwargs = service._build_companion_scene.await_args.kwargs
    assert call_kwargs["note"] == "今天很开心"
    assert call_kwargs["emotion_tag"] == "happy"
