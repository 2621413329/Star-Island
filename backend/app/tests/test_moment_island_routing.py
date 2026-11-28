import uuid

from app.models.growth_tag import GrowthTag, GrowthTagCategory
from app.models.story_island import StoryIsland
from app.services.moment_analysis_service import MomentAnalysisService
from app.services.profile_service import ProfileService


def _category(category_id: str, label: str, tags: list[str]) -> GrowthTagCategory:
    category = GrowthTagCategory(
        id=category_id,
        label=label,
        icon="label",
        color="#78909C",
        sort_order=0,
        is_active=True,
    )
    category.tags = [
        GrowthTag(
            id=f"{category_id}_{index}",
            category_id=category_id,
            label=tag,
            sort_order=index,
            is_active=True,
        )
        for index, tag in enumerate(tags)
    ]
    return category


def _catalog():
    service = MomentAnalysisService()
    categories = [
        _category("finance", "财务", ["投资", "理财", "工资"]),
        _category("work", "工作", ["加班"]),
        _category("life", "生活", ["日常"]),
        _category("emotion", "情绪", ["开心"]),
    ]
    return service, service.build_catalog(categories)


def test_wealth_repetition_overrides_life_fallback():
    service, catalog = _catalog()
    fallback = service._fallback("生活", catalog)
    aligned = service._align_with_note(fallback, "财富财富财富", catalog)
    assert aligned.primary_tag == "财务"


def test_model_alias_wealth_becomes_finance():
    service, catalog = _catalog()
    result = service._normalize(
        {
            "primary_tag": "财富",
            "secondary_tags": ["投资"],
            "emotion": "满足",
            "growth_points": [],
        },
        catalog,
    )
    assert result.primary_tag == "财务"
    assert result.secondary_tags == ["投资"]


def test_single_wealth_word_overrides_generic_life():
    service, catalog = _catalog()
    fallback = service._fallback("生活", catalog)
    aligned = service._align_with_note(fallback, "财富", catalog)
    assert aligned.primary_tag == "财务"


def test_work_story_keeps_model_tag_when_wealth_is_only_mentioned_once():
    service, catalog = _catalog()
    modeled = service._normalize(
        {
            "primary_tag": "工作",
            "secondary_tags": ["加班"],
            "emotion": "平静",
            "growth_points": [],
        },
        catalog,
    )
    aligned = service._align_with_note(modeled, "今天开会谈到财富", catalog)
    assert aligned.primary_tag == "工作"


def test_story_island_pick_skips_growth_main():
    user_id = uuid.uuid4()
    main = StoryIsland(
        user_id=user_id,
        category_id="life",
        name="主岛",
        sort_order=-100,
        background_config={"is_growth_main": True},
    )
    life = StoryIsland(
        user_id=user_id,
        category_id="life",
        name="生活岛",
        sort_order=10,
        background_config={},
    )
    assert ProfileService._prefer_story_island([main, life]) is life
    assert ProfileService._prefer_story_island([main]) is None
