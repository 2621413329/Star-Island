"""AI 危险评估兜底：规则未覆盖的苗头由大模型补检，只升不降。"""

from __future__ import annotations

from typing import Any

CONCERN_ORDER = {"urgent": 3, "watch": 2, "normal": 1}
RISK_LEVEL_ORDER = {"critical": 2, "elevated": 1, "none": 0}

DANGER_CATEGORIES = frozenset(
    {
        "psych_crisis",
        "violence_threat",
        "danger_behavior",
        "defiance_impulse",
        "emotional_stress",
    }
)

CRITICAL_CATEGORIES = frozenset({"psych_crisis", "violence_threat", "danger_behavior"})

CATEGORY_LABELS: dict[str, str] = {
    "psych_crisis": "心理危机/轻生自伤",
    "violence_threat": "暴力威胁/冲突",
    "danger_behavior": "危险行为暗示",
    "defiance_impulse": "极端赌气/冲动",
    "emotional_stress": "情绪压力苗头",
}

DANGER_AI_PROMPT = """你是学生安全风险评估助手。任务：从摘要中识别一切可能的危险苗头，宁可误报也不漏报。

【四类危险（优先级从高到低）】
1 psych_crisis 心理危机/轻生自伤：绝望、不想活、自伤暗示、告别式表达、觉得没意义
2 violence_threat 暴力威胁/冲突：威胁打人、报复、围堵、动手、鱼死网破类表达
3 danger_behavior 危险行为暗示：高危玩耍、攀爬坠落、玩火违禁、不怕出事
4 defiance_impulse 极端赌气/冲动：对抗家长老师、辍学冲动、失控赌气
补充 emotional_stress 情绪压力苗头：霸凌、失眠、崩溃、害怕等未达上述四类时

【等级（就高不就低）】
concern_level: normal < watch < urgent
- 出现 1/2/3 类倾向 → urgent
- 仅 4 类或 emotional_stress → watch
risk_level: none < elevated < critical
- psych_crisis 或明确自伤/暴力/高危行为 → critical
- 其余检测到苗头 → elevated

【隐私】risk_flags 用中性标签≤30字，不得复述 private_notes 原文、人名、成绩细节。
可参考 risk_hints（规则已命中项），但若 private_notes 另有风险须独立标注。

【记录定位】records 与 private_notes 按下标一一对应（从 0 开始）；仅在 detected=true 时填写 flagged_records。

只输出 JSON：
{
  "detected": true,
  "concern_level": "normal|watch|urgent",
  "risk_level": "none|elevated|critical",
  "risk_category": "psych_crisis|violence_threat|danger_behavior|defiance_impulse|emotional_stress",
  "risk_flags": ["AI-中性风险标签，每条≤30字"],
  "risk_reminder": "仅 urgent/critical 时填写，建议行动，≤40字",
  "flagged_records": [{"index": 0, "category": "psych_crisis", "label": "≤30字中性标签"}]
}
未检测到任何苗头时：
{"detected": false, "concern_level": "normal", "risk_level": "none", "risk_category": null, "risk_flags": [], "risk_reminder": null, "flagged_records": []}

输入摘要：
"""


def merge_concern_levels(*levels: str | None) -> str:
    candidates = [lvl for lvl in levels if lvl in CONCERN_ORDER]
    if not candidates:
        return "normal"
    return max(candidates, key=lambda x: CONCERN_ORDER[x])


def merge_risk_levels(*levels: str | None) -> str:
    candidates = [lvl for lvl in levels if lvl in RISK_LEVEL_ORDER]
    if not candidates:
        return "none"
    return max(candidates, key=lambda x: RISK_LEVEL_ORDER[x])


def normalize_danger_ai(raw: dict[str, Any] | None) -> dict[str, Any] | None:
    if not raw:
        return None
    detected = bool(raw.get("detected"))
    concern = raw.get("concern_level") if raw.get("concern_level") in CONCERN_ORDER else "normal"
    risk_level = raw.get("risk_level") if raw.get("risk_level") in RISK_LEVEL_ORDER else "none"
    category = raw.get("risk_category")
    if category not in DANGER_CATEGORIES:
        category = None
    flags = [str(x).strip() for x in (raw.get("risk_flags") or []) if str(x).strip()]
    reminder = (raw.get("risk_reminder") or "").strip() or None
    flagged: list[dict[str, Any]] = []
    for item in raw.get("flagged_records") or []:
        if not isinstance(item, dict):
            continue
        idx = item.get("index")
        if not isinstance(idx, int) or idx < 0:
            continue
        cat = item.get("category")
        if cat not in DANGER_CATEGORIES:
            continue
        label = str(item.get("label") or "").strip()
        if not label:
            label = CATEGORY_LABELS.get(cat, "AI检测到关注信号")
        flagged.append({"index": idx, "category": cat, "label": label[:30]})
    if not detected and not flags and not flagged:
        return None
    if not detected and (flags or flagged):
        detected = True
    if detected and concern == "normal" and risk_level == "none" and (flags or flagged):
        concern = "watch"
        risk_level = "elevated"
    if flagged:
        top_cat = flagged[0]["category"]
        if top_cat in CRITICAL_CATEGORIES:
            concern = merge_concern_levels(concern, "urgent")
            risk_level = merge_risk_levels(risk_level, "critical")
        elif concern == "normal":
            concern = "watch"
    if category in CRITICAL_CATEGORIES:
        concern = merge_concern_levels(concern, "urgent")
        risk_level = merge_risk_levels(risk_level, "critical")
    elif category and concern == "normal":
        concern = "watch"
        risk_level = merge_risk_levels(risk_level, "elevated")
    return {
        "detected": detected,
        "concern_level": concern,
        "risk_level": risk_level,
        "risk_category": category,
        "risk_flags": flags[:6],
        "risk_reminder": reminder,
        "flagged_records": flagged[:8],
    }


def merge_risk_flags(rule_flags: list[str], danger_ai: dict[str, Any] | None) -> list[str]:
    merged = list(rule_flags)
    if not danger_ai:
        return merged[:6]
    for flag in danger_ai.get("risk_flags") or []:
        text = str(flag).strip()
        if text and text not in merged:
            merged.append(text)
    for item in danger_ai.get("flagged_records") or []:
        label = str(item.get("label") or "").strip()
        if label and label not in merged:
            merged.append(label)
    return merged[:6]


def resolve_ai_flagged_moment_ids(
    moments: list[Any], danger_ai: dict[str, Any] | None, *, limit: int = 16
) -> list[str]:
    if not danger_ai:
        return []
    scoped = moments[:limit]
    ids: list[str] = []
    for item in danger_ai.get("flagged_records") or []:
        idx = item.get("index")
        if not isinstance(idx, int) or idx >= len(scoped):
            continue
        moment_id = str(scoped[idx].id)
        if moment_id not in ids:
            ids.append(moment_id)
    return ids


def apply_danger_ai_to_growth_insight(
    insight: dict[str, Any], danger_ai: dict[str, Any] | None
) -> dict[str, Any]:
    if not danger_ai or not danger_ai.get("detected"):
        return insight
    result = dict(insight)
    result["risk_level"] = merge_risk_levels(result.get("risk_level"), danger_ai.get("risk_level"))
    if danger_ai.get("risk_reminder") and result["risk_level"] in ("elevated", "critical"):
        result["risk_reminder"] = str(danger_ai["risk_reminder"])[:256]
    concern = danger_ai.get("concern_level")
    if concern == "urgent" or result["risk_level"] == "critical":
        result["status"] = "priority"
        result["need_attention"] = True
    elif concern == "watch" and result.get("status") == "observing":
        result["status"] = "ongoing"
        result["need_attention"] = True
    category = danger_ai.get("risk_category")
    if category:
        result["ai_danger"] = {
            "risk_category": category,
            "category_label": CATEGORY_LABELS.get(category, category),
            "source": "ai_fallback",
        }
    return result
