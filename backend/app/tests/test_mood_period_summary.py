"""周期心情总体总结服务测试。"""

from datetime import date, timedelta

import pytest

from app.services.mood_period_summary_service import (
    MoodPeriodSummaryService,
    _rule_summary,
)


def _moment(emotion: str, moment_date: date, category: str = "学习"):
    from types import SimpleNamespace

    return SimpleNamespace(
        emotion_tag=emotion,
        moment_date=moment_date,
        event_tags=[category],
    )


def test_rule_summary_empty():
    text = _rule_summary(
        period="month",
        total=0,
        mood_counts={"happy": 0, "calm": 0, "thinking": 0, "sad": 0, "angry": 0},
        category_breakdown={},
        category_filter=None,
    )
    assert "本月" in text
    assert len(text) <= 100


def test_rule_summary_with_data():
    text = _rule_summary(
        period="week",
        total=10,
        mood_counts={
            "happy": 2,
            "calm": 3,
            "thinking": 4,
            "sad": 1,
            "angry": 0,
        },
        category_breakdown={"家庭": 5, "学习": 3},
        category_filter=None,
    )
    assert "本周" in text
    assert len(text) <= 100


@pytest.mark.asyncio
async def test_build_summary_aggregates_period():
    today = date(2026, 6, 12)
    moments = [
        _moment("thinking", today, "家庭"),
        _moment("calm", today - timedelta(days=3), "学习"),
        _moment("sad", today - timedelta(days=20), "朋友"),
    ]
    svc = MoodPeriodSummaryService()
    result = await svc.build_summary(moments, period="month", today=today)
    assert result["total_moments"] == 2
    assert result["mood_counts"]["thinking"] == 1
    assert result["mood_counts"]["calm"] == 1
    assert result["summary"]
    assert len(result["summary"]) <= 100


@pytest.mark.asyncio
async def test_build_summary_category_filter():
    today = date(2026, 6, 12)
    moments = [
        _moment("thinking", today, "家庭"),
        _moment("calm", today, "学习"),
    ]
    svc = MoodPeriodSummaryService()
    result = await svc.build_summary(
        moments,
        period="today",
        category_filter="家庭",
        today=today,
    )
    assert result["total_moments"] == 1
    assert result["dominant_mood"] == "thinking"
