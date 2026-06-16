"""用户建筑解锁：写入数据库并在成长刷新时同步。"""

from __future__ import annotations

import uuid
from datetime import date, datetime, timezone

from app.config.growth_island_buildings import (
    buildings_for_growth_value,
    required_score_for_level,
)
from app.models.daily_mood_report import DailyMoodReport
from app.models.profile import DailyMoment
from app.models.user_building_unlock import UserBuildingUnlock
from app.repositories.user_building_unlock_repository import UserBuildingUnlockRepository
from app.services.growth_points_service import GrowthPointsService


class BuildingUnlockService:
    def __init__(
        self,
        repo: UserBuildingUnlockRepository,
        growth_points: GrowthPointsService | None = None,
    ):
        self.repo = repo
        self.growth_points = growth_points or GrowthPointsService()

    async def list_for_user(self, user_id: uuid.UUID) -> list[UserBuildingUnlock]:
        return await self.repo.list_by_user_id(user_id)

    async def sync_for_user(
        self,
        *,
        user_id: uuid.UUID,
        growth_value: int,
        moments: list[DailyMoment],
        reports: list[DailyMoodReport],
        profile_today_mood: str | None,
        today: date | None = None,
    ) -> None:
        today = today or date.today()
        unlocked = buildings_for_growth_value(growth_value)
        if not unlocked:
            return
        existing = await self.repo.get_unlocked_ids(user_id)
        for building_id, unlock_level in unlocked:
            if building_id in existing:
                continue
            unlocked_at = self._resolve_unlock_datetime(
                unlock_level=unlock_level,
                moments=moments,
                reports=reports,
                profile_today_mood=profile_today_mood,
                today=today,
            )
            await self.repo.create_if_absent(
                user_id=user_id,
                building_id=building_id,
                unlock_level=unlock_level,
                unlocked_at=unlocked_at,
            )

    def _resolve_unlock_datetime(
        self,
        *,
        unlock_level: int,
        moments: list[DailyMoment],
        reports: list[DailyMoodReport],
        profile_today_mood: str | None,
        today: date,
    ) -> datetime:
        target_score = required_score_for_level(unlock_level)
        if target_score is None:
            return datetime.now(timezone.utc)
        if target_score <= 0:
            if not moments:
                return datetime.now(timezone.utc)
            earliest = min(m.moment_date for m in moments)
            return datetime(earliest.year, earliest.month, earliest.day, tzinfo=timezone.utc)

        day_keys: set[date] = set()
        for moment in moments:
            d = moment.moment_date
            day_keys.add(d)
        for report in reports:
            day_keys.add(report.report_date)

        if not day_keys:
            return datetime.now(timezone.utc)

        for day in sorted(day_keys):
            day_moments = [m for m in moments if not self._is_after_day(m.moment_date, day)]
            day_reports = [r for r in reports if not self._is_after_day(r.report_date, day)]
            mood = profile_today_mood if day == today else None
            summary = self.growth_points.compute(
                moments=day_moments,
                reports=day_reports,
                today=today,
                profile_today_mood=mood,
            )
            if summary.growth_value >= target_score:
                return datetime(day.year, day.month, day.day, 12, 0, tzinfo=timezone.utc)

        return datetime.now(timezone.utc)

    @staticmethod
    def _is_after_day(value: date, day: date) -> bool:
        return value > day
