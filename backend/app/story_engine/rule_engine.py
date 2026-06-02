from typing import Any

from app.models.observation import ObservationRecord
from app.models.rule import StoryRule


class RuleEngine:
    def match_rules(self, record: ObservationRecord, rules: list[StoryRule]) -> list[StoryRule]:
        matched = [rule for rule in rules if rule.is_active and self._matches(record, rule.dsl.get("when", {}))]
        return sorted(matched, key=lambda item: (item.priority, item.created_at))

    def _matches(self, record: ObservationRecord, conditions: dict[str, list[Any]]) -> bool:
        if not conditions:
            return True
        record_values = {
            "event_type": record.event_type,
            "emotion_tag": record.emotion_tag,
            "growth_dimension": record.growth_dimension,
            "student_id": str(record.student_id),
        }
        for field, expected_values in conditions.items():
            if record_values.get(field) not in [str(value) if field == "student_id" else value for value in expected_values]:
                return False
        return True

    def serialize_rule(self, rule: StoryRule) -> dict[str, Any]:
        return {
            "id": str(rule.id),
            "name": rule.name,
            "priority": rule.priority,
            "dsl": rule.dsl,
        }
