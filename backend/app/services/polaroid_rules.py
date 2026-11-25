"""拍立得的纯规则：成长补档、正面文案、要拍的等级。不访问数据库。"""

from __future__ import annotations

import re

from app.config.growth_island_buildings import ISLAND_LEVELS
from app.config.story_island_buildings import story_island_building_type
from app.services.growth_points_service import LEVEL_UNLOCKS
from app.services.profile_service import (
    STORY_ISLAND_DAILY_MOMENT_GROWTH_CAP,
    STORY_ISLAND_GROWTH_PER_LEVEL,
    STORY_ISLAND_MOMENT_GROWTH_DELTA,
)

MAIN_BUILDING_NAMES: dict[str, str] = {
    "starter_stone": "起始石碑",
    "record_shed": "记忆棚屋",
    "memory_mailbox": "记忆邮箱",
    "growth_house": "成长小屋",
    "growth_house_lv2": "成长小屋·扩建",
    "habit_flowerbed": "习惯花园",
    "emotion_windchime": "情绪风铃",
    "quiet_tent": "静心帐篷",
    "memory_fountain": "记忆喷泉",
    "growth_clocktower": "成长钟塔",
    "library_seed": "图书种子",
    "lighthouse_base": "灯塔基座",
    "lighthouse": "温暖灯塔",
    "story_plaza": "故事广场",
    "harbor_pier": "港口栈桥",
    "companion_plaza": "陪伴广场",
    "memory_gallery": "记忆画廊",
    "dream_observatory": "梦想天文台",
    "growth_academy": "成长学院",
}

# 这一级没有新建筑时，拍立得写岛上真正长出来的植物。与 DecorConfigs 同步。
_DECOR_SUBJECTS: dict[int, tuple[tuple[str, str], ...]] = {
    2: (("flower_01", "野趣小花"), ("flower_02", "晨露花芽"), ("flower_03", "点缀花蕊")),
    3: (
        ("grass_07", "晚风草芽"),
        ("grass_08", "浅岸草簇"),
        ("stone_01", "圆润卧石"),
        ("stone_02", "滨海怪石"),
    ),
    4: (
        ("flower_04", "岸边小花"),
        ("flower_05", "晨风花苞"),
        ("bush_01", "低垂灌木"),
        ("bush_02", "团簇绿篱"),
        ("bush_03", "丛生灌木"),
    ),
    6: (
        ("tree_small_02", "风向矮树"),
        ("tree_small_03", "夕照树影"),
        ("tree_small_04", "幼苗小树"),
    ),
    8: (
        ("butterfly_01", "翩跹蝴蝶"),
        ("mushroom_02", "幽光蘑菇"),
        ("fallen_leaf_01", "飘落叶片"),
    ),
    10: (("cloud_01", "轻柔云朵"), ("cloud_02", "薄雾云絮"), ("cloud_03", "远处云团")),
}

POLAROID_SKIN_PLAIN = "plain"


def story_island_moment_growth_grant(current_growth: int, earned_today: int) -> int:
    """第一条入驻把副岛补到 Lv1。之后仍是 +10，并且受每日上限约束。"""
    current = max(0, int(current_growth))
    if current < STORY_ISLAND_GROWTH_PER_LEVEL:
        return STORY_ISLAND_GROWTH_PER_LEVEL - current
    remaining = max(0, STORY_ISLAND_DAILY_MOMENT_GROWTH_CAP - max(0, int(earned_today)))
    return min(STORY_ISLAND_MOMENT_GROWTH_DELTA, remaining)


def levels_to_capture(previous_level: int, current_level: int) -> list[int]:
    if current_level <= previous_level:
        return []
    start = max(int(previous_level) + 1, 1)
    return list(range(start, int(current_level) + 1))


def front_caption(subject: str) -> str:
    name = (subject or "").strip() or "新的一角"
    return f"今天，多了{name}"


def _subject_label(names: list[str]) -> str:
    shown = "、".join(names[:2])
    if len(names) > 2:
        return f"{shown}等"
    return shown


def main_level_subject(level: int) -> tuple[str, str]:
    """返回（画面上的名字，客户端资源键）。名字和岛上这一级新出现的东西一致。"""
    for config in ISLAND_LEVELS:
        if config.level != level or not config.unlock_buildings:
            continue
        names = [MAIN_BUILDING_NAMES.get(item, item) for item in config.unlock_buildings]
        asset = f"building:{config.unlock_buildings[0]}"
        return _subject_label(names), asset
    decor = _DECOR_SUBJECTS.get(level)
    if decor:
        names = [name for _, name in decor]
        return _subject_label(names), f"decor:{decor[0][0]}"
    label = LEVEL_UNLOCKS.get(level, "新的一角")
    return label, f"title:{level}"


def story_level_subject(category_id: str, level: int) -> tuple[str, str]:
    name = story_island_building_type(category_id, level)
    return name, f"story:{category_id}:{level}"


_VAGUE_SHORT = ("很充实", "继续加油", "越来越好", "平凡而珍贵", "一点一滴")


def summary_is_specific(text: str) -> bool:
    """太短，或只有空话，就不算这段日子的总结。"""
    cleaned = re.sub(r"\s+", "", (text or "").strip())
    if len(cleaned) < 28:
        return False
    if len(cleaned) < 48 and any(phrase in cleaned for phrase in _VAGUE_SHORT):
        return False
    return True


def _month_day(raw: str) -> str:
    text = (raw or "").strip()
    if len(text) >= 10 and text[4] == "-" and text[7] == "-":
        month = int(text[5:7])
        day = int(text[8:10])
        return f"{month}月{day}日"
    return ""


def specific_back_fallback(change: str, sources: list[dict]) -> str:
    """模型没写出具体内容时，用日记原句拼背面。"""
    pieces: list[str] = []
    for item in sources:
        excerpt = re.sub(r"\s+", "", str(item.get("excerpt") or "").strip())
        if not excerpt:
            continue
        when = _month_day(str(item.get("moment_date") or ""))
        pieces.append(f"{when}写到{excerpt}" if when else excerpt)
        if len(pieces) >= 4:
            break
    if not pieces:
        return ""
    name = (change or "").strip() or "新的一角"
    return f"这段日子岛上多了{name}。{'；'.join(pieces)}。"[:400]


def notes_span(sources: list[dict]) -> str:
    days: list[tuple[str, str]] = []
    seen: set[str] = set()
    for item in sources:
        label = _month_day(str(item.get("moment_date") or ""))
        raw = str(item.get("moment_date") or "")[:10]
        if not label or raw in seen:
            continue
        seen.add(raw)
        days.append((raw, label))
    if not days:
        return "最近这些天"
    days.sort()
    if days[0][0] == days[-1][0]:
        return days[0][1]
    return f"{days[0][1]}到{days[-1][1]}"
