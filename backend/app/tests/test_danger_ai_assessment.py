from app.services.danger_ai_assessment import (
    apply_danger_ai_to_growth_insight,
    merge_concern_levels,
    merge_risk_flags,
    normalize_danger_ai,
    resolve_ai_flagged_moment_ids,
)


class _Moment:
    def __init__(self, moment_id: str):
        self.id = moment_id


def test_normalize_danger_ai_upgrades_watch_from_flagged_records():
    result = normalize_danger_ai(
        {
            "detected": True,
            "concern_level": "normal",
            "risk_level": "none",
            "risk_category": "psych_crisis",
            "risk_flags": ["AI-疑似轻生表达"],
            "flagged_records": [{"index": 0, "category": "psych_crisis", "label": "AI-告别式语气"}],
        }
    )

    assert result is not None
    assert result["concern_level"] == "urgent"
    assert result["risk_level"] == "critical"


def test_merge_concern_levels_takes_highest():
    assert merge_concern_levels("normal", "watch", "urgent") == "urgent"


def test_merge_risk_flags_deduplicates():
    merged = merge_risk_flags(["规则命中"], {"risk_flags": ["AI-苗头"], "flagged_records": []})
    assert merged == ["规则命中", "AI-苗头"]


def test_apply_danger_ai_upgrades_growth_insight():
    base = {
        "status": "observing",
        "need_attention": False,
        "risk_level": "none",
        "risk_reminder": None,
    }
    danger_ai = {
        "detected": True,
        "concern_level": "watch",
        "risk_level": "elevated",
        "risk_category": "emotional_stress",
        "risk_reminder": "建议尽快核实",
    }

    result = apply_danger_ai_to_growth_insight(base, danger_ai)

    assert result["status"] == "ongoing"
    assert result["need_attention"] is True
    assert result["risk_level"] == "elevated"
    assert result["ai_danger"]["risk_category"] == "emotional_stress"


def test_resolve_ai_flagged_moment_ids():
    moments = [_Moment("a"), _Moment("b")]
    danger_ai = {
        "flagged_records": [{"index": 1, "category": "psych_crisis", "label": "AI-苗头"}],
    }

    assert resolve_ai_flagged_moment_ids(moments, danger_ai) == ["b"]
