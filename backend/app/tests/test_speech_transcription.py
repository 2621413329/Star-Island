import uuid
from io import BytesIO
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import UploadFile

from app.services.profile_service import ProfileService


@pytest.mark.asyncio
async def test_transcribe_speech_note_returns_text(monkeypatch, tmp_path):
    user_id = uuid.uuid4()
    service = ProfileService(
        profile_repo=MagicMock(),
        moment_repo=MagicMock(),
    )
    service.moment_voice.root = tmp_path

    async def fake_read_validated_voice(upload, *, voice_duration):
        assert voice_duration == 3
        return b"fake-audio"

    async def fake_transcribe(path, *, voice_url=None):
        assert path.is_file()
        return "今天心情很好。"

    service.moment_voice.read_validated_voice = fake_read_validated_voice
    monkeypatch.setattr(
        "app.services.profile_service.MomentTranscriptionService",
        lambda: MagicMock(transcribe=AsyncMock(side_effect=fake_transcribe)),
    )

    upload = UploadFile(filename="voice.m4a", file=BytesIO(b"fake-audio"))
    text = await service.transcribe_speech_note(
        user_id,
        upload,
        voice_duration=3,
    )
    assert text == "今天心情很好。"
