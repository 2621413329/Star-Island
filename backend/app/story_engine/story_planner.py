from app.models.observation import ObservationRecord
from app.models.rule import StoryRule
from app.prompts.story_prompts import DEFAULT_STORY_TEMPLATE_NAME
from app.story_engine.types import StoryPlan

DEFAULT_SECTIONS = ["event", "emotion_flow", "context"]


class StoryPlanner:
    def build_plan(self, record: ObservationRecord, selected_rule: StoryRule | None) -> StoryPlan:
        then = selected_rule.dsl.get("then", {}) if selected_rule else {}
        sections = then.get("sections") or DEFAULT_SECTIONS
        style = then.get("story_style") or "neutral"
        template_name = then.get("template") or DEFAULT_STORY_TEMPLATE_NAME
        image_style = then.get("image_style") or "soft cartoon"

        return StoryPlan(
            title_seed=record.event_title,
            style=style,
            sections=sections,
            template_name=template_name,
            required_fields=["story_title", "story_body", "emotion_flow", "sections"],
            image_style=image_style,
        )
