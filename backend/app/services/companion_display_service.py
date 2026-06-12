"""将 companion_scene 技术 ID 转为教师端可读文案。"""

from __future__ import annotations

from typing import Any

from app.services.companion_scene_service import EVENT_SCENE_MAP, MOOD_MODIFIER

STYLE_LABELS = {
    "chibi": "Q版伙伴",
    "normal": "标准伙伴",
}

ANIM_LABELS = {
    "lose_slump": "失利后低落",
    "slump_read": "低头阅读",
    "celebrate": "庆祝",
    "think": "思考",
    "cheer": "加油",
    "wave": "挥手",
    "swing": "挥拍",
    "reach_out": "伸手安慰",
    "comfort": "陪伴安慰",
    "hug": "拥抱",
    "float": "轻快漂浮",
    "breathing": "安静呼吸",
    "blink": "眨眼思考",
}

MOOD_MOD_LABELS = {
    "bright": "明媚",
    "soft": "柔和",
    "quiet": "安静",
    "gentle": "温柔",
    "cool": "沉着",
    **{k: v for k, v in MOOD_MODIFIER.items()},
}

BASE_SCENE_LABELS = {
    **{k: k for k in EVENT_SCENE_MAP},
    **{v: k for k, v in EVENT_SCENE_MAP.items()},
    "study": "学习",
    "friendship": "朋友",
    "sport": "运动",
    "family": "家庭",
    "hobby": "兴趣",
    "stargaze": "星空",
}

# 较长动画 ID 优先匹配（如 lose_slump）
_SORTED_ANIMS = sorted(ANIM_LABELS.keys(), key=len, reverse=True)

EMOTION_LABELS = {
    "happy": "超开心",
    "calm": "开心",
    "thinking": "平静",
    "sad": "低落",
    "angry": "生气",
}

PROP_LABELS = {
    "workbook": "练习册",
    "exam_paper": "试卷",
    "ball": "球",
    "basketball": "篮球",
    "badminton_racket": "羽毛球拍",
    "running_shoes": "运动鞋",
    "water_bottle": "水瓶",
    "game_controller": "游戏手柄",
    "palette": "画板",
    "chat_bubbles": "聊天气泡",
    "heart": "爱心",
    "friends": "朋友",
    "home": "家",
    "music": "音乐",
    "umbrella": "雨伞",
    "trophy": "奖杯",
    "medal": "奖牌",
    "glasses": "眼镜",
    "stars": "星星",
    "none": "无道具",
}


def format_teacher_companion_scene(
    *,
    companion_scene: str | None,
    emotion_tag: str,
    category_label: str,
    visual_payload: dict[str, Any] | None = None,
    event_tags: list[str] | None = None,
) -> str:
    """教师端：直白描述，不使用诗意 scene_title。"""
    vp = visual_payload or {}
    emotion = EMOTION_LABELS.get(emotion_tag, emotion_tag)
    cat = category_label or "其它"
    anim_key = (vp.get("animation_type") or vp.get("action_type") or "").strip()
    prop_key = (vp.get("prop") or "").strip()
    parts = [f"{cat}类瞬间", f"情绪{emotion}"]
    if prop_key and prop_key != "none":
        parts.append(f"道具·{PROP_LABELS.get(prop_key, prop_key)}")
    if anim_key:
        parts.append(f"动作·{ANIM_LABELS.get(anim_key, _humanize_token(anim_key))}")
    elif companion_scene:
        parsed = format_companion_scene_display(
            companion_scene,
            visual_payload=None,
            event_tags=event_tags,
            use_poetic_title=False,
        )
        if parsed and parsed != companion_scene:
            parts.append(parsed)
    return " · ".join(parts)


def _humanize_token(token: str) -> str:
    return token.replace("_", " ")


def format_companion_scene_display(
    companion_scene: str | None,
    *,
    visual_payload: dict[str, Any] | None = None,
    event_tags: list[str] | None = None,
    use_poetic_title: bool = True,
) -> str:
    vp = visual_payload or {}
    if use_poetic_title:
        title = (vp.get("scene_title") or "").strip()
        if title:
            return title
        hint = (vp.get("performance_hint") or "").strip()
        if hint:
            return hint

    scene = (companion_scene or "").strip()
    if not scene:
        return "陪伴场景"

    for anim in _SORTED_ANIMS:
        suffix = f"_{anim}"
        if scene.endswith(suffix):
            style_key = scene[: -len(suffix)]
            style = STYLE_LABELS.get(style_key, style_key)
            anim_label = ANIM_LABELS[anim]
            tag_label = _event_tail_label(scene, anim, event_tags)
            if tag_label:
                return f"{style} · {anim_label} · {tag_label}"
            return f"{style} · {anim_label}"

    parts = scene.split("_")
    if len(parts) >= 3:
        mood_mod = parts[-1]
        base = parts[-2]
        style = "_".join(parts[:-2])
        style_l = STYLE_LABELS.get(style, style)
        base_l = BASE_SCENE_LABELS.get(base, base)
        mood_l = MOOD_MOD_LABELS.get(mood_mod, mood_mod)
        return f"{style_l} · {base_l} · {mood_l}"

    return scene.replace("_", " · ")


def _event_tail_label(scene: str, anim: str, event_tags: list[str] | None) -> str:
    if event_tags:
        from app.services.daily_mood_report_service import CATEGORY_LABELS

        main = event_tags[0]
        return CATEGORY_LABELS.get(main, main)
    tail = scene.split(f"_{anim}_", 1)
    if len(tail) == 2 and tail[1]:
        return tail[1]
    return ""
