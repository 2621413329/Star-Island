from __future__ import annotations

import asyncio
import json
import random
import re
from typing import Any

from loguru import logger

from app.core.config import settings
from app.core.companion_dialogue import (
    NICKNAME_PLACEHOLDER,
    normalize_dialogue_template,
)
from app.core.companion_prop_labels import ensure_visual_prop_label
from app.rag.qwen_provider import QwenLLMProvider

ACTION_PROMPT = """你是成长伙伴「小星」的动画导演。根据用户今日事件标签、心情、补充文字，设计可执行的2D小人表演方案。
要求：结合标签与文字理解具体情境（如学业+难过+练习册错题 → 小人看练习册、伤心表情）。
只输出 JSON，不要 Markdown。
字段说明：
- expression: happy|sad|calm|angry|thinking|hurt 之一（小人面部表情）
- prop: none|workbook|exam_paper|ball|badminton_racket|game_controller|running_shoes|friends|chat_bubbles|heart|home|music|stars|umbrella|trophy|medal|glasses 之一（情境配饰，生成后持久保留）
- 示例：游戏通关→game_controller；跑步不错→running_shoes；被老师骂→chat_bubbles
- animation_type: slump_read|celebrate|wave|think|shake|hug|sit|look_down|cheer|swing|lose_slump|reach_out|comfort 之一（2秒动作）
- companion_tint: 十六进制颜色，融合事件+心情（如学业伤心可用灰蓝 #90A4AE）
- scene_title: 8字内场景标题，如「练习册前的片刻」
- performance_hint: 20字内动作描述
- waiting_lines: 6句中文等待文案，每句≤14字，需贴合一级标签和具体关键词
- story_summary_lines: 3句中文对话式陪伴语，每句≤32字，像朋友聊天对用户说话（详情页点击小人时展示）。称呼用户时**必须**使用占位符 {nickname}，不要使用真实姓名，例如「{nickname}，今天辛苦啦」「今天生活对我们{nickname}怎么样呀」。至少2句需包含 {nickname}。
- companion_pose: breathing|float|blink

输入：
"""

AI_CALL_TIMEOUT_SEC = 35.0

MOOD_TINT = {
    "happy": "#FFD54F",
    "calm": "#A8DFCF",
    "thinking": "#B0BEC5",
    "sad": "#90A4AE",
    "angry": "#FF8A65",
}

ALLOWED_PROPS = {
    "none",
    "workbook",
    "exam_paper",
    "ball",
    "basketball",
    "badminton_racket",
    "game_controller",
    "running_shoes",
    "water_bottle",
    "friends",
    "chat_bubbles",
    "heart",
    "home",
    "music",
    "palette",
    "stars",
    "umbrella",
    "trophy",
    "medal",
    "glasses",
}

SPECIFIC_PROPS = {
    "game_controller",
    "running_shoes",
    "exam_paper",
    "badminton_racket",
    "chat_bubbles",
    "umbrella",
    "trophy",
    "medal",
    "glasses",
    "music",
}

EVENT_PROP_HINTS = {
    "学习": "workbook",
    "朋友": "friends",
    "运动": "ball",
    "家庭": "home",
    "兴趣": "music",
}

EVENT_PROP_POOLS: dict[str, list[str]] = {
    "学习": ["workbook", "exam_paper", "glasses", "trophy", "medal"],
    "朋友": ["friends", "chat_bubbles", "heart", "umbrella"],
    "运动": [
        "ball",
        "basketball",
        "running_shoes",
        "badminton_racket",
        "water_bottle",
        "trophy",
    ],
    "家庭": ["home", "heart", "umbrella", "chat_bubbles", "trophy"],
    "兴趣": ["music", "game_controller", "palette", "glasses", "trophy", "medal"],
    "其它": ["chat_bubbles", "heart", "umbrella", "trophy", "medal", "stars"],
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
                "nickname_placeholder": NICKNAME_PLACEHOLDER,
            }
            try:
                raw = await asyncio.wait_for(
                    llm.generate(
                        ACTION_PROMPT + json.dumps(payload, ensure_ascii=False),
                        model=settings.QWEN_FAST_MODEL,
                        max_tokens=520,
                        temperature=0.55,
                    ),
                    timeout=AI_CALL_TIMEOUT_SEC,
                )
                parsed = self._parse_json(raw)
                if parsed:
                    spec = self._normalize_spec(parsed, emotion_tag, event_tags, note)
                    spec["ai_generated"] = True
                    spec["ai_model"] = settings.QWEN_FAST_MODEL
            except (asyncio.TimeoutError, TimeoutError):
                logger.warning(
                    "companion AI timed out after {}s (model={}), using rule fallback",
                    AI_CALL_TIMEOUT_SEC,
                    settings.QWEN_FAST_MODEL,
                )
            except Exception as exc:
                logger.warning("companion AI enrich failed, using rule fallback: {}", exc)

        visual = dict(base_scene.get("visual_payload") or {})
        visual.update(spec)
        ensure_visual_prop_label(visual)
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
        self,
        parsed: dict[str, Any],
        emotion_tag: str,
        event_tags: list[str],
        note: str | None,
    ) -> dict[str, Any]:
        fb = self._fallback(emotion_tag, event_tags, note)
        allowed_expr = {"happy", "sad", "calm", "angry", "thinking", "hurt"}
        allowed_prop = ALLOWED_PROPS
        allowed_anim = {
            "slump_read",
            "celebrate",
            "wave",
            "think",
            "shake",
            "hug",
            "sit",
            "look_down",
            "cheer",
            "swing",
            "lose_slump",
            "reach_out",
            "comfort",
        }
        expr = parsed.get("expression") if parsed.get("expression") in allowed_expr else fb["expression"]
        if not self._expression_matches_emotion(expr, emotion_tag):
            expr = fb["expression"]
        raw_prop = parsed.get("prop") if parsed.get("prop") in allowed_prop else fb["prop"]
        tag = event_tags[0] if event_tags else "其它"
        inferred = self._props_from_context(tag, note)[0]
        prop = self._prefer_prop(str(raw_prop), inferred)
        extra_props = self._normalize_extra_props(
            parsed.get("extra_props"),
            event_tags[0] if event_tags else "其它",
            note,
            primary=prop,
        )
        anim = parsed.get("animation_type") if parsed.get("animation_type") in allowed_anim else fb["animation_type"]
        tint = parsed.get("companion_tint") if self._valid_hex(parsed.get("companion_tint")) else fb["companion_tint"]
        return {
            "expression": expr,
            "prop": prop,
            "extra_props": extra_props,
            "animation_type": anim,
            "action_type": anim,
            "companion_tint": tint,
            "scene_title": (parsed.get("scene_title") or fb["scene_title"])[:16],
            "performance_hint": (parsed.get("performance_hint") or fb["performance_hint"])[:40],
            "waiting_lines": self._normalize_waiting_lines(parsed.get("waiting_lines"), fb["waiting_lines"]),
            "story_summary_lines": self._normalize_story_summary_lines(
                parsed.get("story_summary_lines"), fb["story_summary_lines"]
            ),
            "companion_pose": parsed.get("companion_pose") if parsed.get("companion_pose") else fb["companion_pose"],
            "island_mood": emotion_tag,
            "event_tags": event_tags,
            "performance_ms": 2000,
        }

    @staticmethod
    def expression_for_emotion_tag(emotion_tag: str) -> str:
        from app.config.emotion_catalog import normalize_emotion_id

        return normalize_emotion_id(emotion_tag)

    @staticmethod
    def _expression_matches_emotion(expression: str, emotion_tag: str) -> bool:
        from app.config.emotion_catalog import normalize_emotion_id

        normalized_expression = normalize_emotion_id(expression)
        normalized_tag = normalize_emotion_id(emotion_tag)
        return normalized_expression == normalized_tag

    def _fallback(
        self,
        emotion_tag: str,
        event_tags: list[str],
        note: str | None,
    ) -> dict[str, Any]:
        tag = event_tags[0] if event_tags else "其它"
        props = self._props_from_context(tag, note)
        prop = props[0]
        extra_props: list[str] = []
        expr = CompanionActionAIService.expression_for_emotion_tag(emotion_tag)
        if note and any(k in note for k in ("错", "失败", "难过", "哭", "糟")):
            if emotion_tag in ("sad", "angry", "thinking", "shi_luo", "fen_nu", "jiao_lv"):
                expr = "shi_luo"
        anim = self._anim_from_context(emotion_tag, prop, note)
        title = self._title_from_context(event_tags, note, emotion_tag)
        lines = self._waiting_lines_from_context(event_tags, title)
        summary_lines = self._story_summary_lines_from_context(
            event_tags, emotion_tag, note, title
        )
        return {
            "expression": expr,
            "prop": prop,
            "extra_props": extra_props,
            "animation_type": anim,
            "action_type": anim,
            "companion_tint": self._tint_from_context(emotion_tag, tag, note),
            "scene_title": title,
            "performance_hint": self._hint_from_context(tag, note, emotion_tag),
            "waiting_lines": lines,
            "story_summary_lines": summary_lines,
            "companion_pose": "float" if emotion_tag == "happy" else "breathing",
            "island_mood": emotion_tag,
            "event_tags": event_tags,
            "performance_ms": 2000,
            "ai_generated": False,
        }

    def _props_from_context(self, tag: str, note: str | None) -> list[str]:
        result: list[str] = []
        note_prop = self._prop_from_context(tag, note)
        if note_prop and note_prop not in ("none", "stars"):
            result.append(note_prop)
        pool = list(EVENT_PROP_POOLS.get(tag, EVENT_PROP_POOLS["其它"]))
        random.shuffle(pool)
        target = 2 + random.randint(0, 1)
        for item in pool:
            if len(result) >= target:
                break
            if item not in result and item not in ("none",):
                result.append(item)
        if not result:
            fallback = EVENT_PROP_HINTS.get(tag, "stars")
            result.append(fallback)
        return result

    def _normalize_extra_props(
        self,
        raw: Any,
        tag: str,
        note: str | None,
        *,
        primary: str,
    ) -> list[str]:
        extras: list[str] = []
        if isinstance(raw, list):
            for item in raw:
                key = str(item)
                if key in ALLOWED_PROPS and key not in ("none", "stars", primary):
                    extras.append(key)
        if extras:
            return extras[:2]
        return []

    def _prefer_prop(self, ai_prop: str, inferred: str) -> str:
        if inferred in SPECIFIC_PROPS:
            return inferred
        if ai_prop in SPECIFIC_PROPS:
            return ai_prop
        if ai_prop in ALLOWED_PROPS and ai_prop not in ("none", "stars"):
            return ai_prop
        return inferred

    def _prop_from_context(self, tag: str, note: str | None) -> str:
        if note:
            if any(k in note for k in ("下雨", "淋雨", "雨伞", "伞", "暴雨", "雨天")):
                return "umbrella"
            if any(k in note for k in ("获奖", "得奖", "第一名", "冠军", "赢了", "胜利", "奖杯")):
                return "trophy"
            if any(k in note for k in ("奖牌", " medal", "金牌", "银牌", "铜牌")):
                return "medal"
            if any(k in note for k in ("眼镜", "看书", "阅读", "读书", "图书馆")):
                return "glasses"
            if any(k in note for k in ("唱歌", "听歌", "音乐", "钢琴", "吉他", "跳舞", "舞蹈")):
                return "music"
            if any(k in note for k in ("游戏", "通关", "手游", "端游", "手柄", "打游戏", "打通了", "过关")):
                return "game_controller"
            if any(k in note for k in ("跑步", "跑得好", "跑了", "赛跑", "慢跑", "长跑", "跑操")):
                return "running_shoes"
            if any(k in note for k in ("篮球",)):
                return "basketball"
            if any(k in note for k in ("喝水", "水瓶", "口渴", "补水")):
                return "water_bottle"
            if any(k in note for k in ("画画", "绘画", "美术", "颜料", "画板")):
                return "palette"
            if any(k in note for k in ("老师", "骂", "被骂", "批评", "训斥", "责骂", "罚站", "挨骂")):
                return "chat_bubbles"
            if any(k in note for k in ("考试", "考差", "没考好", "分数", "卷子", "试卷")):
                return "exam_paper"
            if any(k in note for k in ("羽毛球", "球拍", "拍子")):
                return "badminton_racket"
            if any(k in note for k in ("练习册", "作业", "题", "考试", "学", "课")):
                return "workbook"
            if any(k in note for k in ("球", "泳", "运动")):
                return "ball"
            if any(k in note for k in ("安慰", "和好", "抱抱", "陪")):
                return "heart"
            if any(k in note for k in ("朋友", "同学", "聊天", "说话", "一起")):
                if any(k in note for k in ("吵架", "误会", "冷战", "不理")):
                    return "chat_bubbles"
                return "friends"
            if any(k in note for k in ("家", "爸妈", "父母")):
                return "home"
        return EVENT_PROP_HINTS.get(tag, "stars")

    def _anim_from_context(self, emotion: str, prop: str, note: str | None) -> str:
        if prop == "game_controller":
            return "celebrate" if emotion == "happy" else "think"
        if prop == "running_shoes":
            return "cheer" if emotion == "happy" else "wave"
        if prop == "badminton_racket":
            if note and any(k in note for k in ("输", "输了", "失败", "没赢")):
                return "lose_slump"
            return "swing"
        if prop == "chat_bubbles" and (emotion in ("sad", "angry", "thinking") or (note and any(k in note for k in ("骂", "批评", "训斥")))):
            return "look_down"
        if prop in ("friends", "chat_bubbles", "heart"):
            if emotion in ("sad", "angry") or (note and any(k in note for k in ("吵架", "误会", "冷战", "难过"))):
                return "comfort" if prop == "heart" else "reach_out"
            return "hug"
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
        if note and any(k in note for k in ("羽毛球", "球拍")):
            return "#81C784" if emotion == "happy" else "#90A4AE"
        if note and any(k in note for k in ("吵架", "误会", "和好", "朋友")):
            return "#F8BBD0" if emotion in ("sad", "calm") else base
        if tag == "学习" and emotion in ("sad", "thinking"):
            return "#90A4AE"
        if tag == "运动" and emotion == "happy":
            return "#81C784"
        if note and ("错" in note or "难过" in note):
            return "#90A4AE"
        return base

    def _title_from_context(self, event_tags: list[str], note: str | None, emotion: str) -> str:
        tag = event_tags[0] if event_tags else "其它"
        detail = event_tags[1] if len(event_tags) > 1 and event_tags[1] != "自定义" else None
        if note and "羽毛球" in note:
            return "球拍旁的小星"
        if note and any(k in note for k in ("吵架", "误会", "和好")):
            return "朋友之间的云"
        if note and "练习册" in note:
            return "练习册前的片刻"
        if tag == "学习":
            subject = detail or "学业"
            state = event_tags[2] if len(event_tags) > 2 and event_tags[2] != "自定义" else ""
            return f"{subject}{state}时刻"[:12]
        if detail:
            return f"{detail}时刻"[:12]
        return f"{tag}的小岛时刻"[:12]

    def _waiting_lines_from_context(self, event_tags: list[str], title: str) -> list[str]:
        tag = event_tags[0] if event_tags else "其它"
        detail = event_tags[1] if len(event_tags) > 1 and event_tags[1] != "自定义" else None
        detail_line = f"看见了{detail}" if detail else title
        pools = {
            "学习": [
                "小星翻开练习册",
                detail_line,
                "把难题折成星光",
                "给知识点找座位",
                "正在点亮书页",
                title,
            ],
            "朋友": [
                "小星听见心事",
                detail_line,
                "把话语放慢一点",
                "给友情织朵云",
                "正在整理表情",
                title,
            ],
            "运动": [
                "小星系紧鞋带",
                detail_line,
                "风从操场跑过",
                "汗珠变成小星星",
                "正在准备动作",
                title,
            ],
            "家庭": [
                "小星走近窗边",
                detail_line,
                "把家里的声音收好",
                "给情绪盖条毯子",
                "正在点亮小屋",
                title,
            ],
            "兴趣": [
                "小星拿起画笔",
                detail_line,
                "灵感冒出泡泡",
                "把喜欢藏进口袋",
                "正在布置舞台",
                title,
            ],
        }
        return pools.get(
            tag,
            [
                "小星抬头听风",
                detail_line,
                "把今天轻轻收起",
                "给心情找个名字",
                "正在点亮小岛",
                title,
            ],
        )

    def _normalize_waiting_lines(self, value: Any, fallback: list[str]) -> list[str]:
        if not isinstance(value, list):
            return fallback
        lines = [
            normalize_dialogue_template(str(item).strip()[:14])
            for item in value
            if str(item).strip()
        ]
        if len(lines) >= 5:
            return lines[:6]
        merged = lines + [line for line in fallback if line not in lines]
        return merged[:6]

    def _normalize_story_summary_lines(self, value: Any, fallback: list[str]) -> list[str]:
        if not isinstance(value, list):
            return fallback
        lines = [
            normalize_dialogue_template(str(item).strip()[:32])
            for item in value
            if str(item).strip()
        ]
        if len(lines) >= 3:
            return lines[:3]
        merged = lines + [line for line in fallback if line not in lines]
        while len(merged) < 3 and fallback:
            merged.append(fallback[len(merged) % len(fallback)])
        return merged[:3]

    def _story_summary_lines_from_context(
        self,
        event_tags: list[str],
        emotion_tag: str,
        note: str | None,
        title: str,
    ) -> list[str]:
        nick = NICKNAME_PLACEHOLDER
        tag = event_tags[0] if event_tags else "其它"
        detail = event_tags[1] if len(event_tags) > 1 and event_tags[1] != "自定义" else None
        mood_label = {
            "happy": "开心",
            "calm": "平静",
            "thinking": "若有所思",
            "sad": "有点难过",
            "angry": "心里闷闷的",
        }.get(emotion_tag, "有感触")

        if note and len(note.strip()) >= 4:
            snippet = note.strip()[:14]
            return [
                f"{nick}，今天辛苦啦，{snippet}我都记得",
                f"今天{tag}对我们{nick}怎么样呀？",
                f"{nick}，那一刻{mood_label}，我替你收好了",
            ]
        return [
            f"{nick}，今天辛苦啦",
            f"今天{detail or tag}对我们{nick}怎么样呀？",
            f"{nick}，{title}这件事值得记住",
        ]

    def _hint_from_context(self, tag: str, note: str | None, emotion: str) -> str:
        if note and len(note) > 4:
            return f"小星{'轻轻叹气看着' if emotion == 'sad' else '看着'}{self._prop_label(tag)}"
        return "小星缓缓转过身来"

    def _prop_label(self, tag: str) -> str:
        return {"学习": "练习册", "朋友": "朋友", "运动": "球拍", "家庭": "家", "兴趣": "画板"}.get(tag, "远方")

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
