from __future__ import annotations

import json
import re
from typing import Any

from app.core.config import settings
from app.rag.qwen_provider import QwenLLMProvider

ACTION_PROMPT = """你是成长伙伴「小星」的动画导演。根据学生今日事件标签、心情、补充文字，设计可执行的2D小人表演方案。
要求：结合标签与文字理解具体情境（如学业+难过+练习册错题 → 小人看练习册、伤心表情）。
只输出 JSON，不要 Markdown。
字段说明：
- expression: happy|sad|calm|angry|thinking|hurt 之一（小人面部表情）
- prop: none|workbook|ball|friends|home|music|stars|umbrella 之一（手持/身边道具）
- animation_type: slump_read|celebrate|wave|think|shake|hug|sit|look_down|cheer 之一（2秒动作）
- companion_tint: 十六进制颜色，融合事件+心情（如学业伤心可用灰蓝 #90A4AE）
- scene_title: 8字内场景标题，如「练习册前的片刻」
- performance_hint: 20字内动作描述
- waiting_lines: 3句中文等待文案，每句≤14字
- companion_pose: breathing|float|blink

输入：
"""

MOOD_TINT = {
    "happy": "#FFD54F",
    "calm": "#A8DFCF",
    "thinking": "#B0BEC5",
    "sad": "#90A4AE",
    "angry": "#FF8A65",
}

EVENT_PROP_HINTS = {
    "学习": "workbook",
    "朋友": "friends",
    "运动": "ball",
    "家庭": "home",
    "兴趣": "music",
}


class CompanionActionAIService:
    def __init__(self, llm: QwenLLMProvider | None = None):
        self._llm = llm

    def _llm_or_none(self) -> QwenLLMProvider | None:
        if self._llm:
            return self._llm
        if not settings.QWEN_API_KEY:
            return None
        try:
            return QwenLLMProvider()
        except Exception:
            return None

    async def enrich(
        self,
        *,
        companion_style: str,
        emotion_tag: str,
        event_tags: list[str],
        note: str | None,
        base_scene: dict[str, Any],
    ) -> dict[str, Any]:
        fallback = self._fallback(emotion_tag, event_tags, note)
        llm = self._llm_or_none()
        spec = fallback
        if llm:
            payload = {
                "companion_style": companion_style,
                "emotion_tag": emotion_tag,
                "event_tags": event_tags,
                "note": note or "",
            }
            try:
                raw = await llm.generate(
                    ACTION_PROMPT + json.dumps(payload, ensure_ascii=False),
                    max_tokens=380,
                    temperature=0.55,
                )
                parsed = self._parse_json(raw)
                if parsed:
                    spec = self._normalize_spec(parsed, emotion_tag, event_tags, note)
                    spec["ai_generated"] = True
            except Exception:
                pass

        visual = dict(base_scene.get("visual_payload") or {})
        visual.update(spec)
        scene_id = f"{companion_style}_{spec.get('animation_type')}_{event_tags[0] if event_tags else 'other'}"
        return {
            **base_scene,
            "companion_scene": scene_id,
            "companion_pose": spec.get("companion_pose", "breathing"),
            "visual_payload": visual,
            "action_type": spec.get("animation_type", "wave"),
            "waiting_lines": spec.get("waiting_lines", []),
            "performance_ms": 2000,
            "performance_hint": spec.get("performance_hint"),
        }

    def _normalize_spec(
        self, parsed: dict[str, Any], emotion_tag: str, event_tags: list[str], note: str | None
    ) -> dict[str, Any]:
        fb = self._fallback(emotion_tag, event_tags, note)
        allowed_expr = {"happy", "sad", "calm", "angry", "thinking", "hurt"}
        allowed_prop = {"none", "workbook", "ball", "friends", "home", "music", "stars", "umbrella"}
        allowed_anim = {
            "slump_read", "celebrate", "wave", "think", "shake", "hug", "sit", "look_down", "cheer",
        }
        expr = parsed.get("expression") if parsed.get("expression") in allowed_expr else fb["expression"]
        prop = parsed.get("prop") if parsed.get("prop") in allowed_prop else fb["prop"]
        anim = parsed.get("animation_type") if parsed.get("animation_type") in allowed_anim else fb["animation_type"]
        tint = parsed.get("companion_tint") if self._valid_hex(parsed.get("companion_tint")) else fb["companion_tint"]
        return {
            "expression": expr,
            "prop": prop,
            "animation_type": anim,
            "action_type": anim,
            "companion_tint": tint,
            "scene_title": (parsed.get("scene_title") or fb["scene_title"])[:16],
            "performance_hint": (parsed.get("performance_hint") or fb["performance_hint"])[:40],
            "waiting_lines": parsed.get("waiting_lines") or fb["waiting_lines"],
            "companion_pose": parsed.get("companion_pose") if parsed.get("companion_pose") else fb["companion_pose"],
            "island_mood": emotion_tag,
            "event_tags": event_tags,
            "performance_ms": 2000,
        }

    def _fallback(self, emotion_tag: str, event_tags: list[str], note: str | None) -> dict[str, Any]:
        tag = event_tags[0] if event_tags else "其它"
        prop = self._prop_from_context(tag, note)
        expr = {
            "happy": "happy",
            "calm": "calm",
            "thinking": "thinking",
            "sad": "sad",
            "angry": "angry",
        }.get(emotion_tag, "calm")
        if note and any(k in note for k in ("错", "失败", "难过", "哭", "糟")):
            expr = "sad" if emotion_tag in ("sad", "angry", "thinking") else expr
        anim = self._anim_from_context(emotion_tag, prop, note)
        title = self._title_from_context(tag, note, emotion_tag)
        lines = [
            "小星读懂了你的故事…",
            title,
            "正在为你准备表演",
        ]
        return {
            "expression": expr,
            "prop": prop,
            "animation_type": anim,
            "action_type": anim,
            "companion_tint": self._tint_from_context(emotion_tag, tag, note),
            "scene_title": title,
            "performance_hint": self._hint_from_context(tag, note, emotion_tag),
            "waiting_lines": lines,
            "companion_pose": "float" if emotion_tag == "happy" else "breathing",
            "island_mood": emotion_tag,
            "event_tags": event_tags,
            "performance_ms": 2000,
            "ai_generated": False,
        }

    def _prop_from_context(self, tag: str, note: str | None) -> str:
        if note:
            if any(k in note for k in ("练习册", "作业", "题", "考试", "学", "课")):
                return "workbook"
            if any(k in note for k in ("球", "跑", "泳", "运动")):
                return "ball"
            if any(k in note for k in ("朋友", "同学", "一起")):
                return "friends"
            if any(k in note for k in ("家", "爸妈", "父母")):
                return "home"
        return EVENT_PROP_HINTS.get(tag, "stars")

    def _anim_from_context(self, emotion: str, prop: str, note: str | None) -> str:
        if prop == "workbook" and emotion in ("sad", "thinking", "angry"):
            return "slump_read"
        if prop == "workbook" and emotion == "happy":
            return "cheer"
        if emotion == "happy":
            return "celebrate"
        if emotion == "sad":
            return "look_down" if prop == "none" else "slump_read"
        if emotion == "angry":
            return "shake"
        if emotion == "thinking":
            return "think"
        return "wave"

    def _tint_from_context(self, emotion: str, tag: str, note: str | None) -> str:
        base = MOOD_TINT.get(emotion, "#A8DFCF")
        if tag == "学习" and emotion in ("sad", "thinking"):
            return "#90A4AE"
        if tag == "运动" and emotion == "happy":
            return "#81C784"
        if note and ("错" in note or "难过" in note):
            return "#90A4AE"
        return base

    def _title_from_context(self, tag: str, note: str | None, emotion: str) -> str:
        if note and "练习册" in note:
            return "练习册前的片刻"
        if tag == "学习":
            return "学业故事里的小星"
        return f"{tag}的小岛时刻"[:12]

    def _hint_from_context(self, tag: str, note: str | None, emotion: str) -> str:
        if note and len(note) > 4:
            return f"小星{'轻轻叹气看着' if emotion == 'sad' else '看着'}{self._prop_label(tag)}"
        return "小星缓缓转过身来"

    def _prop_label(self, tag: str) -> str:
        return {"学习": "练习册", "朋友": "朋友", "运动": "球场", "家庭": "家", "兴趣": "画板"}.get(tag, "远方")

    def _valid_hex(self, value: Any) -> bool:
        if not isinstance(value, str):
            return False
        return bool(re.fullmatch(r"#[0-9A-Fa-f]{6}", value.strip()))

    def _parse_json(self, raw: str) -> dict[str, Any] | None:
        text = raw.strip()
        match = re.search(r"\{[\s\S]*\}", text)
        if not match:
            return None
        try:
            return json.loads(match.group())
        except json.JSONDecodeError:
            return None
