from __future__ import annotations

import asyncio
import json
import re
from datetime import date, datetime, timezone
from typing import Any

from loguru import logger

from app.core.config import settings
from app.core.moment_content import get_story_content
from app.models.profile import DailyMoment
from app.rag.qwen_provider import QwenLLMProvider

MOOD_LABELS = {
    "happy": "超开心",
    "calm": "开心",
    "thinking": "平静",
    "sad": "低落",
    "angry": "生气",
}

CATEGORY_LABELS = {
    "学习": "学业",
    "朋友": "朋友",
    "运动": "运动",
    "家庭": "家庭",
    "兴趣": "兴趣",
    "其它": "其它",
}

CONCERN_ORDER = {"urgent": 3, "watch": 2, "normal": 1}

BRIEF_MAX_LEN = 30
AI_CALL_TIMEOUT_SEC = 8.0


def _brief(text: str, limit: int = BRIEF_MAX_LEN) -> str:
    cleaned = re.sub(r"\s+", "", (text or "").strip())
    if len(cleaned) <= limit:
        return cleaned
    return cleaned[:limit]


def _merge_concern_levels(rule_level: str, ai_level: str | None) -> str:
    ai = (ai_level or "normal").strip()
    if CONCERN_ORDER.get(ai, 1) > CONCERN_ORDER.get(rule_level, 1):
        return ai
    return rule_level


REPORT_PROMPT = """你是个人成长记录的 AI 助手。基于「结构化摘要」生成陪伴式文案。

【隐私】private_notes 仅供理解；任何字段都不得引用、复述或暗示备注原文；不得出现人名、具体事件细节。

【语气】柔和、陪伴、不说教；用「你」；可适度语气词（～、呢）但克制。
- insight：侧重感受与觉察，≤30字
- warm_suggestion：温和建议，≤30字
- concern_level：normal|watch|urgent（仅反映当日情绪强度，非诊断）

只输出 JSON：
{
  "insight": "≤30字",
  "warm_suggestion": "≤30字",
  "concern_level": "normal|watch|urgent"
}

输入摘要：
"""


class DailyMoodReportService:
    def __init__(self, llm: QwenLLMProvider | None = None):
        self._llm = llm

    def _llm_or_none(self) -> QwenLLMProvider | None:
        if self._llm:
            return self._llm
        if not settings.QWEN_API_KEY:
            logger.warning("daily mood report: QWEN_API_KEY not configured")
            return None
        try:
            return QwenLLMProvider()
        except Exception as exc:
            logger.warning("daily mood report: QwenLLMProvider init failed: {}", exc)
            return None

    def build_radar(
        self, moments: list[DailyMoment], category_filter: str | None = None
    ) -> tuple[dict[str, int], dict[str, float]]:
        filtered = self._filter_moments(moments, category_filter)
        counts = {k: 0 for k in MOOD_LABELS}
        for m in filtered:
            if m.emotion_tag in counts:
                counts[m.emotion_tag] += 1
        return counts, self._scores_from_counts(counts, weighted=False)

    def _filter_moments(
        self, moments: list[DailyMoment], category_filter: str | None
    ) -> list[DailyMoment]:
        if not category_filter:
            return moments
        return [m for m in moments if m.event_tags and m.event_tags[0] == category_filter]

    def _scores_from_counts(self, counts: dict[str, float], *, weighted: bool) -> dict[str, float]:
        total = sum(counts.values())
        if total == 0:
            return {k: 0.0 for k in MOOD_LABELS}
        return {k: round(counts.get(k, 0) / total, 3) for k in MOOD_LABELS}

    def build_category_breakdown(self, moments: list[DailyMoment]) -> dict[str, int]:
        breakdown: dict[str, int] = {}
        for m in moments:
            if not m.event_tags:
                continue
            key = CATEGORY_LABELS.get(m.event_tags[0], m.event_tags[0])
            breakdown[key] = breakdown.get(key, 0) + 1
        return breakdown

    def _merge_concern(self, rule_level: str, ai_level: str | None) -> str:
        return _merge_concern_levels(rule_level, ai_level)

    def _build_digest(
        self,
        moments: list[DailyMoment],
        mood_counts: dict[str, int],
        category_breakdown: dict[str, int],
        risk_flags: list[str],
        profile_mood: str | None,
        category_filter: str | None,
    ) -> dict[str, Any]:
        records = []
        private_notes: list[str] = []
        for m in moments[:16]:
            tags = [CATEGORY_LABELS.get(t, t) for t in m.event_tags]
            detail = [t for t in m.event_tags[1:] if t != "自定义"]
            story_text = get_story_content(m)
            records.append(
                {
                    "categories": tags,
                    "keywords": detail,
                    "emotion": MOOD_LABELS.get(m.emotion_tag, m.emotion_tag),
                    "has_note": bool(story_text),
                }
            )
            if story_text and len(private_notes) < 6:
                private_notes.append(story_text[:80])
        return {
            "filter_view": CATEGORY_LABELS.get(category_filter or "", "当前筛选：全部"),
            "profile_mood": MOOD_LABELS.get(profile_mood or "", "未设置"),
            "mood_counts": {MOOD_LABELS[k]: v for k, v in mood_counts.items()},
            "category_breakdown": category_breakdown,
            "record_count": len(moments),
            "records": records,
            "private_notes": private_notes,
        }

    async def generate_report(
        self,
        *,
        moments: list[DailyMoment],
        category_filter: str | None,
        profile_mood: str | None,
    ) -> dict[str, Any]:
        all_moments = moments
        mood_counts, radar_scores = self.build_radar(all_moments, category_filter)
        category_breakdown = self.build_category_breakdown(all_moments)
        concern = self._concern_from_moods(mood_counts, len(all_moments))

        full_counts, _ = self.build_radar(all_moments, None)
        digest = self._build_digest(
            all_moments,
            full_counts,
            category_breakdown,
            [],
            profile_mood,
            category_filter,
        )

        ai, analysis_source = await self._ai_insight(digest)
        if not ai:
            ai = self._rich_fallback(
                all_moments, full_counts, category_breakdown, concern, profile_mood
            )
            ai["ai_generated"] = False
            ai["analysis_source"] = analysis_source
        else:
            ai["ai_generated"] = True
            ai["analysis_source"] = "ai"

        concern = self._merge_concern(concern, ai.get("concern_level"))

        return {
            "report_date": date.today().isoformat(),
            "category_filter": category_filter,
            "mood_counts": mood_counts,
            "radar_scores": radar_scores,
            "category_breakdown": category_breakdown,
            "moment_count": len(self._filter_moments(all_moments, category_filter)),
            "concern_level": concern,
            "risk_flags": [],
            "attention_highlights": [],
            "insight_summary": _brief(ai.get("insight") or ""),
            "warm_suggestion": _brief(ai.get("warm_suggestion", "")),
            "ai_generated": ai.get("ai_generated", False),
            "analysis_source": ai.get("analysis_source", "unknown"),
            "uploaded_at": datetime.now(timezone.utc).isoformat(),
            "growth_insight": {},
        }

    def _concern_from_moods(self, mood_counts: dict[str, int], total: int) -> str:
        if total <= 0:
            return "normal"
        negative = mood_counts.get("sad", 0) + mood_counts.get("angry", 0)
        if negative >= 3:
            return "watch"
        return "normal"

    async def _ai_insight(self, digest: dict[str, Any]) -> tuple[dict[str, Any] | None, str]:
        llm = self._llm_or_none()
        if not llm:
            return None, "rule_no_key"
        try:
            raw = await asyncio.wait_for(
                llm.generate(
                    REPORT_PROMPT + json.dumps(digest, ensure_ascii=False),
                    model=settings.QWEN_FAST_MODEL,
                    max_tokens=256,
                    temperature=0.4,
                ),
                timeout=AI_CALL_TIMEOUT_SEC,
            )
            parsed = self._parse_json(raw)
            if not parsed:
                logger.warning("daily mood report AI: JSON parse failed, raw_len={}", len(raw))
                return None, "rule_parse_fail"
            insight = _brief(str(parsed.get("insight") or ""))
            warm = _brief(str(parsed.get("warm_suggestion") or ""))
            if not insight or not warm:
                logger.warning("daily mood report AI: missing required fields")
                return None, "rule_parse_fail"
            return {
                "insight": insight,
                "warm_suggestion": warm,
                "concern_level": parsed.get("concern_level"),
            }, f"ai:{settings.QWEN_FAST_MODEL}"
        except (asyncio.TimeoutError, TimeoutError):
            logger.warning(
                "daily mood report AI timed out after {}s, using rule fallback",
                AI_CALL_TIMEOUT_SEC,
            )
            return None, "rule_timeout"
        except Exception as exc:
            logger.warning("daily mood report AI failed: {}", exc)
            return None, "rule_error"

    def _rich_fallback(
        self,
        moments: list[DailyMoment],
        mood_counts: dict[str, int],
        category_breakdown: dict[str, int],
        concern_level: str,
        profile_mood: str | None,
    ) -> dict[str, Any]:
        total = len(moments)
        if total == 0:
            mood_label = MOOD_LABELS.get(profile_mood or "calm", "平静")
            return {
                "insight": _brief(f"今天还没写下瞬间呢，整体挺{mood_label}"),
                "warm_suggestion": _brief("随手记一件小事，我会懂你的节奏～"),
                "concern_level": concern_level,
            }

        top_cats = sorted(category_breakdown.items(), key=lambda x: -x[1])
        main_cat = top_cats[0][0] if top_cats else "多面向"
        top_mood = max(mood_counts, key=mood_counts.get) if total else "calm"
        top_label = MOOD_LABELS.get(top_mood, "平静")
        negative = mood_counts.get("sad", 0) + mood_counts.get("angry", 0)

        if negative >= 2:
            insight = _brief(f"今天{main_cat}这边记了几笔，心里有点累呢")
            warm = _brief("不必逞强，慢慢来也很好～")
        elif negative >= 1:
            insight = _brief(f"今天{main_cat}为主，情绪起起伏伏的")
            warm = _brief("给自己一点空隙，会轻松些")
        else:
            insight = _brief(f"今天{main_cat}为主，整体挺{top_label}的")
            warm = _brief("保持现在的节奏就很棒～")

        return {
            "insight": insight,
            "warm_suggestion": warm,
            "concern_level": concern_level,
        }

    def _parse_json(self, raw: str) -> dict[str, Any] | None:
        text = raw.strip()
        if text.startswith("```"):
            text = re.sub(r"^```(?:json)?\s*", "", text)
            text = re.sub(r"\s*```$", "", text)
        match = re.search(r"\{[\s\S]*\}", text)
        if not match:
            return None
        try:
            return json.loads(match.group())
        except json.JSONDecodeError:
            return None
