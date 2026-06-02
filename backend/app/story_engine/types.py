import uuid
from dataclasses import dataclass, field
from typing import Any


@dataclass(slots=True)
class StoryPlan:
    title_seed: str
    style: str
    sections: list[str]
    template_name: str
    required_fields: list[str] = field(default_factory=list)
    image_style: str = "soft cartoon"

    def model_dump(self) -> dict[str, Any]:
        return {
            "title_seed": self.title_seed,
            "style": self.style,
            "sections": self.sections,
            "template_name": self.template_name,
            "required_fields": self.required_fields,
            "image_style": self.image_style,
        }


@dataclass(slots=True)
class StoryGenerationResult:
    story_title: str
    story_body: str
    emotion_flow: list[dict[str, Any]]
    sections: list[dict[str, Any]]
    scene_prompt: str
    image_style: str
    visual_payload: dict[str, Any]
    raw_response: str
    selected_rule_id: uuid.UUID | None
    selected_template_id: uuid.UUID | None
    matched_rules: list[dict[str, Any]]
    plan: StoryPlan
    prompt: str
    latency_ms: int | None = None
