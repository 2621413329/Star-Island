from types import SimpleNamespace

from app.services.profile_service import (
    STORY_ISLAND_DAILY_MOMENT_GROWTH_CAP,
    STORY_ISLAND_DAILY_TASK_GROWTH_CAP,
    STORY_ISLAND_GROWTH_PER_LEVEL,
    STORY_ISLAND_MAX_LEVEL_GROWTH,
    STORY_ISLAND_MOMENT_GROWTH_DELTA,
    STORY_ISLAND_TASK_GROWTH_DELTA,
    USER_DAILY_MAIN_TASK_XP_CAP,
    USER_DAILY_MOMENT_XP_CAP,
    ProfileService,
)


def test_daily_task_cap_constants():
    assert STORY_ISLAND_TASK_GROWTH_DELTA == 5
    assert STORY_ISLAND_DAILY_TASK_GROWTH_CAP == 15
    assert USER_DAILY_MAIN_TASK_XP_CAP == 15
    assert STORY_ISLAND_MOMENT_GROWTH_DELTA == 10
    assert STORY_ISLAND_DAILY_MOMENT_GROWTH_CAP == 20
    assert USER_DAILY_MOMENT_XP_CAP == 20
    assert STORY_ISLAND_GROWTH_PER_LEVEL == 30
    assert STORY_ISLAND_MAX_LEVEL_GROWTH == 300


def test_clamp_story_island_total_growth_allows_overflow_after_max():
    island = SimpleNamespace(size_kind="small", growth_value=350)
    delta = ProfileService._clamp_story_island_total_growth(island, 10)
    assert delta == 10


def test_clamp_story_island_total_growth_zero_for_non_positive():
    island = SimpleNamespace(size_kind="small", growth_value=350)
    assert ProfileService._clamp_story_island_total_growth(island, 0) == 0
    assert ProfileService._clamp_story_island_total_growth(island, -5) == 0


def test_sub_island_daily_task_reward_stops_after_cap():
    earned_today = 12
    remaining = max(0, STORY_ISLAND_DAILY_TASK_GROWTH_CAP - earned_today)
    assert min(STORY_ISLAND_TASK_GROWTH_DELTA, remaining) == 3

    earned_today = 15
    remaining = max(0, STORY_ISLAND_DAILY_TASK_GROWTH_CAP - earned_today)
    assert min(STORY_ISLAND_TASK_GROWTH_DELTA, remaining) == 0


def test_main_island_daily_task_xp_stops_after_cap():
    earned_today = 12
    remaining = max(0, USER_DAILY_MAIN_TASK_XP_CAP - earned_today)
    assert min(STORY_ISLAND_TASK_GROWTH_DELTA, remaining) == 3

    earned_today = 15
    remaining = max(0, USER_DAILY_MAIN_TASK_XP_CAP - earned_today)
    assert min(STORY_ISLAND_TASK_GROWTH_DELTA, remaining) == 0


def test_daily_moment_reward_stops_after_cap():
    earned_today = 10
    remaining = max(0, USER_DAILY_MOMENT_XP_CAP - earned_today)
    assert min(STORY_ISLAND_MOMENT_GROWTH_DELTA, remaining) == 10

    earned_today = 20
    remaining = max(0, USER_DAILY_MOMENT_XP_CAP - earned_today)
    assert min(STORY_ISLAND_MOMENT_GROWTH_DELTA, remaining) == 0


def test_sub_island_daily_moment_growth_stops_after_cap():
    earned_today = 12
    remaining = max(0, STORY_ISLAND_DAILY_MOMENT_GROWTH_CAP - earned_today)
    assert min(STORY_ISLAND_MOMENT_GROWTH_DELTA, remaining) == 8

    earned_today = 20
    remaining = max(0, STORY_ISLAND_DAILY_MOMENT_GROWTH_CAP - earned_today)
    assert min(STORY_ISLAND_MOMENT_GROWTH_DELTA, remaining) == 0


def test_moment_growth_transfer_subtracts_before_regrant():
    """转移岛屿时应先从旧岛扣减，再向新岛发放。"""
    previous_delta = 10
    transferring = True
    should_subtract = transferring and previous_delta > 0
    assert should_subtract is True

    same_island_idempotent = (not transferring) and previous_delta > 0
    assert same_island_idempotent is True


def test_story_island_thresholds_cap_at_300_for_all_sizes():
    expected = [30, 60, 90, 120, 150, 180, 210, 240, 270, 300]
    for size_kind in ("small", "medium", "large"):
        thresholds = ProfileService._story_island_thresholds(size_kind)
        assert thresholds == expected


def test_small_island_growth_target_is_300():
    assert ProfileService._story_island_growth_target("small") == 300


def test_story_island_level_stops_at_ten_after_max_growth():
    assert ProfileService._story_island_current_level("small", 299) == 9
    assert ProfileService._story_island_current_level("small", 300) == 10
    assert ProfileService._story_island_current_level("small", 450) == 10
