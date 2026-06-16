"""Rule-based companion scene for MVP; replace with LLM/image gen later."""

from __future__ import annotations

import re
from typing import Any

EVENT_SCENE_MAP: dict[str, str] = {
    "学习": "study",
    "朋友": "friendship",
    "运动": "sport",
    "家庭": "family",
    "兴趣": "hobby",
    "其它": "stargaze",
    "工作": "study",
    "健康": "sport",
    "人际": "friendship",
    "生活": "family",
    "创作": "hobby",
    "财务": "stargaze",
    "成就": "stargaze",
    "情绪": "stargaze",
    "灵感": "stargaze",
    "特殊事件": "stargaze",
}

MOOD_MODIFIER: dict[str, str] = {
    "happy": "bright",
    "calm": "soft",
    "thinking": "quiet",
    "sad": "gentle",
    "angry": "cool",
}

NOTE_KEYWORDS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"球|跑|泳|赛|锻炼|运动"), "sport"),
    (re.compile(r"朋友|同学|一起|聚会"), "friendship"),
    (re.compile(r"家|爸妈|父母|家人"), "family"),
    (re.compile(r"书|课|考试|作业|学"), "study"),
    (re.compile(r"画|乐|游戏|琴|舞"), "hobby"),
]


class CompanionSceneService:
    def build(
        self,
        *,
        companion_style: str,
        emotion_tag: str,
        event_tags: list[str],
        note: str | None = None,
    ) -> dict[str, Any]:
        base = self._resolve_base_scene(event_tags, note)
        mood_mod = MOOD_MODIFIER.get(emotion_tag, "soft")
        scene_id = f"{companion_style}_{base}_{mood_mod}"

        pose = "breathing"
        if emotion_tag == "happy":
            pose = "float"
        elif emotion_tag == "thinking":
            pose = "blink"

        animation = {
            "happy": {"type": "float", "amplitude": 6, "duration_ms": 2800},
            "calm": {"type": "breathing", "amplitude": 4, "duration_ms": 3200},
            "thinking": {"type": "blink", "interval_ms": 4000},
            "sad": {"type": "breathing", "amplitude": 3, "duration_ms": 3600},
            "angry": {"type": "breathing", "amplitude": 5, "duration_ms": 3000},
        }.get(emotion_tag, {"type": "breathing", "amplitude": 4, "duration_ms": 3200})

        return {
            "companion_scene": scene_id,
            "companion_pose": pose,
            "visual_payload": {
                "companion_style": companion_style,
                "base_scene": base,
                "mood_modifier": mood_mod,
                "emotion_tag": emotion_tag,
                "event_tags": event_tags,
                "note_hint": self._note_hint(note),
                "animation": animation,
            },
        }

    def _resolve_base_scene(self, event_tags: list[str], note: str | None) -> str:
        if note:
            for pattern, scene in NOTE_KEYWORDS:
                if pattern.search(note):
                    return scene
        for tag in event_tags:
            if tag in EVENT_SCENE_MAP:
                return EVENT_SCENE_MAP[tag]
        return "stargaze"

    def _note_hint(self, note: str | None) -> str | None:
        if not note:
            return None
        trimmed = note.strip()
        return trimmed[:80] if trimmed else None
