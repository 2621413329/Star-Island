from datetime import date, timedelta

from app.models.profile import DailyMoment
from app.services.growth_observation_analysis_service import GrowthObservationAnalysisService


def _moment(*, primary: str = "工作", emotion: str = "calm") -> DailyMoment:
    return DailyMoment(
        user_id=None,
        event_tags=[primary],
        emotion_tag=emotion,
        primary_tag=primary,
        companion_scene="study",
        companion_pose="breathing",
        moment_date=date.today(),
    )


def test_weekly_hint_uses_companion_name():
    svc = GrowthObservationAnalysisService()
    moments = [_moment(), _moment(primary="生活")]
    result = svc.analyze_period([], moments, days=7, companion_name="小光宝")
    hint = result["weekly_hint"]
    assert "2" in hint
    assert "记录" in hint
    assert "小光宝" in hint


def test_weekly_hint_empty_when_no_moments():
    svc = GrowthObservationAnalysisService()
    result = svc.analyze_period([], [], days=7)
    assert "还没有" in result["weekly_hint"]
