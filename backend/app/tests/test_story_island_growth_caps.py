from types import SimpleNamespace

from app.services.profile_service import (
    STORY_ISLAND_DAILY_MOMENT_GROWTH_CAP,
    STORY_ISLAND_DAILY_TASK_GROWTH_CAP,
    STORY_ISLAND_MOMENT_GROWTH_DELTA,
    STORY_ISLAND_TASK_GROWTH_DELTA,
    ProfileService,
)


def test_daily_task_cap_constants():
    assert STORY_ISLAND_TASK_GROWTH_DELTA == 5
    assert STORY_ISLAND_DAILY_TASK_GROWTH_CAP == 10
    assert STORY_ISLAND_MOMENT_GROWTH_DELTA == 10
    assert STORY_ISLAND_DAILY_MOMENT_GROWTH_CAP == 20


def test_clamp_story_island_total_growth_respects_target():
    island = SimpleNamespace(size_kind="small", growth_value=205)
    delta = ProfileService._clamp_story_island_total_growth(island, 10)
    assert delta == 5


def test_clamp_story_island_total_growth_zero_when_full():
    island = SimpleNamespace(size_kind="small", growth_value=210)
    delta = ProfileService._clamp_story_island_total_growth(island, 5)
    assert delta == 0


def test_daily_task_reward_stops_after_cap():
    earned_today = 8
    remaining = max(0, STORY_ISLAND_DAILY_TASK_GROWTH_CAP - earned_today)
    assert min(STORY_ISLAND_TASK_GROWTH_DELTA, remaining) == 2

    earned_today = 10
    remaining = max(0, STORY_ISLAND_DAILY_TASK_GROWTH_CAP - earned_today)
    assert min(STORY_ISLAND_TASK_GROWTH_DELTA, remaining) == 0


def test_daily_moment_reward_stops_after_cap():
    earned_today = 10
    remaining = max(0, STORY_ISLAND_DAILY_MOMENT_GROWTH_CAP - earned_today)
    assert min(STORY_ISLAND_MOMENT_GROWTH_DELTA, remaining) == 10

    earned_today = 20
    remaining = max(0, STORY_ISLAND_DAILY_MOMENT_GROWTH_CAP - earned_today)
    assert min(STORY_ISLAND_MOMENT_GROWTH_DELTA, remaining) == 0
