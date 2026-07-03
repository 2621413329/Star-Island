from app.config.story_island_buildings import (
    STORY_ISLAND_BUILDINGS_BY_CATEGORY,
    story_island_building_type,
)


def test_each_category_has_ten_buildings():
    assert len(STORY_ISLAND_BUILDINGS_BY_CATEGORY) == 11
    for category_id, buildings in STORY_ISLAND_BUILDINGS_BY_CATEGORY.items():
        assert len(buildings) == 10, category_id
        assert len(set(buildings)) == 10, category_id


def test_work_island_level_progression():
    assert story_island_building_type("work", 1) == "工作角"
    assert story_island_building_type("work", 10) == "公司总部"


def test_unknown_category_uses_fallback():
    name = story_island_building_type("unknown", 5)
    assert name == "路径广场"
