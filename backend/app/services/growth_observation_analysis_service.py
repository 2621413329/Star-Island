"""个人成长周期小结：基于心情趋势的轻量提示。"""

from __future__ import annotations

from datetime import date, timedelta
from typing import Any

from app.models.daily_mood_report import DailyMoodReport
from app.models.profile import DailyMoment

DISCLAIMER = "本小结基于你的记录自动生成，仅供参考，不构成专业诊断。"

MOOD_SCORE = {
    "happy": 4,
    "calm": 3,
    "thinking": 2,
    "sad": 1,
    "angry": 0,
}

TREND_LABELS = {
    "stable": "稳定",
    "worsening": "有些起伏",
    "significantly_worsening": "最近偏累",
}


class GrowthObservationAnalysisService:
    """保留类名以兼容 profile_service 注入。"""

    def analyze_period(
        self,
        reports: list[DailyMoodReport],
        moments: list[DailyMoment],
        *,
        anchor_date: date | None = None,
        days: int = 7,
    ) -> dict[str, Any]:
        anchor = anchor_date or date.today()
        since = anchor - timedelta(days=max(days - 1, 0))
        window_reports = sorted(
            [r for r in reports if since <= r.report_date <= anchor],
            key=lambda r: r.report_date,
        )
        window_moments = [m for m in moments if since <= m.moment_date <= anchor]
        emotion_trend = self._calc_emotion_trend(window_reports, window_moments)
        weekly_hint = self._build_weekly_hint(emotion_trend, window_moments)

        return {
            "weekly_hint": weekly_hint,
            "emotion_trend": emotion_trend,
            "disclaimer": DISCLAIMER,
            "analysis_window": {
                "from": since.isoformat(),
                "to": anchor.isoformat(),
                "days": days,
                "moment_count": len(window_moments),
                "report_days": len(window_reports),
            },
        }

    async def analyze_period_with_ai(
        self,
        reports: list[DailyMoodReport],
        moments: list[DailyMoment],
        *,
        anchor_date: date | None = None,
        days: int = 7,
        skip_ai: bool = False,
    ) -> dict[str, Any]:
        del skip_ai
        return self.analyze_period(
            reports, moments, anchor_date=anchor_date, days=days
        )

    def _calc_emotion_trend(
        self,
        reports: list[DailyMoodReport],
        moments: list[DailyMoment],
    ) -> dict[str, Any]:
        scores: list[float] = []
        for report in reports:
            counts = report.mood_counts or {}
            if not counts:
                continue
            total = sum(counts.values()) or 1
            avg = sum(MOOD_SCORE.get(k, 2) * v for k, v in counts.items()) / total
            scores.append(avg)

        if not scores and moments:
            counts: dict[str, int] = {}
            for m in moments:
                counts[m.emotion_tag] = counts.get(m.emotion_tag, 0) + 1
            total = sum(counts.values()) or 1
            scores.append(
                sum(MOOD_SCORE.get(k, 2) * v for k, v in counts.items()) / total
            )

        if len(scores) < 2:
            direction = "stable"
        else:
            delta = scores[-1] - scores[0]
            if delta <= -1.2:
                direction = "significantly_worsening"
            elif delta <= -0.45:
                direction = "worsening"
            else:
                direction = "stable"

        return {
            "direction": direction,
            "label": TREND_LABELS[direction],
        }

    def _build_weekly_hint(
        self,
        emotion_trend: dict[str, Any],
        moments: list[DailyMoment],
    ) -> str:
        if not moments:
            return "这周还没有太多记录，随手记一件小事吧～"

        direction = emotion_trend.get("direction", "stable")
        if direction == "significantly_worsening":
            return "最近好像有点累，记得照顾自己的感受～"
        if direction == "worsening":
            return "这周情绪有些起伏，给自己一点空隙吧～"
        return "这周整体节奏还不错，继续保持记录的习惯～"
