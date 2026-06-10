"""跨时段成长观察分析：规则定级 + 趋势统计 + 可选 AI 润色（不单独升级风险等级）。"""

from __future__ import annotations

import asyncio
import json
import re
from datetime import date, timedelta
from typing import Any

from loguru import logger

from app.core.config import settings
from app.models.daily_mood_report import DailyMoodReport
from app.models.profile import DailyMoment
from app.rag.qwen_provider import QwenLLMProvider
from app.services.growth_insight_service import (
    ATTENTION_TAG_LABELS,
    FOCUS_RULES,
    GrowthInsightService,
)

RISK_TIER_ORDER = {"none": 0, "light": 1, "moderate": 2, "high": 3, "urgent": 4}

RISK_TIER_LABELS: dict[str, str] = {
    "none": "无风险",
    "light": "轻度关注",
    "moderate": "中度关注",
    "high": "高度关注",
    "urgent": "紧急关注",
}

STRESS_SOURCE_LABELS: dict[str, str] = {
    "study_pressure": "学业压力",
    "family_pressure": "家庭问题",
    "social_isolation": "人际关系问题",
    "sleep_issue": "生活状态问题",
    "self_negation": "自我认同问题",
    "goal_confusion": "情绪困扰",
    "low_mood": "情绪困扰",
    "interest_change": "生活状态问题",
}

EMOTION_TREND_DIRECTIONS = ("stable", "worsening", "significantly_worsening")

EMOTION_TREND_LABELS: dict[str, str] = {
    "stable": "稳定",
    "worsening": "逐渐变差",
    "significantly_worsening": "明显恶化",
}

GUIDANCE_URGENCY_LABELS: dict[str, str] = {
    "observe": "建议观察",
    "light_talk": "建议简单沟通",
    "focused_follow": "建议重点跟进",
    "immediate": "建议立即联系心理教师",
}

GUIDANCE_ACTION_LABELS: dict[str, str] = {
    "observe": "持续观察记录变化",
    "light_talk": "找合适时机温暖沟通",
    "focused_follow": "近期重点跟进并记录",
    "immediate": "尽快联系心理教师或上报",
}

DISCLAIMER = "本报告为基于文本的结构化观察提示，非医学或心理诊断结论。"

OBSERVATION_AI_PROMPT = """你是学生成长观察分析助手。根据已判定的结构化信号，用温暖中性语言补充说明。
禁止：医学诊断、恐慌性表述、引用学生原文、单独提高风险等级。
只输出 JSON：
{
  "risk_summary_extra": ["补充风险点，每条≤40字，可为空数组"],
  "teacher_rationale": "≤80字，说明为何建议该关注方式",
  "student_weekly_hint": "≤50字，给学生看的本周轻提示，柔和不说教"
}
信号摘要：
"""

AI_CALL_TIMEOUT_SEC = 8.0


class GrowthObservationAnalysisService:
    def __init__(
        self,
        insight_svc: GrowthInsightService | None = None,
        llm: QwenLLMProvider | None = None,
    ):
        self.insight_svc = insight_svc or GrowthInsightService()
        self._llm = llm

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

        stress_sources = self._collect_stress_sources(window_reports, window_moments)
        emotion_trend = self._calc_period_trend(window_reports, window_moments, days)
        risk_tier = self._calc_risk_tier(window_reports, window_moments, emotion_trend)
        risk_summary = self._build_risk_summary(
            window_reports, window_moments, risk_tier, emotion_trend
        )
        teacher_guidance = self._build_teacher_guidance(
            risk_tier, emotion_trend, stress_sources, window_reports
        )
        student_weekly = self._build_student_weekly_hint(stress_sources, emotion_trend, window_moments)

        return {
            "risk_tier": risk_tier,
            "risk_tier_label": RISK_TIER_LABELS.get(risk_tier, "无风险"),
            "risk_summary": risk_summary[:6],
            "stress_sources": stress_sources[:8],
            "emotion_trend": emotion_trend,
            "teacher_guidance": teacher_guidance,
            "student_weekly_hint": student_weekly,
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
        if skip_ai or base["risk_tier"] == "urgent":
            return base
        ai_extra = await self._ai_enrich(base)
        if not ai_extra:
            return base
        merged = dict(base)
        extra_summary = ai_extra.get("risk_summary_extra") or []
        if extra_summary:
            merged["risk_summary"] = list(
                dict.fromkeys(list(merged["risk_summary"]) + [str(x)[:40] for x in extra_summary])
            )[:6]
        rationale = ai_extra.get("teacher_rationale")
        if rationale:
            merged["teacher_guidance"] = dict(merged["teacher_guidance"])
            merged["teacher_guidance"]["rationale"] = str(rationale)[:80]
        hint = ai_extra.get("student_weekly_hint")
        if hint:
            merged["student_weekly_hint"] = str(hint)[:50]
        return merged

    def _collect_stress_sources(
        self, reports: list[DailyMoodReport], moments: list[DailyMoment]
    ) -> list[dict[str, str]]:
        tag_days: dict[str, set[str]] = {}
        tag_counts: dict[str, int] = {}

        for report in reports:
            dismissed = self.insight_svc.dismissed_ids(report)
            day_moments = [m for m in moments if m.moment_date == report.report_date]
            ins = self.insight_svc.resolve_for_report(report, day_moments)
            for tag in ins.get("focus_tags") or []:
                tag_counts[tag] = tag_counts.get(tag, 0) + 1
                tag_days.setdefault(tag, set()).add(report.report_date.isoformat())

        for m in moments:
            note = (m.note or "").strip()
            if not note:
                continue
            report = next((r for r in reports if r.report_date == m.moment_date), None)
            dismissed = self.insight_svc.dismissed_ids(report)
            if str(m.id) in dismissed:
                continue
            for pattern, tag, _direction in FOCUS_RULES:
                if pattern.search(note):
                    tag_counts[tag] = tag_counts.get(tag, 0) + 1
                    tag_days.setdefault(tag, set()).add(m.moment_date.isoformat())

        ranked = sorted(tag_counts.items(), key=lambda x: (-x[1], x[0]))
        sources: list[dict[str, str]] = []
        for code, count in ranked[:8]:
            day_n = len(tag_days.get(code, set()))
            evidence = f"近{day_n}天出现" if day_n > 1 else "近期记录中出现"
            sources.append(
                {
                    "code": code,
                    "label": STRESS_SOURCE_LABELS.get(code, ATTENTION_TAG_LABELS.get(code, code)),
                    "evidence": evidence,
                    "count": str(count),
                }
            )
        return sources

    def _calc_period_trend(
        self,
        reports: list[DailyMoodReport],
        moments: list[DailyMoment],
        days: int,
    ) -> dict[str, Any]:
        signals: list[str] = []
        if not reports and not moments:
            return {
                "direction": "stable",
                "label": EMOTION_TREND_LABELS["stable"],
                "signals": ["近期暂无足够记录"],
            }

        negative_report_days = sum(
            1 for r in reports if r.concern_level in ("watch", "urgent")
        )
        urgent_days = sum(1 for r in reports if r.concern_level == "urgent")

        scores: list[float] = []
        for r in sorted(reports, key=lambda x: x.report_date):
            total = sum((r.mood_counts or {}).values()) or 1
            neg = (r.mood_counts or {}).get("sad", 0) + (r.mood_counts or {}).get("angry", 0)
            scores.append(round(1.0 - neg / total, 2))

        slope = 0.0
        if len(scores) >= 2:
            slope = scores[-1] - scores[0]

        if negative_report_days >= 3 or urgent_days >= 1:
            signals.append(f"近{days}天有{negative_report_days}天出现需关注信号")
        elif negative_report_days >= 2:
            signals.append("连续多日出现负面情绪记录")

        if len(scores) >= 3 and slope <= -0.2:
            signals.append("情绪正向指数呈下降趋势")
        elif len(scores) >= 2 and scores[0] > 0.5 and scores[-1] < 0.4:
            signals.append("情绪由相对平稳转向偏低落")

        tag_repeat = self._repeated_focus_tags(reports, moments)
        if tag_repeat:
            signals.append(f"同类压力主题多次出现（{tag_repeat}）")

        direction = "stable"
        if urgent_days >= 1 or negative_report_days >= 3 or (len(scores) >= 3 and slope <= -0.25):
            direction = "significantly_worsening"
        elif negative_report_days >= 2 or slope < -0.1 or tag_repeat:
            direction = "worsening"

        if not signals:
            signals.append("情绪波动在正常范围内")

        return {
            "direction": direction,
            "label": EMOTION_TREND_LABELS[direction],
            "signals": signals[:5],
        }

    def _repeated_focus_tags(
        self, reports: list[DailyMoodReport], moments: list[DailyMoment]
    ) -> str | None:
        tag_days: dict[str, int] = {}
        for report in reports:
            day_moments = [m for m in moments if m.moment_date == report.report_date]
            ins = self.insight_svc.resolve_for_report(report, day_moments)
            for tag in ins.get("focus_tags") or []:
                tag_days[tag] = tag_days.get(tag, 0) + 1
        repeated = [k for k, v in tag_days.items() if v >= 2]
        if not repeated:
            return None
        label = STRESS_SOURCE_LABELS.get(repeated[0], ATTENTION_TAG_LABELS.get(repeated[0], repeated[0]))
        return label

    def _calc_risk_tier(
        self,
        reports: list[DailyMoodReport],
        moments: list[DailyMoment],
        emotion_trend: dict[str, Any],
    ) -> str:
        tier = "none"

        for m in moments:
            report = next((r for r in reports if r.report_date == m.moment_date), None)
            dismissed = self.insight_svc.dismissed_ids(report)
            if self.insight_svc.moment_note_is_critical(m, dismissed):
                return "urgent"

        for report in reports:
            dismissed = self.insight_svc.dismissed_ids(report)
            day_moments = [m for m in moments if m.moment_date == report.report_date]
            ins = self.insight_svc.resolve_for_report(report, day_moments)
            risk_level = ins.get("risk_level") or "none"
            if risk_level == "critical":
                return "urgent"
            if risk_level == "elevated":
                tier = self._max_tier(tier, "moderate")
            if report.concern_level == "urgent":
                tier = self._max_tier(tier, "high")
            elif report.concern_level == "watch":
                tier = self._max_tier(tier, "light")

        watch_days = sum(1 for r in reports if r.concern_level in ("watch", "urgent"))
        if watch_days >= 3:
            tier = self._max_tier(tier, "high")
        elif watch_days >= 2:
            tier = self._max_tier(tier, "moderate")

        if emotion_trend["direction"] == "significantly_worsening" and tier != "urgent":
            tier = self._max_tier(tier, "high")
        elif emotion_trend["direction"] == "worsening" and tier == "none":
            tier = "light"

        stress_count = len(self._collect_stress_sources(reports, moments))
        if stress_count >= 3 and tier in ("none", "light"):
            tier = "moderate"

        return tier

    def _build_risk_summary(
        self,
        reports: list[DailyMoodReport],
        moments: list[DailyMoment],
        risk_tier: str,
        emotion_trend: dict[str, Any],
    ) -> list[str]:
        if risk_tier == "none":
            return ["暂未发现需要特别关注的信号"]

        items: list[str] = []
        for report in reports:
            for flag in report.risk_flags or []:
                text = str(flag).strip()
                if text and text not in items:
                    items.append(text[:40])

        for signal in emotion_trend.get("signals") or []:
            if signal not in items and "正常范围" not in signal:
                items.append(str(signal)[:40])

        if not items:
            items.append(f"综合评估为{RISK_TIER_LABELS.get(risk_tier, '需关注')}")
        return items[:6]

    def _build_teacher_guidance(
        self,
        risk_tier: str,
        emotion_trend: dict[str, Any],
        stress_sources: list[dict[str, str]],
        reports: list[DailyMoodReport],
    ) -> dict[str, Any]:
        urgency = "observe"
        if risk_tier == "urgent":
            urgency = "immediate"
        elif risk_tier == "high":
            urgency = "focused_follow"
        elif risk_tier in ("moderate",) or emotion_trend["direction"] == "worsening":
            urgency = "light_talk"
        elif risk_tier == "light":
            urgency = "observe"

        watch_days = sum(1 for r in reports if r.concern_level in ("watch", "urgent"))
        is_short_term = watch_days <= 1 and emotion_trend["direction"] != "significantly_worsening"
        duration = "短期压力" if is_short_term else "需持续关注的状况"

        rationale_parts = [duration]
        if stress_sources:
            rationale_parts.append(f"主要压力方向涉及{stress_sources[0]['label']}")
        if emotion_trend["direction"] != "stable":
            rationale_parts.append(f"情绪趋势{emotion_trend['label']}")

        return {
            "need_attention": risk_tier != "none",
            "urgency": urgency,
            "urgency_label": GUIDANCE_URGENCY_LABELS[urgency],
            "suggested_actions": [GUIDANCE_ACTION_LABELS[urgency]],
            "duration_assessment": duration,
            "rationale": "，".join(rationale_parts)[:120],
        }

    def _build_student_weekly_hint(
        self,
        stress_sources: list[dict[str, str]],
        emotion_trend: dict[str, Any],
        moments: list[DailyMoment],
    ) -> str:
        if not moments:
            return "这周还没有太多记录，随手记一件小事吧～"
        if emotion_trend["direction"] == "significantly_worsening":
            return "最近好像有点累，记得照顾自己的感受～"
        if stress_sources:
            label = stress_sources[0]["label"]
            if "学业" in label:
                return "这周学习相关的事出现得比较多，适当休息也很重要～"
            if "人际" in label:
                return "最近人际方面的事可能让你有些在意，你并不孤单～"
            if "家庭" in label:
                return "家里的事有时会让人心里沉一点，慢慢来就好～"
        if emotion_trend["direction"] == "worsening":
            return "这周情绪有些起伏，给自己一点空隙吧～"
        return "这周整体节奏还不错，继续保持记录的习惯～"

    async def _ai_enrich(self, digest: dict[str, Any]) -> dict[str, Any] | None:
        llm = self._llm_or_none()
        if not llm:
            return None
        slim = {
            "risk_tier": digest.get("risk_tier_label"),
            "risk_summary": digest.get("risk_summary"),
            "stress_sources": [s.get("label") for s in digest.get("stress_sources") or []],
            "emotion_trend": digest.get("emotion_trend", {}).get("label"),
            "teacher_guidance": digest.get("teacher_guidance", {}).get("urgency_label"),
        }
        try:
            raw = await asyncio.wait_for(
                llm.generate(
                    OBSERVATION_AI_PROMPT + json.dumps(slim, ensure_ascii=False),
                    model=settings.QWEN_FAST_MODEL,
                    max_tokens=200,
                    temperature=0.35,
                ),
                timeout=AI_CALL_TIMEOUT_SEC,
            )
            return self._parse_json(raw)
        except (asyncio.TimeoutError, TimeoutError):
            logger.warning("growth observation AI timed out")
            return None
        except Exception as exc:
            logger.warning("growth observation AI failed: {}", exc)
            return None

    def _llm_or_none(self) -> QwenLLMProvider | None:
        if self._llm:
            return self._llm
        if not settings.QWEN_API_KEY:
            return None
        try:
            return QwenLLMProvider()
        except Exception:
            return None

    @staticmethod
    def _max_tier(current: str, candidate: str) -> str:
        if RISK_TIER_ORDER.get(candidate, 0) > RISK_TIER_ORDER.get(current, 0):
            return candidate
        return current

    @staticmethod
    def _parse_json(raw: str) -> dict[str, Any] | None:
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
