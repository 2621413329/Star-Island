from types import SimpleNamespace

from app.services.profile_service import (
    STORY_ISLAND_DAILY_MOMENT_GROWTH_CAP,
    STORY_ISLAND_DAILY_TASK_GROWTH_CAP,
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


def test_clamp_story_island_total_growth_respects_target():
    island = SimpleNamespace(size_kind="small", growth_value=205)
    delta = ProfileService._clamp_story_island_total_growth(island, 10)
    assert delta == 5


def test_clamp_story_island_total_growth_zero_when_full():
    island = SimpleNamespace(size_kind="small", growth_value=210)
    delta = ProfileService._clamp_story_island_total_growth(island, 5)
    assert delta == 0


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


def test_small_island_geometric_thresholds():
    thresholds = ProfileService._story_island_thresholds("small")
    assert len(thresholds) == 10
    assert thresholds[0] > 0
    assert thresholds[-1] == 210
    assert all(
        thresholds[index] > thresholds[index - 1]
        for index in range(1, len(thresholds))
    )
    increments = [
        thresholds[0],
        *(thresholds[i] - thresholds[i - 1] for i in range(1, len(thresholds))),
    ]
    assert sum(increments) == 210
    assert increments[-1] == STORY_ISLAND_DAILY_TASK_GROWTH_CAP
    ratio = increments[1] / increments[0]
    for index in range(2, len(increments)):
        observed = increments[index] / increments[index - 1]
        assert abs(observed - ratio) < 0.08
