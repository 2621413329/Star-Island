import uuid
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.schemas.profile import ProfileMoodUpdate
from app.services.profile_service import ProfileService


@pytest.mark.asyncio
async def test_update_mood_keeps_saved_mood_when_growth_refresh_fails():
    user_id = uuid.uuid4()
    profile = SimpleNamespace(user_id=user_id, today_mood=None)
    service = ProfileService(MagicMock(), MagicMock())
    service.get_profile = AsyncMock(return_value=profile)
    service.profile_repo.save = AsyncMock(side_effect=lambda item: item)
    service.profile_repo.db.rollback = AsyncMock()
    service.refresh_growth_state = AsyncMock(side_effect=RuntimeError("growth down"))

    saved = await service.update_mood(
        user_id,
        ProfileMoodUpdate(today_mood="kai_xin"),
    )

    assert saved.today_mood == "kai_xin"
    service.profile_repo.save.assert_awaited()
    service.profile_repo.db.rollback.assert_awaited()
