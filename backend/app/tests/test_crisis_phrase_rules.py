import pytest

from app.services.crisis_phrase_rules import detect_crisis_phrases, note_has_critical_crisis
from app.services.daily_mood_report_service import DailyMoodReportService
from app.services.growth_insight_service import GrowthInsightService


class _Moment:
    def __init__(self, note: str, emotion_tag: str = "calm", moment_id: str = "m1"):
        self.id = moment_id
        self.note = note
        self.emotion_tag = emotion_tag
        self.event_tags = ["其它"]


@pytest.mark.parametrize(
    "note",
    [
        "活着没什么意思了。",
        "我太累了，不想再坚持了。",
        "以后就没人烦你们了。",
        "如果我消失了，大家会不会更好。",
        "我已经不在乎疼不疼了。",
        "再见了，所有人。",
    ],
)
def test_psych_crisis_phrases_are_urgent_and_critical(note: str):
    matches = detect_crisis_phrases(note)
    assert matches
    assert matches[0].concern_level == "urgent"
    assert matches[0].is_critical
    assert note_has_critical_crisis(note)
    assert GrowthInsightService().moment_note_is_critical(_Moment(note))


@pytest.mark.parametrize(
    "note",
    [
        "我迟早要教训他。",
        "敢惹我，我不会放过你。",
        "大不了鱼死网破。",
        "放学后你等着。",
        "信不信我对你动手。",
    ],
)
def test_violence_threat_phrases_are_urgent_and_critical(note: str):
    matches = detect_crisis_phrases(note)
    assert matches
    assert matches[0].concern_level == "urgent"
    assert matches[0].is_critical
    assert GrowthInsightService().moment_note_is_critical(_Moment(note))


@pytest.mark.parametrize(
    "note",
    [
        "你们根本不配管我。",
        "我偏要做，谁也拦不住我。",
        "这个学我不上了。",
    ],
)
def test_defiance_phrases_are_watch_not_critical(note: str):
    matches = detect_crisis_phrases(note)
    assert matches
    assert matches[0].concern_level == "watch"
    assert not matches[0].is_critical
    assert not note_has_critical_crisis(note)
    assert not GrowthInsightService().moment_note_is_critical(_Moment(note))


@pytest.mark.parametrize(
    "note",
    [
        "高处摔下去也没事。",
        "这个东西玩起来很刺激，不怕出事。",
    ],
)
def test_danger_behavior_phrases_are_urgent_and_critical(note: str):
    matches = detect_crisis_phrases(note)
    assert matches
    assert matches[0].concern_level == "urgent"
    assert matches[0].is_critical
    assert GrowthInsightService().moment_note_is_critical(_Moment(note))


def test_daily_report_detects_danger_behavior_phrase():
    flags, level = DailyMoodReportService().detect_risk_signals(
        [_Moment("高处摔下去也没事。")]
    )

    assert level == "urgent"
    assert any("危险行为暗示" in flag for flag in flags)
