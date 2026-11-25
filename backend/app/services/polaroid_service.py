"""拍立得：等级变化时插入，打开相册时补齐旧等级，总结在快门之后写。"""

from __future__ import annotations

import asyncio
import re
import uuid
from datetime import datetime, timezone

from loguru import logger
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.companion_dialogue import apply_nickname_to_template
from app.core.companion_roles import display_name_for_role, resolve_companion_role_id
from app.core.config import settings
from app.core.moment_content import get_story_content
from app.core.text_utils import soft_truncate
from app.database.database import AsyncSessionLocal
from app.exceptions.business import BusinessException
from app.models.island_polaroid import IslandPolaroid
from app.models.profile import DailyMoment, UserProfile
from app.models.story_island import StoryIsland
from app.models.user import User
from app.rag.qwen_provider import QwenLLMProvider
from app.repositories.island_polaroid_repository import IslandPolaroidRepository
from app.repositories.story_island_repository import StoryIslandRepository
from app.repositories.user_growth_state_repository import UserGrowthStateRepository
from app.services.polaroid_rules import (
    POLAROID_SKIN_PLAIN,
    front_caption,
    levels_to_capture,
    main_level_subject,
    notes_span,
    specific_back_fallback,
    story_level_subject,
    summary_is_specific,
)
from app.services.profile_service import ProfileService

AI_TIMEOUT_SEC = 12.0
SOURCE_LIMIT = 8
EXCERPT_LIMIT = 100

BACK_PROMPT = """你是伙伴「__COMPANION__」。给一张拍立得背面写这段日子的小结。
纯中文，两到三句，90到160字，句号结束。不加引号、标题、编号、表情。
必须写进日常里已经出现的具体事情，例如谁、做了什么、吃了什么、去了哪里，能对上日期就写出日期。
也要写到岛上的变化。不要空泛地说「这段日子很充实」「继续加油」。没有写到的事不要编。
称呼用户时使用占位符 {nickname}。
岛：__ISLAND__
变化：__CHANGE__
时间：__SPAN__
日常：
__NOTES__
"""


class PolaroidService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.repo = IslandPolaroidRepository(db)
        self.islands = StoryIslandRepository(db)
        self.growth = UserGrowthStateRepository(db)

    async def on_story_growth(
        self,
        user_id: uuid.UUID,
        island: StoryIsland,
        previous_growth: int,
        current_growth: int,
    ) -> list[uuid.UUID]:
        if self.islands.is_growth_main_island(island):
            return []
        previous_level = ProfileService._story_island_current_level(island.size_kind, previous_growth)
        current_level = ProfileService._story_island_current_level(island.size_kind, current_growth)
        if current_level < previous_level:
            await self.repo.delete_levels_above(user_id, island.id, current_level)
            return []
        created = await self._capture_levels(
            user_id,
            island,
            levels_to_capture(previous_level, current_level),
            kind="story",
            live=True,
        )
        return [row.id for row in created]

    async def on_main_level(
        self,
        user_id: uuid.UUID,
        previous_level: int,
        current_level: int,
    ) -> list[uuid.UUID]:
        island = await self.islands.ensure_growth_main_island(user_id)
        if current_level < previous_level:
            await self.repo.delete_levels_above(user_id, island.id, current_level)
            return []
        created = await self._capture_levels(
            user_id,
            island,
            levels_to_capture(previous_level, current_level),
            kind="main",
            live=True,
        )
        return [row.id for row in created]

    async def list_for_island(self, user_id: uuid.UUID, island_id: uuid.UUID) -> list[IslandPolaroid]:
        island = await self.islands.get_by_id_and_user(island_id, user_id)
        if island is None or island.is_archived:
            raise BusinessException("岛屿不存在或无权查看", 404)
        if self.islands.is_growth_main_island(island):
            state = await self.growth.get_by_user_id(user_id)
            current_level = state.level if state is not None else 1
            kind = "main"
        else:
            current_level = ProfileService._story_island_current_level(
                island.size_kind,
                int(island.growth_value or 0),
            )
            kind = "story"
        existing = await self.repo.list_for_island(user_id, island_id)
        have = {row.level for row in existing}
        missing = [level for level in range(1, max(current_level, 0) + 1) if level not in have]
        if missing:
            await self._capture_levels(user_id, island, missing, kind=kind, live=False)
        return await self.repo.list_for_island(user_id, island_id)

    async def get_one(self, user_id: uuid.UUID, polaroid_id: uuid.UUID) -> IslandPolaroid:
        row = await self.repo.get_by_id(polaroid_id, user_id)
        if row is None:
            raise BusinessException("拍立得不存在", 404)
        return row

    async def _capture_levels(
        self,
        user_id: uuid.UUID,
        island: StoryIsland,
        levels: list[int],
        *,
        kind: str,
        live: bool,
    ) -> list[IslandPolaroid]:
        if not levels:
            return []
        role_id, companion_name, nickname = await self._companion(user_id)
        sources = await self._source_payloads(user_id, island, kind=kind)
        has_text = any((item.get("excerpt") or "").strip() for item in sources)
        created: list[IslandPolaroid] = []
        for level in levels:
            if await self.repo.get_level(user_id, island.id, level) is not None:
                continue
            if kind == "main":
                subject, asset_key = main_level_subject(level)
                category_id = ""
            else:
                subject, asset_key = story_level_subject(island.category_id, level)
                category_id = island.category_id
            fallback = specific_back_fallback(subject, sources)
            ask_model = live and has_text
            row = IslandPolaroid(
                user_id=user_id,
                island_id=island.id,
                island_kind=kind,
                level=level,
                building_name=subject[:64],
                asset_key=asset_key[:128],
                category_id=category_id[:32],
                companion_role=role_id[:32],
                skin_id=POLAROID_SKIN_PLAIN,
                taken_at=datetime.now(timezone.utc) if live else _backfill_taken_at(island),
                front_caption=front_caption(subject)[:80],
                back_summary=None if ask_model else (fallback or None),
                back_status="developing" if ask_model else "fallback",
                captured_live=live,
                source_moments=sources,
            )
            try:
                async with self.db.begin_nested():
                    self.db.add(row)
                    await self.db.flush()
            except IntegrityError:
                continue
            try:
                saved = await self.repo.save(row)
            except IntegrityError:
                await self.db.rollback()
                continue
            created.append(saved)
            if saved.back_status == "developing":
                schedule_polaroid_summary(
                    saved.id,
                    island_name=island.name,
                    change=subject,
                    companion_name=companion_name,
                    nickname=nickname,
                    notes=_notes_block(sources),
                    span=notes_span(sources),
                    fallback=fallback,
                )
        return created

    async def _source_payloads(
        self,
        user_id: uuid.UUID,
        island: StoryIsland,
        *,
        kind: str,
    ) -> list[dict]:
        stmt = select(DailyMoment).where(DailyMoment.user_id == user_id)
        if kind == "story":
            stmt = stmt.where(DailyMoment.story_island_id == island.id)
        stmt = stmt.order_by(DailyMoment.moment_date.desc(), DailyMoment.created_at.desc()).limit(24)
        result = await self.db.execute(stmt)
        payloads: list[dict] = []
        for moment in result.scalars().all():
            text = get_story_content(moment)
            if not text:
                continue
            payloads.append(
                {
                    "id": str(moment.id),
                    "moment_date": moment.moment_date.isoformat(),
                    "excerpt": soft_truncate(text, EXCERPT_LIMIT),
                }
            )
            if len(payloads) >= SOURCE_LIMIT:
                break
        return payloads

    async def _companion(self, user_id: uuid.UUID) -> tuple[str, str, str | None]:
        profile_result = await self.db.execute(
            select(UserProfile).where(UserProfile.user_id == user_id)
        )
        profile = profile_result.scalar_one_or_none()
        user_result = await self.db.execute(select(User).where(User.id == user_id))
        user = user_result.scalar_one_or_none()
        role_id = resolve_companion_role_id(
            companion_role_id=getattr(profile, "companion_role_id", None),
            legacy_gender=getattr(profile, "gender", None),
        ) or ""
        name = display_name_for_role(
            role_id or None,
            legacy_gender=getattr(profile, "gender", None),
        )
        nickname = (getattr(user, "nickname", None) or "").strip() or None
        return role_id, name, nickname


def schedule_polaroid_summary(
    polaroid_id: uuid.UUID,
    *,
    island_name: str,
    change: str,
    companion_name: str,
    nickname: str | None,
    notes: str,
    span: str,
    fallback: str,
) -> None:
    try:
        loop = asyncio.get_running_loop()
    except RuntimeError:
        return
    loop.create_task(
        summarize_polaroid_back(
            polaroid_id,
            island_name=island_name,
            change=change,
            companion_name=companion_name,
            nickname=nickname,
            notes=notes,
            span=span,
            fallback=fallback,
        )
    )


async def summarize_polaroid_back(
    polaroid_id: uuid.UUID,
    *,
    island_name: str,
    change: str,
    companion_name: str,
    nickname: str | None,
    notes: str,
    span: str,
    fallback: str,
) -> None:
    async with AsyncSessionLocal() as session:
        repo = IslandPolaroidRepository(session)
        try:
            result = await session.execute(
                select(IslandPolaroid).where(IslandPolaroid.id == polaroid_id)
            )
            row = result.scalar_one_or_none()
            if row is None or row.back_status != "developing":
                return
            if not notes.strip():
                row.back_status = "fallback"
                await repo.save(row)
                return
            prompt = (
                BACK_PROMPT.replace("__COMPANION__", companion_name or "小星仔")
                .replace("__ISLAND__", island_name or "这座岛")
                .replace("__CHANGE__", change or "新的变化")
                .replace("__SPAN__", span or "最近这些天")
                .replace("__NOTES__", notes)
            )
            raw = await asyncio.wait_for(
                QwenLLMProvider().generate(
                    prompt,
                    model=settings.QWEN_FAST_MODEL,
                    temperature=0.35,
                    max_tokens=360,
                ),
                timeout=AI_TIMEOUT_SEC,
            )
            cleaned = re.sub(r"\s+", "", (raw or "").strip()).strip("「」\"'")
            cleaned = apply_nickname_to_template(cleaned, nickname)
            if summary_is_specific(cleaned):
                row.back_summary = cleaned[:400]
                row.back_status = "ready"
            elif fallback.strip():
                row.back_summary = fallback.strip()[:400]
                row.back_status = "fallback"
            else:
                row.back_status = "fallback"
            await repo.save(row)
        except Exception:
            logger.exception("polaroid summary failed id={}", polaroid_id)
            try:
                await session.rollback()
                result = await session.execute(
                    select(IslandPolaroid).where(IslandPolaroid.id == polaroid_id)
                )
                row = result.scalar_one_or_none()
                if row is not None and row.back_status == "developing":
                    if fallback.strip():
                        row.back_summary = fallback.strip()[:400]
                    row.back_status = "fallback"
                    await repo.save(row)
            except Exception:
                logger.exception("polaroid summary fallback failed id={}", polaroid_id)


def _notes_block(sources: list[dict]) -> str:
    lines = []
    for item in sources:
        excerpt = (item.get("excerpt") or "").strip()
        if not excerpt:
            continue
        lines.append(f"{item.get('moment_date') or ''} {excerpt}")
    return "\n".join(lines)


def _backfill_taken_at(island: StoryIsland) -> datetime:
    created = getattr(island, "created_at", None)
    if isinstance(created, datetime):
        if created.tzinfo is None:
            return created.replace(tzinfo=timezone.utc)
        return created
    return datetime.now(timezone.utc)
