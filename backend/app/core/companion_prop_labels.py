"""配饰 id / 资源文件名 → 中文展示名。"""

from __future__ import annotations

import re

KNOWN_TITLES: dict[str, str] = {
    "workbook": "练习册",
    "exam_paper": "试卷",
    "ball": "球类",
    "basketball": "篮球",
    "badminton_racket": "羽毛球拍",
    "friends": "朋友",
    "chat_bubbles": "聊天",
    "heart": "温暖",
    "home": "家庭",
    "music": "音乐",
    "palette": "绘画",
    "umbrella": "雨伞",
    "trophy": "奖杯",
    "game_controller": "游戏",
    "game": "游戏",
    "running_shoes": "跑步鞋",
    "water_bottle": "水瓶",
    "glasses": "眼镜",
    "medal": "奖牌",
    "stars": "星光",
    "none": "无",
    "camera": "相机",
    "coffee": "咖啡",
    "book": "书本",
    "novel": "小说",
    "present": "礼物",
    "robot": "机器人",
    "duck": "小鸭子",
    "sleep": "睡眠",
    "peace": "平静",
    "love": "爱心",
    "children": "伙伴",
    "education": "学习",
    "construction": "积木",
    "playground-equipment": "游乐",
    "baby-toy": "玩具",
    "game-console": "游戏机",
}

_CJK = re.compile(r"[\u4e00-\u9fff]")


def _raw_prop_token(prop: str) -> str:
    trimmed = prop.strip()
    category_index = trimmed.find("__")
    if 0 < category_index < len(trimmed) - 2:
        return trimmed[category_index + 2 :]
    for prefix in ("story_", "detail_", "note_"):
        if trimmed.startswith(prefix):
            return trimmed[len(prefix) :]
    return trimmed


def companion_prop_label(prop: str, *, stored_label: str | None = None) -> str:
    label = (stored_label or "").strip()
    if label:
        return label

    token = _raw_prop_token(prop)
    if token in KNOWN_TITLES:
        return KNOWN_TITLES[token]
    if _CJK.search(token):
        return token
    return token.replace("-", " ").replace("_", " ").strip() or "配饰"


def ensure_visual_prop_label(visual: dict) -> dict:
    prop = visual.get("prop")
    if not prop or prop in ("none", "stars"):
        return visual
    if not visual.get("prop_label"):
        visual["prop_label"] = companion_prop_label(str(prop))
    return visual
