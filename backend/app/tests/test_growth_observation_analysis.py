"""成长观察分析服务单元测试。"""

from datetime import date, timedelta
from types import SimpleNamespace
from uuid import uuid4

from app.services.growth_observation_analysis_service import GrowthObservationAnalysisService


def _report(day_offset: int, concern: str = "normal", sad: int = 0, angry: int = 0):
    d = date.today() - timedelta(days=day_offset)
    return SimpleNamespace(
        report_date=d,
        concern_level=concern,
        mood_counts={"sad": sad, "angry": angry, "calm": 1},
        risk_flags=[],
        growth_insight={},
        dismissed_risk_moment_ids=[],
        moment_count=1,
        category_breakdown={},
    )


def _moment(day_offset: int, emotion: str = "calm", note: str = ""):
    return SimpleNamespace(
        id=uuid4(),
        moment_date=date.today() - timedelta(days=day_offset),
        emotion_tag=emotion,
        note=note,
        event_tags=["学习"],
    )


def test_analyze_period_none_when_empty():
    svc = GrowthObservationAnalysisService()
    result = svc.analyze_period([], [], days=7)
    assert result["risk_tier"] == "none"
    assert result["risk_tier_label"] == "无风险"
    assert result["emotion_trend"]["direction"] == "stable"


def test_analyze_period_urgent_on_critical_note():
    svc = GrowthObservationAnalysisService()
    moments = [_moment(0, "sad", "我不想活了")]
    result = svc.analyze_period([], moments, days=7)
    assert result["risk_tier"] == "urgent"
    assert result["teacher_guidance"]["urgency"] == "immediate"


def test_analyze_period_worsening_on_watch_streak():
    svc = GrowthObservationAnalysisService()
    reports = [
        _report(2, "watch", sad=2),
        _report(1, "watch", sad=2),
        _report(0, "watch", sad=1, angry=1),
    ]
    result = svc.analyze_period(reports, [], days=7)
    assert result["emotion_trend"]["direction"] in ("worsening", "significantly_worsening")
    assert result["risk_tier"] in ("moderate", "high")


def test_stress_sources_from_notes():
    svc = GrowthObservationAnalysisService()
    moments = [_moment(0, "sad", "考试考砸了，作业也写不完")]
    result = svc.analyze_period([], moments, days=7)
    codes = [s["code"] for s in result["stress_sources"]]
    assert "study_pressure" in codes
