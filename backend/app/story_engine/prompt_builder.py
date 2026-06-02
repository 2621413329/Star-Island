import json
from typing import Any

from app.models.observation import ObservationRecord
from app.models.rule import StoryRule, StoryTemplate
from app.prompts.story_prompts import DEFAULT_STORY_OUTPUT_SCHEMA, STORY_SYSTEM_PROMPTS, STORY_USER_PROMPT_TEMPLATE
from app.story_engine.types import StoryPlan


class PromptBuilder:
    def build(
        self,
        record: ObservationRecord,
        plan: StoryPlan,
        selected_rule: StoryRule | None,
        template: StoryTemplate | None = None,
    ) -> str:
        system_prompt = template.system_prompt if template else STORY_SYSTEM_PROMPTS.get(plan.style, STORY_SYSTEM_PROMPTS["neutral"])
        user_template = template.user_prompt_template if template else STORY_USER_PROMPT_TEMPLATE
        output_schema: dict[str, Any] = template.output_schema if template else DEFAULT_STORY_OUTPUT_SCHEMA

        record_payload = {
            "id": str(record.id),
            "student_id": str(record.student_id),
            "event_type": record.event_type,
            "event_title": record.event_title,
            "event_content": record.event_content,
            "emotion_tag": record.emotion_tag,
            "growth_dimension": record.growth_dimension,
            "created_at": record.created_at.isoformat() if record.created_at else None,
        }
        rule_payload = {
            "id": str(selected_rule.id),
            "name": selected_rule.name,
            "dsl": selected_rule.dsl,
        } if selected_rule else {}

        user_prompt = user_template.format(
            output_schema=json.dumps(output_schema, ensure_ascii=False),
            record=json.dumps(record_payload, ensure_ascii=False),
            plan=json.dumps(plan.model_dump(), ensure_ascii=False),
            rule=json.dumps(rule_payload, ensure_ascii=False),
        )
        return f"{system_prompt}\n\n{user_prompt}"
