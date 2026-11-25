"""拍立得的纯规则：成长补档、正面文案、要拍的等级。不访问数据库。"""

from __future__ import annotations

from app.config.growth_island_buildings import ISLAND_LEVELS
from app.config.story_island_buildings import story_island_building_type
from app.services.growth_points_service import LEVEL_UNLOCKS
from app.services.profile_service import (
    STORY_ISLAND_DAILY_MOMENT_GROWTH_CAP,
    STORY_ISLAND_GROWTH_PER_LEVEL,
    STORY_ISLAND_MOMENT_GROWTH_DELTA,
)

MAIN_BUILDING_NAMES: dict[str, str] = {
    "starter_stone": "启程石",
    "record_shed": "记录小屋",
    "memory_mailbox": "记忆信箱",
    "growth_house": "成长小屋",
    "growth_house_lv2": "成长小屋·二阶",
    "habit_flowerbed": "习惯花圃",
    "emotion_windchime": "心情风铃",
    "quiet_tent": "静思帐篷",
    "memory_fountain": "记忆喷泉",
    "growth_clocktower": "成长钟楼",
    "library_seed": "日常图书馆",
    "lighthouse_base": "灯塔基座",
    "lighthouse": "成长灯塔",
    "story_plaza": "日常广场",
    "harbor_pier": "港口栈桥",
    "companion_plaza": "伙伴广场",
    "memory_gallery": "记忆画廊",
    "dream_observatory": "梦想观测台",
    "growth_academy": "成长学院",
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


def main_level_subject(level: int) -> tuple[str, str]:
    """返回（画面上的名字，客户端资源键）。"""
    for config in ISLAND_LEVELS:
        if config.level != level or not config.unlock_buildings:
            continue
        names = [MAIN_BUILDING_NAMES.get(item, item) for item in config.unlock_buildings]
        asset = f"building:{config.unlock_buildings[0]}"
        return "、".join(names[:2]), asset
    label = LEVEL_UNLOCKS.get(level, "新的一角")
    return label, f"title:{level}"


def story_level_subject(category_id: str, level: int) -> tuple[str, str]:
    name = story_island_building_type(category_id, level)
    return name, f"story:{category_id}:{level}"
