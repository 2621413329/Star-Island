"""个人成长周期小结：基于心情趋势与记录的轻量 / AI 提示。"""

from __future__ import annotations

import asyncio
import re
from datetime import date, timedelta
from typing import Any

from loguru import logger

from app.core.config import settings
from app.models.daily_mood_report import DailyMoodReport
from app.models.profile import DailyMoment
from app.rag.qwen_provider import QwenLLMProvider

DISCLAIMER = "本小结基于你的记录自动生成，仅供参考，不构成专业诊断。"

MOOD_SCORE = {
    "happy": 4,
    "calm": 3,
    "thinking": 2,
    "sad": 1,
    "angry": 0,
}

MOOD_LABELS = {
    "happy": "开心",
    "calm": "平静",
    "thinking": "若有所思",
    "sad": "低落",
    "angry": "生气",
}

TREND_LABELS = {
    "stable": "稳定",
    "worsening": "有些起伏",
    "significantly_worsening": "最近偏累",
}

WEEKLY_HINT_PROMPT = """你是成长记录 App 的温柔陪伴助手「小星」。根据用户本周记录数据，写一句本周小结（纯中文，不超过 36 字，不加引号与标题，不说教、不诊断）。
要求：提及记录次数或主要生活主题之一，语气像朋友聊天。
数据：{stats}
只输出小结正文。"""

AI_CALL_TIMEOUT_SEC = 8.0


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
        base = self.analyze_period(
            reports, moments, anchor_date=anchor_date, days=days
        )
        if skip_ai or not settings.QWEN_API_KEY:
            return base

        window_moments = [
            m
            for m in moments
            if (anchor_date or date.today()) - timedelta(days=max(days - 1, 0))
            <= m.moment_date
            <= (anchor_date or date.today())
        ]
        if not window_moments:
            return base

        try:
            ai_hint = await self._build_weekly_hint_with_ai(
                window_moments,
                emotion_trend=base.get("emotion_trend") or {},
            )
            if ai_hint:
                base["weekly_hint"] = ai_hint
        except Exception as exc:
            logger.warning("weekly hint AI failed: {}", exc)
        return base

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

    def _aggregate_tags(self, moments: list[DailyMoment]) -> dict[str, int]:
        counts: dict[str, int] = {}
        for moment in moments:
            primary = (moment.primary_tag or "").strip()
            if not primary and moment.event_tags:
                primary = moment.event_tags[0]
            if primary:
                counts[primary] = counts.get(primary, 0) + 1
        return counts

    def _build_weekly_hint(
        self,
        emotion_trend: dict[str, Any],
        moments: list[DailyMoment],
    ) -> str:
        if not moments:
            return "这周还没有太多记录，随手记一件小事吧～"

        direction = emotion_trend.get("direction", "stable")
        tag_counts = self._aggregate_tags(moments)
        top_tags = sorted(tag_counts.items(), key=lambda x: (-x[1], x[0]))[:2]
        tag_part = ""
        if top_tags:
            tag_labels = "、".join(label for label, _ in top_tags)
            tag_part = f"，{tag_labels}出现得比较多"

        if direction == "significantly_worsening":
            return f"这周记录了 {len(moments)} 次{tag_part}，最近好像有点累，记得照顾自己～"
        if direction == "worsening":
            return f"这周记录了 {len(moments)} 次{tag_part}，情绪有些起伏，给自己一点空隙吧～"
        if len(moments) >= 5:
            return f"这周已记录 {len(moments)} 次{tag_part}，节奏很稳，继续保持～"
        return f"这周记录了 {len(moments)} 次{tag_part}，整体节奏还不错，继续保持记录的习惯～"

    async def _build_weekly_hint_with_ai(
        self,
        moments: list[DailyMoment],
        *,
        emotion_trend: dict[str, Any],
    ) -> str:
        tag_counts = self._aggregate_tags(moments)
        mood_counts: dict[str, int] = {}
        for moment in moments:
            label = MOOD_LABELS.get(moment.emotion_tag, moment.emotion_tag)
            mood_counts[label] = mood_counts.get(label, 0) + 1

        tag_line = "、".join(f"{k}{v}次" for k, v in sorted(tag_counts.items(), key=lambda x: -x[1])[:4])
        mood_line = "、".join(f"{k}{v}次" for k, v in mood_counts.items())
        stats = (
            f"本周记录{len(moments)}次；"
            f"主题分布：{tag_line or '暂无'}；"
            f"心情：{mood_line or '暂无'}；"
            f"趋势：{emotion_trend.get('label', '稳定')}"
        )
        prompt = WEEKLY_HINT_PROMPT.format(stats=stats)
        raw = await asyncio.wait_for(
            QwenLLMProvider().generate(
                prompt,
                model=settings.QWEN_FAST_MODEL,
                temperature=0.35,
                max_tokens=80,
            ),
            timeout=AI_CALL_TIMEOUT_SEC,
        )
        cleaned = re.sub(r"\s+", "", (raw or "").strip())
        if len(cleaned) < 6:
            return ""
        return cleaned[:36]
