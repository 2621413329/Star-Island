"""成长岛建筑解锁配置（与 Flutter GrowthIslandConfigs 对齐）。"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class IslandLevelDef:
    level: int
    required_growth_score: int
    unlock_buildings: tuple[str, ...]


# 各岛屿等级首次解锁的建筑与所需成长值（与 Flutter GrowthIslandConfigs 对齐）。
ISLAND_LEVELS: tuple[IslandLevelDef, ...] = (
    IslandLevelDef(1, 0, ("starter_stone",)),
    IslandLevelDef(2, 70, ()),
    IslandLevelDef(3, 150, ()),
    IslandLevelDef(4, 244, ()),
    IslandLevelDef(5, 356, ("record_shed",)),
    IslandLevelDef(6, 490, ()),
    IslandLevelDef(7, 650, ("memory_mailbox",)),
    IslandLevelDef(8, 840, ()),
    IslandLevelDef(9, 1064, ("growth_house",)),
    IslandLevelDef(10, 1326, ()),
    IslandLevelDef(11, 1630, ("harbor_pier", "lighthouse_base")),
    IslandLevelDef(12, 1980, ("story_plaza",)),
    IslandLevelDef(13, 2380, ("emotion_windchime", "memory_fountain")),
    IslandLevelDef(14, 2834, ("library_seed",)),
    IslandLevelDef(15, 3346, ("habit_flowerbed", "growth_clocktower")),
    IslandLevelDef(16, 3920, ("lighthouse",)),
    IslandLevelDef(17, 4560, ("quiet_tent", "companion_plaza")),
    IslandLevelDef(18, 5270, ("memory_gallery",)),
    IslandLevelDef(19, 6054, ("dream_observatory",)),
    IslandLevelDef(20, 6916, ("growth_house_lv2", "growth_academy")),
)

BUILDING_UNLOCK_LEVEL: dict[str, int] = {}
BUILDING_UNLOCK_SCORE: dict[str, int] = {}

for _level_def in ISLAND_LEVELS:
    for _building_id in _level_def.unlock_buildings:
        BUILDING_UNLOCK_LEVEL[_building_id] = _level_def.level
        BUILDING_UNLOCK_SCORE[_building_id] = _level_def.required_growth_score


def resolve_island_level(growth_value: int) -> int:
    level = 1
    for config in ISLAND_LEVELS:
        if growth_value >= config.required_growth_score:
            level = config.level
    return level


def buildings_for_growth_value(growth_value: int) -> list[tuple[str, int]]:
    """返回当前成长值下已解锁的 (building_id, unlock_level)。"""
    island_level = resolve_island_level(growth_value)
    out: list[tuple[str, int]] = []
    for building_id, unlock_level in BUILDING_UNLOCK_LEVEL.items():
        if unlock_level <= island_level:
            out.append((building_id, unlock_level))
    return out


def required_score_for_level(unlock_level: int) -> int | None:
    for config in ISLAND_LEVELS:
        if config.level == unlock_level:
            return config.required_growth_score
    return None
