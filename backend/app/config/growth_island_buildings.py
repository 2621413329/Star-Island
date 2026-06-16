"""成长岛建筑解锁配置（与 Flutter GrowthIslandConfigs 对齐）。"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class IslandLevelDef:
    level: int
    required_growth_score: int
    unlock_buildings: tuple[str, ...]


# 各岛屿等级首次解锁的建筑与所需成长值。
ISLAND_LEVELS: tuple[IslandLevelDef, ...] = (
    IslandLevelDef(1, 0, ("starter_stone",)),
    IslandLevelDef(2, 25, ()),
    IslandLevelDef(3, 55, ("record_shed",)),
    IslandLevelDef(4, 95, ("memory_mailbox",)),
    IslandLevelDef(5, 145, ("growth_house",)),
    IslandLevelDef(6, 205, ("harbor_pier",)),
    IslandLevelDef(7, 275, ("emotion_windchime",)),
    IslandLevelDef(8, 355, ("habit_flowerbed",)),
    IslandLevelDef(9, 445, ("quiet_tent",)),
    IslandLevelDef(10, 545, ("growth_house_lv2",)),
    IslandLevelDef(11, 660, ("lighthouse_base",)),
    IslandLevelDef(12, 790, ("story_plaza",)),
    IslandLevelDef(13, 935, ("memory_fountain",)),
    IslandLevelDef(14, 1095, ("library_seed",)),
    IslandLevelDef(15, 1270, ("growth_clocktower",)),
    IslandLevelDef(16, 1460, ("lighthouse",)),
    IslandLevelDef(17, 1665, ("companion_plaza",)),
    IslandLevelDef(18, 1885, ("memory_gallery",)),
    IslandLevelDef(19, 2120, ("dream_observatory",)),
    IslandLevelDef(20, 2370, ("growth_academy",)),
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
