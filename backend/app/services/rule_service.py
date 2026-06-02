import uuid
from typing import Any

from app.exceptions.business import BusinessException
from app.models.rule import StoryRule
from app.repositories.rule_repository import RuleRepository
from app.schemas.rule import StoryRuleCreate, StoryRuleUpdate


SUPPORTED_WHEN_FIELDS = {"event_type", "emotion_tag", "growth_dimension", "student_id"}
SUPPORTED_THEN_FIELDS = {"story_style", "sections", "template", "image_style"}


class RuleService:
    def __init__(self, rule_repo: RuleRepository):
        self.rule_repo = rule_repo

    async def create(self, payload: StoryRuleCreate, created_by: uuid.UUID) -> StoryRule:
        if await self.rule_repo.get_by_name(payload.name):
            raise BusinessException("规则名称已存在", 409)
        dsl = self._validate_dsl(payload.dsl.model_dump())
        rule = StoryRule(
            name=payload.name,
            description=payload.description,
            dsl=dsl,
            priority=payload.priority,
            is_active=payload.is_active,
            created_by=created_by,
        )
        return await self.rule_repo.create(rule)

    async def update(self, rule_id: uuid.UUID, payload: StoryRuleUpdate) -> StoryRule:
        rule = await self.get(rule_id)
        update_data = payload.model_dump(exclude_unset=True)
        if "name" in update_data and update_data["name"] != rule.name:
            if await self.rule_repo.get_by_name(update_data["name"]):
                raise BusinessException("规则名称已存在", 409)
        if "dsl" in update_data and update_data["dsl"] is not None:
            update_data["dsl"] = self._validate_dsl(update_data["dsl"])

        for key, value in update_data.items():
            setattr(rule, key, value)
        return await self.rule_repo.update(rule)

    async def get(self, rule_id: uuid.UUID) -> StoryRule:
        rule = await self.rule_repo.get_by_id(rule_id)
        if not rule:
            raise BusinessException("规则不存在", 404)
        return rule

    async def list(self, page: int, page_size: int, active_only: bool = False):
        return await self.rule_repo.list(page, page_size, active_only)

    def _validate_dsl(self, dsl: dict[str, Any]) -> dict[str, Any]:
        when = dsl.get("when") or {}
        then = dsl.get("then") or {}
        if not isinstance(when, dict) or not isinstance(then, dict):
            raise BusinessException("规则 DSL 必须包含 when 和 then 对象", 422)
        unsupported_when = set(when) - SUPPORTED_WHEN_FIELDS
        unsupported_then = set(then) - SUPPORTED_THEN_FIELDS
        if unsupported_when:
            raise BusinessException(f"不支持的 when 字段: {', '.join(sorted(unsupported_when))}", 422)
        if unsupported_then:
            raise BusinessException(f"不支持的 then 字段: {', '.join(sorted(unsupported_then))}", 422)
        for field, values in when.items():
            if not isinstance(values, list):
                raise BusinessException(f"when.{field} 必须是列表", 422)
        if "sections" in then and not isinstance(then["sections"], list):
            raise BusinessException("then.sections 必须是列表", 422)
        return {"when": when, "then": then}
