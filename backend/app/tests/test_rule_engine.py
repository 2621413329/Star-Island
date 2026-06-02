from datetime import datetime, timezone
from types import SimpleNamespace
from uuid import uuid4

from app.models.rule import StoryRule
from app.story_engine.rule_engine import RuleEngine


def test_rule_engine_matches_by_priority():
    record = SimpleNamespace(
        event_type="课堂表现",
        emotion_tag="happy",
        growth_dimension="self_management",
        student_id=uuid4(),
    )
    low_priority = StoryRule(
        id=uuid4(),
        name="low",
        dsl={"when": {"event_type": ["课堂表现"]}, "then": {}},
        priority=100,
        is_active=True,
        created_at=datetime.now(timezone.utc),
    )
    high_priority = StoryRule(
        id=uuid4(),
        name="high",
        dsl={"when": {"emotion_tag": ["happy"]}, "then": {}},
        priority=10,
        is_active=True,
        created_at=datetime.now(timezone.utc),
    )

    matched = RuleEngine().match_rules(record, [low_priority, high_priority])

    assert [rule.name for rule in matched] == ["high", "low"]
