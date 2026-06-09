"""成长观察洞察：规则引擎 + 报告聚合（教师端中性表达）。"""

from __future__ import annotations

import re
from typing import Any

from app.models.daily_mood_report import DailyMoodReport
from app.models.profile import DailyMoment
from app.services.danger_keyword_rules import detect_danger_keywords

MOOD_LABELS = {
    "happy": "超开心",
    "calm": "开心",
    "thinking": "平静",
    "sad": "低落",
    "angry": "生气",
}

ATTENTION_TAG_LABELS: dict[str, str] = {
    "low_mood": "情绪低落",
    "study_pressure": "学习压力",
    "family_pressure": "家庭压力",
    "social_isolation": "社交孤立",
    "interest_change": "兴趣变化",
    "goal_confusion": "目标迷茫",
    "sleep_issue": "睡眠异常",
    "self_negation": "自我否定",
}

DIRECTION_LABELS: dict[str, str] = {
    "emotion": "情绪状态",
    "family": "家庭关系",
    "study": "学习压力",
    "social": "人际关系",
    "interest": "兴趣变化",
}

FOCUS_RULES: list[tuple[re.Pattern[str], str, str]] = [
    (re.compile(r"吵架|父母|家里|家庭"), "family_pressure", "family"),
    (re.compile(r"考砸|考试|作业|学不会|学习"), "study_pressure", "study"),
    (re.compile(r"欺负|排挤|孤立|同学|朋友"), "social_isolation", "social"),
    (re.compile(r"睡不着|失眠|睡眠"), "sleep_issue", "emotion"),
    (re.compile(r"没意思|迷茫|不知道"), "goal_confusion", "interest"),
    (re.compile(r"不行|没用|自卑"), "self_negation", "emotion"),
]

CRITICAL_RULES: list[re.Pattern[str]] = [
    re.compile(r"自杀|自残|轻生|不想活|结束生命|跳楼|割腕"),
    re.compile(r"想死|活不下去|活着没意思|撑不下去"),
]

# 仅观察、不需进入成长时间轴的低优先级标签
LOW_PRIORITY_FOCUS_TAGS = frozenset({"interest_change", "goal_confusion"})

DEFAULT_SUMMARY = "AI观察到近期成长状态出现明显变化"


class GrowthInsightService:
    def dismissed_ids(self, report: DailyMoodReport | None) -> set[str]:
        if not report:
            return set()
        return {str(x) for x in (report.dismissed_risk_moment_ids or [])}

    def moment_note_is_critical(self, moment: DailyMoment, dismissed: set[str] | None = None) -> bool:
        dismissed = dismissed or set()
        if str(moment.id) in dismissed:
            return False
        note = (moment.note or "").strip()
        if not note:
            return False
        if any(match.risk_level == "critical" for match in detect_danger_keywords(note)):
            return True
        return any(p.search(note) for p in CRITICAL_RULES)

    def filter_focus_tags(self, tags: list[str], *, need_attention: bool) -> list[str]:
        if need_attention:
            return [t for t in tags if t not in LOW_PRIORITY_FOCUS_TAGS]
        return []

    def should_show_in_timeline(self, insight: dict[str, Any]) -> bool:
        if insight.get("risk_level") == "critical":
            return True
        if not insight.get("need_attention"):
            return False
        tags = set(insight.get("focus_tags") or [])
        if tags and tags <= LOW_PRIORITY_FOCUS_TAGS:
            return False
        return True

    def resolve_for_report(
        self,
        report: DailyMoodReport,
        moments: list[DailyMoment] | None = None,
    ) -> dict[str, Any]:
        rule = self.build_from_report(report, moments)
        stored = self.from_stored(report)
        if stored:
            merged = self.merge_insights(rule, stored)
            merged["risk_level"] = rule["risk_level"]
            merged["risk_reminder"] = rule["risk_reminder"]
            merged["status"] = rule["status"]
            merged["need_attention"] = rule["need_attention"]
            merged["focus_tags"] = rule["focus_tags"]
            merged["attention_tags"] = rule["attention_tags"]
            return merged
        return rule

    def build_from_report(
        self,
        report: DailyMoodReport,
        moments: list[DailyMoment] | None = None,
    ) -> dict[str, Any]:
        moments = moments or []
        return self._build(
            concern_level=report.concern_level,
            mood_counts=report.mood_counts or {},
            category_breakdown=report.category_breakdown or {},
            moment_count=report.moment_count,
            moments=moments,
            risk_flags=report.risk_flags or [],
            dismissed_ids=self.dismissed_ids(report),
        )

    def build_from_moments(
        self,
        moments: list[DailyMoment],
        concern_level: str = "normal",
        dismissed_ids: set[str] | None = None,
    ) -> dict[str, Any]:
        mood_counts: dict[str, int] = {}
        for m in moments:
            mood_counts[m.emotion_tag] = mood_counts.get(m.emotion_tag, 0) + 1
        category: dict[str, int] = {}
        for m in moments:
            if m.event_tags:
                key = m.event_tags[0]
                category[key] = category.get(key, 0) + 1
        return self._build(
            concern_level=concern_level,
            mood_counts=mood_counts,
            category_breakdown=category,
            moment_count=len(moments),
            moments=moments,
            risk_flags=[],
            dismissed_ids=dismissed_ids,
        )

    def _build(
        self,
        *,
        concern_level: str,
        mood_counts: dict[str, int],
        category_breakdown: dict[str, int],
        moment_count: int,
        moments: list[DailyMoment],
        risk_flags: list[str],
        dismissed_ids: set[str] | None = None,
    ) -> dict[str, Any]:
        dismissed_ids = dismissed_ids or set()
        focus_tags: list[str] = []
        focus_directions: list[str] = []
        for m in moments:
            note = (m.note or "").strip()
            if not note or str(m.id) in dismissed_ids:
                continue
            for pattern, tag, direction in FOCUS_RULES:
                if pattern.search(note) and tag not in focus_tags:
                    focus_tags.append(tag)
                if pattern.search(note) and direction not in focus_directions:
                    focus_directions.append(direction)

        sad_n = mood_counts.get("sad", 0) + mood_counts.get("angry", 0)
        if sad_n >= 2 and "low_mood" not in focus_tags:
            focus_tags.append("low_mood")
        if sad_n >= 2 and "emotion" not in focus_directions:
            focus_directions.append("emotion")

        for cat in category_breakdown:
            if cat in ("家庭",) and "family" not in focus_directions:
                focus_directions.append("family")
            if cat in ("学习", "学业") and "study" not in focus_directions:
                focus_directions.append("study")
            if cat in ("朋友",) and "social" not in focus_directions:
                focus_directions.append("social")

        risk_level = "none"
        risk_reminder = None
        for m in moments:
            if str(m.id) in dismissed_ids:
                continue
            danger_matches = detect_danger_keywords(m.note)
            critical_match = next(
                (match for match in danger_matches if match.risk_level == "critical"),
                None,
            )
            elevated_match = next(
                (match for match in danger_matches if match.risk_level == "elevated"),
                None,
            )
            if critical_match:
                risk_level = "critical"
                risk_reminder = f"检测到{critical_match.category}表达，建议立即关注"
                break
            if elevated_match and risk_level == "none":
                risk_level = "elevated"
                risk_reminder = f"检测到{elevated_match.category}表达，建议尽快核实"
            if self.moment_note_is_critical(m, dismissed_ids):
                risk_level = "critical"
                risk_reminder = "检测到疑似自伤表达，建议联系心理教师"
                break
        if risk_level != "critical" and concern_level in ("watch", "urgent"):
            risk_level = "elevated"

        if concern_level == "urgent" or risk_level == "critical":
            growth_status = "priority"
        elif concern_level == "watch" or sad_n >= 2 or focus_tags:
            growth_status = "ongoing"
        else:
            growth_status = "observing"

        trend = self._calc_trend(mood_counts, moment_count)
        need_attention = growth_status in ("ongoing", "priority")
        focus_tags = self.filter_focus_tags(focus_tags, need_attention=need_attention)
        summary = self._build_summary(focus_tags, focus_directions, mood_counts, moment_count)

        return {
            "status": growth_status,
            "focus_tags": focus_tags[:6],
            "focus_directions": [DIRECTION_LABELS.get(d, d) for d in focus_directions[:5]],
            "trend": trend,
            "summary": summary,
            "need_attention": need_attention,
            "risk_level": risk_level,
            "risk_reminder": risk_reminder,
            "attention_tags": [
                {"code": t, "label": ATTENTION_TAG_LABELS.get(t, t)} for t in focus_tags[:8]
            ],
        }

    def _calc_trend(self, mood_counts: dict[str, int], moment_count: int) -> str:
        if moment_count <= 0:
            return "stable"
        negative = mood_counts.get("sad", 0) + mood_counts.get("angry", 0)
        positive = mood_counts.get("happy", 0) + mood_counts.get("calm", 0)
        if negative > positive:
            return "down"
        if positive > negative * 2:
            return "up"
        return "stable"

    def _build_summary(
        self,
        focus_tags: list[str],
        focus_directions: list[str],
        mood_counts: dict[str, int],
        moment_count: int,
    ) -> str:
        if moment_count <= 0:
            return "近期暂无成长记录，持续观察中"
        parts = [DEFAULT_SUMMARY]
        if focus_directions:
            labels = [DIRECTION_LABELS.get(d, d) if d in DIRECTION_LABELS else d for d in focus_directions[:2]]
            parts.append(f"关注方向涉及{'、'.join(labels)}")
        elif focus_tags:
            labels = [ATTENTION_TAG_LABELS.get(t, t) for t in focus_tags[:2]]
            parts.append(f"主要围绕{'、'.join(labels)}")
        if mood_counts:
            top = max(mood_counts, key=mood_counts.get)
            parts.append(f"情绪以{MOOD_LABELS.get(top, top)}为主")
        text = "，".join(parts)
        return text[:120]

    def build_archive_summary(self, reports: list[DailyMoodReport], moments: list[DailyMoment]) -> str:
        if not reports and not moments:
            return "近期暂无足够记录生成成长总结，建议鼓励学生持续记录。"
        all_tags: list[str] = []
        for r in reports:
            ins = self.build_from_report(r)
            all_tags.extend(ins.get("focus_tags") or [])
        tag_counts: dict[str, int] = {}
        for t in all_tags:
            tag_counts[t] = tag_counts.get(t, 0) + 1
        lines = [f"近{max(len(reports), 1)}天记录中"]
        if tag_counts:
            top = sorted(tag_counts.items(), key=lambda x: -x[1])[:2]
            tag_text = "、".join(ATTENTION_TAG_LABELS.get(k, k) for k, _ in top)
            lines.append(f"学生多次提及{tag_text}")
        mood_line = []
        sad_total = sum((r.mood_counts or {}).get("sad", 0) for r in reports)
        if sad_total >= 2:
            mood_line.append("情绪以低落为主")
        if mood_line:
            lines.append("，".join(mood_line))
        lines.append("建议近期进行一次温暖沟通。")
        return "，".join(lines)

    def from_stored(self, report: DailyMoodReport) -> dict[str, Any] | None:
        raw = report.growth_insight if report.growth_insight else None
        if not raw or not raw.get("status"):
            return None
        return raw

    def merge_insights(self, rule: dict[str, Any], ai: dict[str, Any] | None) -> dict[str, Any]:
        if not ai:
            return rule
        merged = dict(rule)
        if ai.get("summary"):
            merged["summary"] = str(ai["summary"])[:120]
        if ai.get("focus_tags"):
            merged["focus_tags"] = list(dict.fromkeys((rule.get("focus_tags") or []) + ai["focus_tags"]))[:6]
        if ai.get("focus_directions"):
            merged["focus_directions"] = list(
                dict.fromkeys((rule.get("focus_directions") or []) + ai["focus_directions"])
            )[:5]
        if ai.get("trend") in ("up", "stable", "down"):
            merged["trend"] = ai["trend"]
        if ai.get("status") in ("observing", "ongoing", "priority"):
            merged["status"] = ai["status"]
        merged["need_attention"] = merged["status"] in ("ongoing", "priority")
        if rule.get("risk_level") == "critical":
            merged["risk_level"] = "critical"
            merged["risk_reminder"] = rule.get("risk_reminder")
        elif ai.get("risk_level") == "critical":
            merged["risk_level"] = "critical"
            merged["risk_reminder"] = ai.get("risk_reminder") or rule.get("risk_reminder")
        merged["attention_tags"] = [
            {"code": t, "label": ATTENTION_TAG_LABELS.get(t, t)} for t in merged.get("focus_tags", [])
        ]
        return merged


GROWTH_AI_PROMPT = """你是学生成长观察助手。根据结构化摘要，输出教师端「成长观察」JSON（中性、温暖、不说教）。
禁止：问题学生、高危监控、敏感词列表、诊断术语。
risk_reminder 仅 risk_level 为 critical 时填写，建议联系心理教师。
只输出 JSON：
{
  "status": "observing|ongoing|priority",
  "focus_tags": ["family_pressure","study_pressure"],
  "focus_directions": ["家庭关系","学习压力"],
  "trend": "up|stable|down",
  "summary": "≤60字成长观察句",
  "need_attention": true,
  "risk_level": "none|elevated|critical",
  "risk_reminder": null
}
摘要：
"""
