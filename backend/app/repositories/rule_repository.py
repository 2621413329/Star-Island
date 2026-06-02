from __future__ import annotations

import uuid

from sqlalchemy import Select, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.rule import StoryRule, StoryTemplate


class RuleRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, rule_id: uuid.UUID) -> StoryRule | None:
        return await self.db.get(StoryRule, rule_id)

    async def get_by_name(self, name: str) -> StoryRule | None:
        result = await self.db.execute(select(StoryRule).where(StoryRule.name == name))
        return result.scalar_one_or_none()

    async def list(self, page: int, page_size: int, active_only: bool = False) -> tuple[int, list[StoryRule]]:
        stmt: Select[tuple[StoryRule]] = select(StoryRule).order_by(StoryRule.priority.asc(), StoryRule.created_at.desc())
        count_stmt = select(func.count()).select_from(StoryRule)
        if active_only:
            stmt = stmt.where(StoryRule.is_active.is_(True))
            count_stmt = count_stmt.where(StoryRule.is_active.is_(True))

        total = await self.db.scalar(count_stmt) or 0
        result = await self.db.execute(stmt.offset((page - 1) * page_size).limit(page_size))
        return total, list(result.scalars().all())

    async def list_active(self) -> list[StoryRule]:
        result = await self.db.execute(
            select(StoryRule).where(StoryRule.is_active.is_(True)).order_by(StoryRule.priority.asc(), StoryRule.created_at.desc())
        )
        return list(result.scalars().all())

    async def create(self, rule: StoryRule) -> StoryRule:
        self.db.add(rule)
        await self.db.commit()
        await self.db.refresh(rule)
        return rule

    async def update(self, rule: StoryRule) -> StoryRule:
        await self.db.commit()
        await self.db.refresh(rule)
        return rule


class StoryTemplateRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_active_by_name(self, name: str) -> StoryTemplate | None:
        result = await self.db.execute(
            select(StoryTemplate)
            .where(StoryTemplate.name == name, StoryTemplate.is_active.is_(True))
            .order_by(StoryTemplate.created_at.desc())
        )
        return result.scalars().first()

    async def get_active_by_style(self, style: str) -> StoryTemplate | None:
        result = await self.db.execute(
            select(StoryTemplate)
            .where(StoryTemplate.style == style, StoryTemplate.is_active.is_(True))
            .order_by(StoryTemplate.created_at.desc())
        )
        return result.scalars().first()
