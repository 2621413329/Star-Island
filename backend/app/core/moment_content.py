"""故事正文读取：文字故事用 note，语音故事用 speech_text（供 AI 分析）。"""

from __future__ import annotations

from app.models.profile import DailyMoment

CONTENT_TYPE_TEXT = "text"
CONTENT_TYPE_VOICE = "voice"


def get_story_content(moment: DailyMoment) -> str:
    content_type = (moment.content_type or CONTENT_TYPE_TEXT).strip().lower()
    if content_type == CONTENT_TYPE_VOICE:
        return (moment.speech_text or "").strip()
    return (moment.note or "").strip()


def is_voice_moment(moment: DailyMoment) -> bool:
    return (moment.content_type or CONTENT_TYPE_TEXT).strip().lower() == CONTENT_TYPE_VOICE
