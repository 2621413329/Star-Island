from app.services.polaroid_rules import (
    front_caption,
    levels_to_capture,
    main_level_subject,
    story_island_moment_growth_grant,
    story_level_subject,
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
    assert front_caption(name) == "今天，多了茶屋"

    main_name, main_asset = main_level_subject(5)
    assert main_name == "记录小屋"
    assert main_asset == "building:record_shed"

    quiet_name, quiet_asset = main_level_subject(2)
    assert quiet_name == "小树苗"
    assert quiet_asset == "title:2"
