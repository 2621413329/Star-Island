"""周期心情总体总结：仅传聚合统计给 AI，节省 token。"""

from __future__ import annotations

import asyncio
import re
from datetime import date, timedelta
from typing import Any

from loguru import logger

from app.config.emotion_catalog import (
    EMOTION_LABELS,
    EMOTION_LEGACY_MOOD,
    LEGACY_MOOD_LABELS,
    dominant_emotion_by_count,
    effective_emotion_for_moment,
)
from app.core.config import settings
from app.models.profile import DailyMoment
from app.rag.qwen_provider import QwenLLMProvider

CATEGORY_LABELS = {
    "学习": "学业",
    "朋友": "朋友",
    "运动": "运动",
    "家庭": "家庭",
    "兴趣": "兴趣",
    "其它": "其它",
}

PERIOD_LABELS = {
    "today": "今天",
    "week": "本周",
    "month": "本月",
    "year": "本年度",
}

MAX_SUMMARY_LEN = 100
MAX_SUMMARY_HARD_CAP = 320
MAX_CONTENT_ITEMS = 10
MAX_NOTE_SNIPPET = 40
AI_CALL_TIMEOUT_SEC = 8.0

PERIOD_SUMMARY_PROMPT = """你是个人成长记录助手，用户选择的成长伙伴是「{companion_name}」。
根据统计数据和以下日常记录摘要，写一段温暖、中性、不说教的周期总体总结。
要求：纯中文，100字左右；要提到具体发生的事或生活主题，不要只罗列感受词；内容完整时可略长，不必强行截断；不加标题和引号，不出现医学诊断。
统计：{stats_line}
日常摘要：
{content_block}
只输出总结正文。"""


def _clean_summary(text: str, *, hard_cap: int = MAX_SUMMARY_HARD_CAP) -> str:
    cleaned = re.sub(r"\s+", "", (text or "").strip())
    if len(cleaned) <= hard_cap:
        return cleaned
    return cleaned[:hard_cap]


def _period_start(period: str, today: date) -> date:
    if period == "week":
        return today - timedelta(days=today.weekday())
    if period == "month":
        return today.replace(day=1)
    if period == "year":
        return today.replace(month=1, day=1)
    return today


def _moment_category(moment: DailyMoment) -> str | None:
    primary = (getattr(moment, "primary_tag", None) or "").strip()
    if primary:
        return primary
    if moment.event_tags:
        return moment.event_tags[0]
    return None


def _filter_moments(
    moments: list[DailyMoment],
    *,
    period: str,
    today: date,
    category_filter: str | None,
) -> list[DailyMoment]:
    since = _period_start(period, today)
    filtered = [
        m
        for m in moments
        if since <= m.moment_date <= today
    ]
    if not category_filter:
        return filtered
    return [
        m
        for m in filtered
        if m.primary_tag == category_filter
        or (m.event_tags and m.event_tags[0] == category_filter)
    ]


def _aggregate(
    moments: list[DailyMoment],
) -> tuple[dict[str, int], dict[str, int]]:
    mood_counts = {k: 0 for k in EMOTION_LABELS}
    category_breakdown: dict[str, int] = {}
    for m in moments:
        emotion = effective_emotion_for_moment(m)
        mood_counts[emotion.emotion_id] = mood_counts.get(emotion.emotion_id, 0) + 1
        category = _moment_category(m)
        if category:
            category_breakdown[category] = category_breakdown.get(category, 0) + 1
    return mood_counts, category_breakdown


def _legacy_counts_from_emotion_counts(counts: dict[str, int]) -> dict[str, int]:
    legacy = {k: 0 for k in LEGACY_MOOD_LABELS}
    for emotion_id, count in counts.items():
        if count <= 0:
            continue
        legacy_id = EMOTION_LEGACY_MOOD.get(emotion_id, emotion_id)
        legacy[legacy_id] = legacy.get(legacy_id, 0) + count
    return legacy


def _moment_text(moment: DailyMoment) -> str:
    return re.sub(r"\s+", " ", ((moment.note or moment.speech_text or "").strip()))


def _content_block(moments: list[DailyMoment]) -> str:
    lines: list[str] = []
    sorted_moments = sorted(
        moments,
        key=lambda m: (m.moment_date, getattr(m, "created_at", m.moment_date)),
        reverse=True,
    )
    for moment in sorted_moments:
        text = _moment_text(moment)
        if not text:
            continue
        tag = _moment_category(moment) or "日常"
        emotion = effective_emotion_for_moment(moment)
        em_label = (moment.ai_emotion or emotion.label).strip()
        snippet = (
            text
            if len(text) <= MAX_NOTE_SNIPPET
            else text[:MAX_NOTE_SNIPPET] + "…"
        )
        date_str = moment.moment_date.strftime("%m-%d")
        lines.append(f"{date_str} [{tag}/{em_label}] {snippet}")
        if len(lines) >= MAX_CONTENT_ITEMS:
            break
    return "\n".join(lines) if lines else "（暂无文字摘要）"


def _content_snippets_for_rule(moments: list[DailyMoment], limit: int = 2) -> str:
    parts: list[str] = []
    sorted_moments = sorted(
        moments,
        key=lambda m: (m.moment_date, getattr(m, "created_at", m.moment_date)),
        reverse=True,
    )
    for moment in sorted_moments:
        text = _moment_text(moment)
        if not text:
            continue
        tag = _moment_category(moment) or "日常"
        snippet = text if len(text) <= 18 else text[:18] + "…"
        parts.append(f"{tag}「{snippet}」")
        if len(parts) >= limit:
            break
    return "，".join(parts)


def _stats_line(
    *,
    period: str,
    total: int,
    mood_counts: dict[str, int],
    category_breakdown: dict[str, int],
    category_filter: str | None,
) -> str:
    period_label = PERIOD_LABELS.get(period, period)
    mood_parts = [
        f"{EMOTION_LABELS[k]}{v}"
        for k, v in mood_counts.items()
        if v > 0
    ]
    mood_str = " ".join(mood_parts) if mood_parts else "无"
    top_cats = sorted(category_breakdown.items(), key=lambda x: -x[1])[:3]
    cat_str = (
        " ".join(
            f"{CATEGORY_LABELS.get(k, k)}{v}" for k, v in top_cats
        )
        if top_cats
        else "无"
    )
    filter_note = (
        f"筛选{CATEGORY_LABELS.get(category_filter, category_filter)}"
        if category_filter
        else ""
    )
    return (
        f"周期{period_label} 共{total}条 {filter_note} "
        f"心情:{mood_str} 标签:{cat_str}"
    ).strip()


def _rule_summary(
    *,
    period: str,
    total: int,
    mood_counts: dict[str, int],
    category_breakdown: dict[str, int],
    category_filter: str | None,
    moments: list[DailyMoment] | None = None,
) -> str:
    period_label = PERIOD_LABELS.get(period, period)
    if total == 0:
        return _clean_summary(
            f"{period_label}还没有心情记录，记下故事后这里会出现总结～"
        )

    top_mood = dominant_emotion_by_count(mood_counts) or "calm"
    top_label = EMOTION_LABELS.get(top_mood, "平静")
    top_cats = sorted(category_breakdown.items(), key=lambda x: -x[1])
    cat_part = ""
    if top_cats:
        labels = [
            CATEGORY_LABELS.get(c[0], c[0]) for c in top_cats[:2]
        ]
        cat_part = f"，{'和'.join(labels)}相关记录较多"

    legacy = _legacy_counts_from_emotion_counts(mood_counts)
    negative = legacy.get("sad", 0) + legacy.get("angry", 0)
    neg_ratio = negative / total if total else 0.0
    if neg_ratio >= 0.4:
        tone = "情绪有些起伏，记得照顾好自己"
    elif neg_ratio >= 0.2:
        tone = "整体有起有落，节奏还算正常"
    else:
        tone = f"以{top_label}为主，整体比较平稳"

    if category_filter:
        cat_label = CATEGORY_LABELS.get(category_filter, category_filter)
        text = (
            f"{period_label}在「{cat_label}」下共{total}条心情"
            f"{cat_part}，{tone}～"
        )
    else:
        text = f"{period_label}共{total}条心情{cat_part}，{tone}～"

    content_part = _content_snippets_for_rule(moments or [])
    if content_part:
        text = f"{text[:-1]}，{content_part}～"
    return _clean_summary(text)


class MoodPeriodSummaryService:
    async def build_summary(
        self,
        moments: list[DailyMoment],
        *,
        period: str = "today",
        category_filter: str | None = None,
        today: date | None = None,
        companion_name: str = "小星仔",
    ) -> dict[str, Any]:
        today = today or date.today()
        scoped = _filter_moments(
            moments,
            period=period,
            today=today,
            category_filter=category_filter,
        )
        total = len(scoped)
        mood_counts, category_breakdown = _aggregate(scoped)
        stats_line = _stats_line(
            period=period,
            total=total,
            mood_counts=mood_counts,
            category_breakdown=category_breakdown,
            category_filter=category_filter,
        )
        content_block = _content_block(scoped)
        fallback = _rule_summary(
            period=period,
            total=total,
            mood_counts=mood_counts,
            category_breakdown=category_breakdown,
            category_filter=category_filter,
            moments=scoped,
        )

        ai_summary, ai_generated = await self._try_ai(
            stats_line,
            content_block,
            fallback,
            companion_name=companion_name,
        )
        return {
            "period": period,
            "category_filter": category_filter,
            "summary": ai_summary,
            "ai_generated": ai_generated,
            "total_moments": total,
            "mood_counts": mood_counts,
            "dominant_mood": dominant_emotion_by_count(mood_counts),
        }

    async def _try_ai(
        self,
        stats_line: str,
        content_block: str,
        fallback: str,
        *,
        companion_name: str = "小星仔",
    ) -> tuple[str, bool]:
        if not settings.QWEN_API_KEY:
            return fallback, False
        prompt = PERIOD_SUMMARY_PROMPT.format(
            companion_name=companion_name,
            stats_line=stats_line,
            content_block=content_block,
        )
        try:
            provider = QwenLLMProvider()
            raw = await asyncio.wait_for(
                provider.generate(
                    prompt,
                    model=settings.QWEN_FAST_MODEL,
                    max_tokens=200,
                    temperature=0.6,
                ),
                timeout=AI_CALL_TIMEOUT_SEC,
            )
            cleaned = _clean_summary(
                re.sub(r"^[\"'「」]+|[\"'「」]+$", "", raw.strip()),
            )
            if len(cleaned) >= 8:
                return cleaned, True
            logger.warning("mood period summary AI: output too short")
        except (asyncio.TimeoutError, TimeoutError):
            logger.warning(
                "mood period summary AI timed out after {}s",
                AI_CALL_TIMEOUT_SEC,
            )
        except Exception as exc:
            logger.warning("mood period summary AI failed: {}", exc)
        return fallback, False
