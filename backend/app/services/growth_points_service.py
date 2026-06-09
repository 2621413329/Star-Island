"""成长值与等级：按日汇总，防止刷次数，奖励坚持与认真记录。"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, timedelta

from app.models.daily_mood_report import DailyMoodReport
from app.models.profile import DailyMoment

# 完善记录：事件描述最低有效字数（去除空白）
MIN_DETAIL_NOTE_LEN = 10

DAILY_MOOD_XP = 10
DAILY_DETAIL_XP = 5
DAILY_AI_SUMMARY_XP = 5

STREAK_MILESTONE_XP: dict[int, int] = {
    2: 5,
    3: 10,
    7: 20,
    14: 30,
    30: 50,
    60: 100,
    100: 150,
    365: 500,
}

LEVEL_THRESHOLDS: list[tuple[int, str]] = [
    (0, "漂流者"),
    (25, "登岛者"),   # 连续 2 天完成记录（约 10+10+ streak5）
    (55, "守望者"),
    (95, "探索者"),
    (145, "建造者"),
    (205, "追光者"),
    (275, "灯塔守护者"),
    (355, "星海旅人"),
    (445, "梦想岛主"),
    (545, "成长观察者"),
]

LEVEL_UNLOCKS: dict[int, str] = {
    1: "荒岛草地",
    2: "小树苗",
    3: "发光石",
    4: "花丛",
    5: "木屋",
    6: "风车",
    7: "灯塔",
    8: "夜空星光",
    9: "岛屿扩建",
    10: "成长纪念馆",
}


@dataclass
class DayActivity:
    mood_recorded: bool = False
    detail_complete: bool = False
    ai_summary_done: bool = False


@dataclass
class GrowthSummary:
    growth_value: int
    level: int
    level_title: str
    streak_days: int
    max_streak_days: int
    next_level: int | None
    next_level_title: str | None
    xp_into_level: int
    xp_for_next_level: int | None
    island_stage: int
    unlock_label: str
    today_mood: str | None
    today_weather_label: str


class GrowthPointsService:
    def compute(
        self,
        *,
        moments: list[DailyMoment],
        reports: list[DailyMoodReport],
        today: date,
        profile_today_mood: str | None,
    ) -> GrowthSummary:
        day_map: dict[date, DayActivity] = {}

        for m in moments:
            d = m.moment_date
            act = day_map.setdefault(d, DayActivity())
            act.mood_recorded = True
            note = (m.note or "").strip()
            if note and len(note) >= MIN_DETAIL_NOTE_LEN and m.event_tags:
                act.detail_complete = True

        for r in reports:
            act = day_map.setdefault(r.report_date, DayActivity())
            act.mood_recorded = True
            if r.ai_generated:
                act.ai_summary_done = True
            elif r.student_insight or r.growth_insight:
                act.ai_summary_done = True

        if profile_today_mood:
            act = day_map.setdefault(today, DayActivity())
            act.mood_recorded = True

        daily_xp = 0
        for act in day_map.values():
            if act.mood_recorded:
                daily_xp += DAILY_MOOD_XP
            if act.detail_complete:
                daily_xp += DAILY_DETAIL_XP
            if act.ai_summary_done:
                daily_xp += DAILY_AI_SUMMARY_XP

        active_days = sorted(day_map.keys())
        max_streak = self._max_streak(active_days)
        current_streak = self._current_streak(active_days, today)
        streak_bonus = sum(
            xp for threshold, xp in STREAK_MILESTONE_XP.items() if max_streak >= threshold
        )
        weekly_bonus = self._weekly_bonus(active_days)

        growth_value = daily_xp + streak_bonus + weekly_bonus
        level, title = self._resolve_level(growth_value)
        next_lv, next_title, xp_into, xp_need = self._next_level_progress(growth_value, level)

        mood = profile_today_mood
        weather = _mood_weather_label(mood)

        return GrowthSummary(
            growth_value=growth_value,
            level=level,
            level_title=title,
            streak_days=current_streak,
            max_streak_days=max_streak,
            next_level=next_lv,
            next_level_title=next_title,
            xp_into_level=xp_into,
            xp_for_next_level=xp_need,
            island_stage=level,
            unlock_label=LEVEL_UNLOCKS.get(level, ""),
            today_mood=mood,
            today_weather_label=weather,
        )

    def _weekly_bonus(self, active_days: list[date]) -> int:
        if not active_days:
            return 0
        by_week: dict[tuple[int, int], set[date]] = {}
        for d in active_days:
            iso = d.isocalendar()
            key = (iso[0], iso[1])
            by_week.setdefault(key, set()).add(d)
        total = 0
        for days in by_week.values():
            n = len(days)
            if n >= 7:
                total += 50
            elif n >= 5:
                total += 20
        return total

    def _max_streak(self, days: list[date]) -> int:
        if not days:
            return 0
        sorted_days = sorted(set(days))
        best = cur = 1
        for i in range(1, len(sorted_days)):
            if sorted_days[i] - sorted_days[i - 1] == timedelta(days=1):
                cur += 1
                best = max(best, cur)
            else:
                cur = 1
        return best

    def _current_streak(self, days: list[date], today: date) -> int:
        day_set = set(days)
        if not day_set:
            return 0
        cursor = today
        if cursor not in day_set:
            cursor = today - timedelta(days=1)
            if cursor not in day_set:
                return 0
        streak = 0
        while cursor in day_set:
            streak += 1
            cursor -= timedelta(days=1)
        return streak

    def _resolve_level(self, growth_value: int) -> tuple[int, str]:
        level = 1
        title = LEVEL_THRESHOLDS[0][1]
        for idx, (threshold, name) in enumerate(LEVEL_THRESHOLDS):
            if growth_value >= threshold:
                level = idx + 1
                title = name
        return level, title

    def _next_level_progress(
        self, growth_value: int, level: int
    ) -> tuple[int | None, str | None, int, int | None]:
        if level >= len(LEVEL_THRESHOLDS):
            return None, None, growth_value - LEVEL_THRESHOLDS[-1][0], None
        current_threshold = LEVEL_THRESHOLDS[level - 1][0]
        next_threshold, next_title = LEVEL_THRESHOLDS[level]
        return (
            level + 1,
            next_title,
            growth_value - current_threshold,
            next_threshold - current_threshold,
        )


def aggregate_emotion_fragments(moments: list[DailyMoment]) -> tuple[int, dict[str, int]]:
    """每条 daily_moment 视为一片情绪碎片，按 emotion_tag 汇总。"""
    totals: dict[str, int] = {}
    for moment in moments:
        tag = moment.emotion_tag or "calm"
        totals[tag] = totals.get(tag, 0) + 1
    return len(moments), totals


def _mood_weather_label(mood: str | None) -> str:
    return {
        "happy": "☀ 超开心",
        "calm": "☀ 平静",
        "thinking": "✨ 思考",
        "sad": "🌫 低落",
        "angry": "🌧 生气",
    }.get(mood or "", "☀ 平静")
