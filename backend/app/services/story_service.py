import uuid
from datetime import date, datetime, time, timedelta, timezone
from typing import Any

from app.exceptions.business import BusinessException
from app.models.observation import ObservationRecord
from app.models.story import Story, StoryGenerationRun
from app.repositories.observation_repository import ObservationRepository
from app.repositories.rule_repository import RuleRepository, StoryTemplateRepository
from app.repositories.story_repository import StoryRepository
from app.schemas.story import StoryGenerateRequest
from app.story_engine import StoryOrchestrator
from app.story_engine.rule_engine import RuleEngine
from app.story_engine.story_planner import StoryPlanner


class StoryService:
    def __init__(
        self,
        story_repo: StoryRepository,
        observation_repo: ObservationRepository,
        rule_repo: RuleRepository,
        template_repo: StoryTemplateRepository,
        orchestrator: StoryOrchestrator | None = None,
    ):
        self.story_repo = story_repo
        self.observation_repo = observation_repo
        self.rule_repo = rule_repo
        self.template_repo = template_repo
        self.orchestrator = orchestrator or StoryOrchestrator()

    async def generate(self, payload: StoryGenerateRequest, created_by: uuid.UUID) -> Story:
        record = await self.observation_repo.get_by_id(payload.observation_record_id)
        if not record:
            raise BusinessException("观察记录不存在", 404)
        rules = await self.rule_repo.list_active()
        matched_rules = RuleEngine().match_rules(record, rules)
        selected_rule = matched_rules[0] if matched_rules else None
        plan = StoryPlanner().build_plan(record, selected_rule)
        selected_template = await self.template_repo.get_active_by_name(plan.template_name)
        result = await self.orchestrator.generate(record, rules, selected_template)

        story = Story(
            student_id=record.student_id,
            source_record_id=record.id,
            rule_id=result.selected_rule_id,
            template_id=result.selected_template_id,
            title=result.story_title,
            body=result.story_body,
            emotion_flow=result.emotion_flow,
            sections=result.sections,
            scene_prompt=result.scene_prompt,
            image_style=result.image_style,
            visual_payload=result.visual_payload,
            status="generated",
            created_by=created_by,
        )
        run = StoryGenerationRun(
            record_snapshot=self._snapshot_record(record),
            matched_rules=result.matched_rules,
            plan=result.plan.model_dump(),
            prompt=result.prompt,
            llm_response=result.raw_response,
            status="success",
            latency_ms=result.latency_ms,
        )
        return await self.story_repo.create_with_run(story, run)

    async def get(self, story_id: uuid.UUID) -> Story:
        story = await self.story_repo.get_by_id(story_id)
        if not story:
            raise BusinessException("故事不存在", 404)
        return story

    async def list_daily(self, student_id: uuid.UUID, target_date: date | None = None) -> list[Story]:
        start_at, end_at = self._day_range(target_date or date.today())
        return await self.story_repo.list_by_student(student_id, start_at, end_at)

    async def list_week(self, student_id: uuid.UUID, target_date: date | None = None) -> list[Story]:
        current = target_date or date.today()
        start_date = current - timedelta(days=current.weekday())
        start_at = datetime.combine(start_date, time.min, tzinfo=timezone.utc)
        end_at = start_at + timedelta(days=7)
        return await self.story_repo.list_by_student(student_id, start_at, end_at)

    async def list(self, page: int, page_size: int, student_id: uuid.UUID | None = None):
        return await self.story_repo.list(page, page_size, student_id)

    def _day_range(self, target_date: date) -> tuple[datetime, datetime]:
        start_at = datetime.combine(target_date, time.min, tzinfo=timezone.utc)
        return start_at, start_at + timedelta(days=1)

    def _snapshot_record(self, record: ObservationRecord) -> dict[str, Any]:
        return {
            "id": str(record.id),
            "student_id": str(record.student_id),
            "event_type": record.event_type,
            "event_title": record.event_title,
            "event_content": record.event_content,
            "emotion_tag": record.emotion_tag,
            "growth_dimension": record.growth_dimension,
            "created_by": str(record.created_by),
            "created_at": record.created_at.isoformat() if record.created_at else None,
        }
