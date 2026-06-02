import json
import time
from typing import Any

from app.models.observation import ObservationRecord
from app.models.rule import StoryRule, StoryTemplate
from app.story_engine.llm_gateway import LLMGateway
from app.story_engine.prompt_builder import PromptBuilder
from app.story_engine.rule_engine import RuleEngine
from app.story_engine.story_planner import StoryPlanner
from app.story_engine.types import StoryGenerationResult


class StoryOrchestrator:
    def __init__(
        self,
        rule_engine: RuleEngine | None = None,
        planner: StoryPlanner | None = None,
        prompt_builder: PromptBuilder | None = None,
        llm_gateway: LLMGateway | None = None,
    ):
        self.rule_engine = rule_engine or RuleEngine()
        self.planner = planner or StoryPlanner()
        self.prompt_builder = prompt_builder or PromptBuilder()
        self.llm_gateway = llm_gateway or LLMGateway()

    async def generate(
        self,
        record: ObservationRecord,
        rules: list[StoryRule],
        template: StoryTemplate | None = None,
    ) -> StoryGenerationResult:
        started_at = time.perf_counter()
        matched_rules = self.rule_engine.match_rules(record, rules)
        selected_rule = matched_rules[0] if matched_rules else None
        plan = self.planner.build_plan(record, selected_rule)
        prompt = self.prompt_builder.build(record, plan, selected_rule, template)
        raw_response = await self.llm_gateway.generate(prompt)
        payload = self._parse_response(raw_response)
        latency_ms = int((time.perf_counter() - started_at) * 1000)

        return StoryGenerationResult(
            story_title=payload.get("story_title") or record.event_title,
            story_body=payload.get("story_body") or raw_response,
            emotion_flow=payload.get("emotion_flow") or [],
            sections=payload.get("sections") or [],
            scene_prompt=payload.get("scene_prompt") or self._build_scene_prompt(record),
            image_style=plan.image_style,
            visual_payload={
                "emotion": record.emotion_tag,
                "source": record.event_type,
                "event": record.event_title,
            },
            raw_response=raw_response,
            selected_rule_id=selected_rule.id if selected_rule else None,
            selected_template_id=template.id if template else None,
            matched_rules=[self.rule_engine.serialize_rule(rule) for rule in matched_rules],
            plan=plan,
            prompt=prompt,
            latency_ms=latency_ms,
        )

    def _parse_response(self, raw_response: str) -> dict[str, Any]:
        try:
            payload = json.loads(raw_response)
        except json.JSONDecodeError:
            return {}
        return payload if isinstance(payload, dict) else {}

    def _build_scene_prompt(self, record: ObservationRecord) -> str:
        return f"{record.event_type} 场景中，学生经历了“{record.event_title}”，情绪标签为 {record.emotion_tag or '未标注'}。"
