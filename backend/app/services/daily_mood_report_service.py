from __future__ import annotations

import asyncio
import json
import re
from datetime import date, datetime, timezone
from typing import Any

from loguru import logger

from app.core.config import settings
from app.models.profile import DailyMoment
from app.rag.qwen_provider import QwenLLMProvider
from app.services.crisis_phrase_rules import detect_crisis_phrases
from app.services.danger_ai_assessment import (
    DANGER_AI_PROMPT,
    apply_danger_ai_to_growth_insight,
    merge_concern_levels,
    merge_risk_flags,
    normalize_danger_ai,
    resolve_ai_flagged_moment_ids,
)
from app.services.danger_keyword_rules import detect_danger_keywords
from app.services.growth_insight_service import GROWTH_AI_PROMPT, GrowthInsightService

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

# 教师端雷达：低落/生气权重更高，便于导师优先关注。
TEACHER_MOOD_WEIGHT = {
    "angry": 2.25,
    "sad": 2.0,
    "thinking": 1.25,
    "calm": 1.0,
    "happy": 0.85,
}

CONCERN_ORDER = {"urgent": 3, "watch": 2, "normal": 1}

BRIEF_MAX_LEN = 30
AI_CALL_TIMEOUT_SEC = 8.0


def _brief(text: str, limit: int = BRIEF_MAX_LEN) -> str:
    cleaned = re.sub(r"\s+", "", (text or "").strip())
    if len(cleaned) <= limit:
        return cleaned
    return cleaned[:limit]

RISK_RULES: list[tuple[str, re.Pattern[str], str]] = [
    (
        "urgent",
        re.compile(r"自杀|自残|轻生|不想活|不想活了|了结|结束生命|跳楼|割腕|一了百了"),
        "检测到可能的自伤/轻生风险信号",
    ),
    (
        "urgent",
        re.compile(r"想死|活不下去|活着没意思|没有希望|撑不下去"),
        "检测到放弃或绝望倾向信号",
    ),
    (
        "watch",
        re.compile(r"崩溃|受不了|绝望|抑郁|失眠|睡不着|一直哭|想哭"),
        "检测到情绪压力累积信号",
    ),
    (
        "watch",
        re.compile(r"被欺负|排挤|孤立|冷战|吵架|霸凌|辱骂"),
        "检测到人际关系紧张信号",
    ),
    (
        "watch",
        re.compile(r"考砸|没考好|被骂|挨打|恐惧|害怕"),
        "检测到学业或家庭压力信号",
    ),
]

REPORT_PROMPT = """你是学生成长的 AI 助手。基于「结构化摘要」生成两套互不影响的文案。

【隐私】private_notes 仅供理解；任何字段都不得引用、复述或暗示备注原文；不得出现人名、成绩、具体事件细节。

【学生端 student_insight / warm_suggestion】
- 语气柔和、陪伴、不说教；用「你」；可适度语气词（～、呢）但克制。
- 侧重感受与鼓励，避免诊断、命令、统计术语（如「权重」「占比」「记录N条」）。
- 每条≤30字（含标点），一句话。

【教师端 fuzzy_analysis / attention_highlights / risk_flags】
- 纯客观观察记录，像导师工作日志：只写可核验的统计与风险标签。
- 用「共N条」「主类」「主情绪」「低落/生气各N次」等表述；禁止安慰、鼓励、主观建议。
- fuzzy_analysis≤30字；attention_highlights 每条≤30字。

只输出 JSON：
{
  "student_insight": "学生端柔和洞察，≤30字",
  "warm_suggestion": "学生端柔和建议，≤30字",
  "fuzzy_analysis": "教师端客观结论，≤30字",
  "attention_highlights": ["教师端客观要点，每条≤30字"],
  "risk_flags": ["风险标签，每条≤30字"],
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

    def build_teacher_radar(self, moments: list[DailyMoment]) -> tuple[dict[str, int], dict[str, float]]:
        counts = {k: 0 for k in MOOD_LABELS}
        for m in moments:
            if m.emotion_tag in counts:
                counts[m.emotion_tag] += 1
        weighted = {k: round(v * TEACHER_MOOD_WEIGHT.get(k, 1.0), 2) for k, v in counts.items()}
        return counts, self._scores_from_counts(weighted, weighted=True)

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

    def detect_risk_signals(
        self, moments: list[DailyMoment], *, dismissed_ids: set[str] | None = None
    ) -> tuple[list[str], str]:
        dismissed_ids = dismissed_ids or set()
        flags: list[str] = []
        level = "normal"
        for m in moments:
            if str(m.id) in dismissed_ids:
                continue
            note = (m.note or "").strip()
            if not note:
                continue
            for match in detect_danger_keywords(note):
                label = _brief(match.label)
                if label not in flags:
                    flags.append(label)
                if CONCERN_ORDER[match.concern_level] > CONCERN_ORDER[level]:
                    level = match.concern_level
            for concern, pattern, label in RISK_RULES:
                if pattern.search(note) and label not in flags:
                    flags.append(label)
                    if CONCERN_ORDER[concern] > CONCERN_ORDER[level]:
                        level = concern
            for crisis in detect_crisis_phrases(note):
                if crisis.label not in flags:
                    flags.append(crisis.label)
                if CONCERN_ORDER[crisis.concern_level] > CONCERN_ORDER[level]:
                    level = crisis.concern_level
        sad_angry = sum(1 for m in moments if m.emotion_tag in ("sad", "angry"))
        if sad_angry >= 2 and level == "normal":
            flags.append("今日多次出现低落或生气情绪")
            level = "watch"
        if sad_angry >= 3 and level != "urgent":
            flags.append("负面情绪记录较为集中")
            level = "watch"
        return flags, level

    def has_danger_keyword_match(
        self, moments: list[DailyMoment], *, dismissed_ids: set[str] | None = None
    ) -> bool:
        """兼容旧调用：是否命中任意危险规则（含 watch 级危机短语）。"""
        return self.has_critical_danger_match(moments, dismissed_ids=dismissed_ids) or any(
            detect_crisis_phrases(m.note) for m in moments if str(m.id) not in (dismissed_ids or set())
        )

    def has_critical_danger_match(
        self, moments: list[DailyMoment], *, dismissed_ids: set[str] | None = None
    ) -> bool:
        """规则已明确命中高危时，跳过面向学生的文案 AI（隐私保护）。"""
        insight_svc = GrowthInsightService()
        dismissed_ids = dismissed_ids or set()
        return any(
            insight_svc.moment_note_is_critical(m, dismissed_ids) for m in moments
        )

    def _teacher_objective_analysis(
        self,
        mood_counts: dict[str, int],
        category_breakdown: dict[str, int],
        record_count: int,
    ) -> str:
        if record_count <= 0:
            return _brief("当日无成长记录上报")
        parts = [f"共{record_count}条"]
        if category_breakdown:
            top_cats = sorted(category_breakdown.items(), key=lambda x: -x[1])[:3]
            cat_part = "、".join(f"{name}{count}条" for name, count in top_cats)
            parts.append(f"分类{cat_part}")
        if mood_counts:
            top_mood = max(mood_counts, key=mood_counts.get)
            parts.append(f"主情绪{MOOD_LABELS.get(top_mood, top_mood)}")
            sad_n = mood_counts.get("sad", 0)
            angry_n = mood_counts.get("angry", 0)
            if sad_n or angry_n:
                parts.append(f"低落{sad_n}次生气{angry_n}次")
        return _brief("，".join(parts))

    def _teacher_objective_highlights(
        self,
        category_breakdown: dict[str, int],
        mood_counts: dict[str, int],
        record_count: int,
        risk_flags: list[str],
    ) -> list[str]:
        if record_count <= 0:
            return [_brief("待学生完成心情上报")]
        highlights: list[str] = []
        if category_breakdown:
            main = max(category_breakdown.items(), key=lambda x: x[1])
            highlights.append(_brief(f"主类{main[0]}{main[1]}条"))
        negative = mood_counts.get("sad", 0) + mood_counts.get("angry", 0)
        if negative >= 2:
            highlights.append(_brief(f"低落生气合计{negative}次"))
        elif negative == 1:
            highlights.append(_brief("出现1次负面情绪"))
        if risk_flags:
            highlights.append(_brief("规则命中关注信号"))
        return highlights[:5] or [_brief(f"共{record_count}条待阅")]

    def _merge_concern(self, rule_level: str, ai_level: str | None) -> str:
        return merge_concern_levels(rule_level, ai_level)

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
            records.append(
                {
                    "categories": tags,
                    "keywords": detail,
                    "emotion": MOOD_LABELS.get(m.emotion_tag, m.emotion_tag),
                    "has_note": bool(m.note and m.note.strip()),
                }
            )
            if m.note and m.note.strip() and len(private_notes) < 6:
                private_notes.append(m.note.strip()[:80])
        return {
            "filter_view": CATEGORY_LABELS.get(category_filter or "", "学生端当前筛选：全部"),
            "profile_mood": MOOD_LABELS.get(profile_mood or "", "未设置"),
            "mood_counts": {MOOD_LABELS[k]: v for k, v in mood_counts.items()},
            "category_breakdown": category_breakdown,
            "record_count": len(moments),
            "records": records,
            "risk_hints": risk_flags,
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
        _, teacher_radar = self.build_teacher_radar(all_moments)
        category_breakdown = self.build_category_breakdown(all_moments)
        risk_flags, rule_concern = self.detect_risk_signals(all_moments)

        full_counts, _ = self.build_teacher_radar(all_moments)
        digest = self._build_digest(
            all_moments,
            full_counts,
            category_breakdown,
            risk_flags,
            profile_mood,
            category_filter,
        )

        danger_ai = await self._ai_danger_assessment(digest)
        concern = rule_concern
        if danger_ai:
            concern = merge_concern_levels(concern, danger_ai.get("concern_level"))
            risk_flags = merge_risk_flags(risk_flags, danger_ai)

        critical_rule_hit = self.has_critical_danger_match(all_moments)
        if critical_rule_hit:
            ai = self._rich_fallback(
                all_moments, full_counts, category_breakdown, risk_flags, concern, profile_mood
            )
            ai["ai_generated"] = False
            ai["analysis_source"] = "rule_danger_keyword"
            analysis_source = "rule_danger_keyword"
        else:
            ai, analysis_source = await self._ai_insight(digest)
        if not ai:
            ai = self._rich_fallback(
                all_moments, full_counts, category_breakdown, risk_flags, concern, profile_mood
            )
            ai["ai_generated"] = False
            ai["analysis_source"] = analysis_source
        elif not critical_rule_hit:
            ai["ai_generated"] = True
            ai["analysis_source"] = "ai"

        concern = self._merge_concern(concern, ai.get("concern_level"))
        merged_flags = [
            _brief(x)
            for x in list(dict.fromkeys(risk_flags + (ai.get("risk_flags") or [])))[:6]
        ]
        if danger_ai:
            if critical_rule_hit:
                analysis_source = "rule_danger_keyword+ai_danger"
            elif ai.get("ai_generated"):
                analysis_source = "ai+ai_danger"
            else:
                analysis_source = f"{analysis_source}+ai_danger"
        teacher_obj = self._teacher_objective_analysis(
            full_counts, category_breakdown, len(all_moments)
        )
        fuzzy = _brief(str(ai.get("fuzzy_analysis") or "")) or teacher_obj
        highlights = [
            _brief(str(x)) for x in (ai.get("attention_highlights") or [])[:5]
        ]
        if not highlights:
            highlights = self._teacher_objective_highlights(
                category_breakdown, full_counts, len(all_moments), merged_flags
            )

        growth_insight = await self._build_growth_insight(
            moments=all_moments,
            concern_level=concern,
            mood_counts=full_counts,
            category_breakdown=category_breakdown,
            risk_flags=merged_flags,
            digest=digest,
            skip_ai=critical_rule_hit,
            danger_ai=danger_ai,
        )

        return {
            "report_date": date.today().isoformat(),
            "category_filter": category_filter,
            "mood_counts": mood_counts,
            "radar_scores": radar_scores,
            "teacher_radar_scores": teacher_radar,
            "category_breakdown": category_breakdown,
            "moment_count": len(self._filter_moments(all_moments, category_filter)),
            "concern_level": concern,
            "risk_flags": merged_flags,
            "attention_highlights": highlights,
            "fuzzy_analysis": fuzzy,
            "student_insight": _brief(ai.get("student_insight", "")),
            "warm_suggestion": _brief(ai.get("warm_suggestion", "")),
            "teacher_summary": fuzzy,
            "ai_generated": ai.get("ai_generated", False),
            "analysis_source": ai.get("analysis_source", "unknown"),
            "uploaded_at": datetime.now(timezone.utc).isoformat(),
            "growth_insight": growth_insight,
        }

    async def _build_growth_insight(
        self,
        *,
        moments: list[DailyMoment],
        concern_level: str,
        mood_counts: dict[str, int],
        category_breakdown: dict[str, int],
        risk_flags: list[str],
        digest: dict[str, Any],
        skip_ai: bool = False,
        danger_ai: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        svc = GrowthInsightService()
        rule = svc._build(
            concern_level=concern_level,
            mood_counts=mood_counts,
            category_breakdown=category_breakdown,
            moment_count=len(moments),
            moments=moments,
            risk_flags=risk_flags,
        )
        rule = apply_danger_ai_to_growth_insight(rule, danger_ai)
        ai_flagged_ids = resolve_ai_flagged_moment_ids(moments, danger_ai)
        if ai_flagged_ids:
            rule["ai_flagged_moment_ids"] = ai_flagged_ids
        if skip_ai:
            return rule
        ai_parsed = await self._ai_growth_insight(digest)
        merged = svc.merge_insights(rule, ai_parsed)
        if ai_flagged_ids:
            merged["ai_flagged_moment_ids"] = ai_flagged_ids
        return merged

    async def _ai_danger_assessment(self, digest: dict[str, Any]) -> dict[str, Any] | None:
        llm = self._llm_or_none()
        if not llm:
            return None
        try:
            raw = await asyncio.wait_for(
                llm.generate(
                    DANGER_AI_PROMPT + json.dumps(digest, ensure_ascii=False),
                    model=settings.QWEN_FAST_MODEL,
                    max_tokens=320,
                    temperature=0.2,
                ),
                timeout=AI_CALL_TIMEOUT_SEC,
            )
            parsed = self._parse_json(raw)
            return normalize_danger_ai(parsed)
        except (asyncio.TimeoutError, TimeoutError):
            logger.warning("danger AI assessment timed out")
            return None
        except Exception as exc:
            logger.warning("danger AI assessment failed: {}", exc)
            return None

    async def _ai_growth_insight(self, digest: dict[str, Any]) -> dict[str, Any] | None:
        llm = self._llm_or_none()
        if not llm:
            return None
        try:
            raw = await asyncio.wait_for(
                llm.generate(
                    GROWTH_AI_PROMPT + json.dumps(digest, ensure_ascii=False),
                    model=settings.QWEN_FAST_MODEL,
                    max_tokens=220,
                    temperature=0.35,
                ),
                timeout=AI_CALL_TIMEOUT_SEC,
            )
            parsed = self._parse_json(raw)
            if not parsed:
                return None
            return {
                "status": parsed.get("status"),
                "focus_tags": parsed.get("focus_tags"),
                "focus_directions": parsed.get("focus_directions"),
                "trend": parsed.get("trend"),
                "summary": parsed.get("summary"),
                "need_attention": parsed.get("need_attention"),
                "risk_level": parsed.get("risk_level"),
                "risk_reminder": parsed.get("risk_reminder"),
            }
        except (asyncio.TimeoutError, TimeoutError):
            logger.warning("growth insight AI timed out")
            return None
        except Exception as exc:
            logger.warning("growth insight AI failed: {}", exc)
            return None

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
            insight = _brief(str(parsed.get("student_insight") or ""))
            warm = _brief(str(parsed.get("warm_suggestion") or ""))
            fuzzy = _brief(str(parsed.get("fuzzy_analysis") or ""))
            if not insight or not warm:
                logger.warning("daily mood report AI: missing required fields")
                return None, "rule_parse_fail"
            return {
                "student_insight": insight,
                "warm_suggestion": warm,
                "fuzzy_analysis": fuzzy,
                "attention_highlights": [
                    _brief(str(x)) for x in (parsed.get("attention_highlights") or [])[:5]
                ],
                "risk_flags": [_brief(str(x)) for x in (parsed.get("risk_flags") or [])[:5]],
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
        risk_flags: list[str],
        concern_level: str,
        profile_mood: str | None,
    ) -> dict[str, Any]:
        total = len(moments)
        if total == 0:
            mood_label = MOOD_LABELS.get(profile_mood or "calm", "平静")
            return {
                "student_insight": _brief(f"今天还没写下瞬间呢，整体挺{mood_label}"),
                "warm_suggestion": _brief("随手记一件小事，我会懂你的节奏～"),
                "fuzzy_analysis": self._teacher_objective_analysis(mood_counts, category_breakdown, 0),
                "attention_highlights": self._teacher_objective_highlights(
                    category_breakdown, mood_counts, 0, risk_flags
                ),
                "risk_flags": [_brief(x) for x in risk_flags],
                "concern_level": concern_level,
            }

        top_cats = sorted(category_breakdown.items(), key=lambda x: -x[1])
        main_cat = top_cats[0][0] if top_cats else "多面向"
        top_mood = max(mood_counts, key=mood_counts.get) if total else "calm"
        top_label = MOOD_LABELS.get(top_mood, "平静")
        negative = mood_counts.get("sad", 0) + mood_counts.get("angry", 0)

        if negative >= 2:
            student_insight = _brief(f"今天{main_cat}这边记了几笔，心里有点累呢")
            warm = _brief("不必逞强，慢慢来也很好～")
        elif negative >= 1:
            student_insight = _brief(f"今天{main_cat}为主，情绪起起伏伏的")
            warm = _brief("给自己一点空隙，会轻松些")
        else:
            student_insight = _brief(f"今天{main_cat}为主，整体挺{top_label}的")
            warm = _brief("保持现在的节奏就很棒～")

        fuzzy = self._teacher_objective_analysis(mood_counts, category_breakdown, total)
        if negative >= 2:
            fuzzy = _brief(f"{fuzzy}，负面情绪偏多")

        highlights = self._teacher_objective_highlights(
            category_breakdown, mood_counts, total, risk_flags
        )

        return {
            "student_insight": student_insight,
            "warm_suggestion": warm,
            "fuzzy_analysis": fuzzy,
            "attention_highlights": highlights,
            "risk_flags": [_brief(x) for x in risk_flags],
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
