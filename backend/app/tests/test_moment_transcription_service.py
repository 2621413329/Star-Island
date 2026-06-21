from app.services.moment_transcription_service import MomentTranscriptionService


def test_parse_transcription_payload_from_transcripts():
    payload = {
        "transcripts": [
            {
                "channel_id": 0,
                "text": "今天和同事一起完成了项目，感觉很有成就感。",
            }
        ]
    }
    text = MomentTranscriptionService.parse_transcription_payload(payload)
    assert text == "今天和同事一起完成了项目，感觉很有成就感。"


def test_parse_transcription_payload_joins_multiple_transcripts():
    payload = {
        "transcripts": [
            {"text": "第一段。"},
            {"text": "第二段。"},
        ]
    }
    text = MomentTranscriptionService.parse_transcription_payload(payload)
    assert text == "第一段。 第二段。"


def test_extract_transcription_text_from_output_with_url(monkeypatch):
    service = MomentTranscriptionService()
    output = {
        "results": [
            {
                "subtask_status": "SUCCEEDED",
                "transcription_url": "https://example.com/result.json",
            }
        ]
    }

    async def fake_fetch(url: str) -> str:
        assert url == "https://example.com/result.json"
        return "今天心情很好，去公园散步了。"

    monkeypatch.setattr(service, "_fetch_transcription_json", fake_fetch)

    import asyncio

    text = asyncio.run(service._extract_transcription_text(output))
    assert text == "今天心情很好，去公园散步了。"
