from app.services.daily_mood_report_service import DailyMoodReportService
from app.services.danger_keyword_rules import detect_danger_keywords
from app.services.growth_insight_service import GrowthInsightService


class _Moment:
    def __init__(self, note: str, emotion_tag: str = "calm", moment_id: str = "m1"):
        self.id = moment_id
        self.note = note
        self.emotion_tag = emotion_tag
        self.event_tags = ["其它"]


def test_danger_keywords_detect_graded_terms():
    matches = detect_danger_keywords("他说要动刀，还要抢手机")
    by_term = {match.term: match for match in matches}

    assert set(by_term) == {"动刀", "抢手机"}
    assert by_term["动刀"].risk_level == "critical"
    assert by_term["抢手机"].risk_level == "critical"


def test_daily_report_risk_signals_use_danger_keywords():
    flags, level = DailyMoodReportService().detect_risk_signals(
        [_Moment("有人堵校门还围堵同学")]
    )

    assert level == "watch"
    assert any("治安风险" in flag for flag in flags)


def test_growth_insight_marks_critical_danger_note():
    moment = _Moment("他威胁要割腕")

    assert GrowthInsightService().moment_note_is_critical(moment)
