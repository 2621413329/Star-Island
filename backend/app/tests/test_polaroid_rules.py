from app.services.polaroid_rules import (
    front_caption,
    levels_to_capture,
    main_level_subject,
    notes_span,
    specific_back_fallback,
    story_island_moment_growth_grant,
    story_level_subject,
    summary_is_specific,
)


def test_first_moment_reaches_level_one():
    assert story_island_moment_growth_grant(0, earned_today=0) == 30
    assert story_island_moment_growth_grant(10, earned_today=10) == 20


def test_later_moments_keep_daily_cap():
    assert story_island_moment_growth_grant(30, earned_today=0) == 10
    assert story_island_moment_growth_grant(30, earned_today=12) == 8
    assert story_island_moment_growth_grant(30, earned_today=20) == 0


def test_levels_to_capture_skips_existing():
    assert levels_to_capture(0, 1) == [1]
    assert levels_to_capture(1, 1) == []
    assert levels_to_capture(2, 5) == [3, 4, 5]
    assert levels_to_capture(4, 2) == []


def test_front_caption_uses_the_change_not_the_diary():
    note = "今天和妈妈吃了牛肉面"
    caption = front_caption("茶屋")
    assert caption == "今天，多了茶屋"
    assert note not in caption


def test_story_and_main_subjects_name_the_change():
    name, asset = story_level_subject("life", 6)
    assert name == "茶屋"
    assert asset == "story:life:6"
    assert front_caption(name, evolved=True) == "今天，进化成了茶屋"
    assert front_caption(name) == "今天，多了茶屋"

    main_name, main_asset = main_level_subject(5)
    assert main_name == "记忆棚屋"
    assert main_asset == "building:record_shed"

    quiet_name, quiet_asset = main_level_subject(2)
    assert quiet_name == "野趣小花、晨露花芽等"
    assert quiet_asset == "decor:flower_01"

    tree_name, tree_asset = main_level_subject(6)
    assert "风车" not in tree_name
    assert tree_name == "风向矮树、夕照树影等"
    assert tree_asset == "decor:tree_small_02"


def test_back_fallback_names_the_day_and_the_note():
    text = specific_back_fallback(
        "茶屋",
        [{"moment_date": "2026-03-12", "excerpt": "今天和妈妈吃了牛肉面"}],
    )
    assert "茶屋" in text
    assert "3月12日" in text
    assert "牛肉面" in text
    assert summary_is_specific("这段日子很充实") is False
    assert summary_is_specific(text) is True
    assert notes_span(
        [
            {"moment_date": "2026-03-12"},
            {"moment_date": "2026-03-02"},
        ]
    ) == "3月2日到3月12日"
