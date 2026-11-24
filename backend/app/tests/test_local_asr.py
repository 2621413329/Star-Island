import json
from pathlib import Path

import httpx
import pytest

from app.core.config import settings
from app.services.moment_transcription_service import MomentTranscriptionService
from scripts.local_sensevoice_server import clean_sensevoice_text


class _FakeResponse:
    def __init__(self, status_code: int, payload: dict):
        self.status_code = status_code
        self._payload = payload
        self.text = json.dumps(payload)

    def json(self):
        return self._payload


class _FakeClient:
    def __init__(self, *args, **kwargs):
        self.kwargs = kwargs

    async def __aenter__(self):
        return self

    async def __aexit__(self, *args):
        return None

    async def post(self, url, content=None, headers=None):
        assert url == "http://127.0.0.1:8091/transcribe"
        assert content == b"audio-bytes"
        assert headers["X-Filename"].endswith(".m4a")
        return _FakeResponse(200, {"text": "今天心情很好"})


@pytest.mark.asyncio
async def test_transcribe_uses_local_service_without_cloud_key(monkeypatch, tmp_path: Path):
    audio = tmp_path / "voice.m4a"
    audio.write_bytes(b"audio-bytes")
    monkeypatch.setattr(settings, "LOCAL_ASR_BASE_URL", "http://127.0.0.1:8091")
    monkeypatch.setattr(settings, "LOCAL_ASR_TIMEOUT_SEC", 30)
    monkeypatch.setattr(settings, "QWEN_API_KEY", None)
    monkeypatch.setattr(httpx, "AsyncClient", _FakeClient)

    text = await MomentTranscriptionService().transcribe(audio)

    assert text == "今天心情很好"


def test_clean_sensevoice_text_strips_tags():
    raw = "<|zh|><|NEUTRAL|><|Speech|><|withitn|>今天天气不错"
    assert clean_sensevoice_text(raw) == "今天天气不错"
