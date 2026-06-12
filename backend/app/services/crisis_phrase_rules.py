"""口语化危机短语规则：补充关键词词典未覆盖的求救、威胁与危险行为暗示。"""

from __future__ import annotations

import re
from dataclasses import dataclass


@dataclass(frozen=True)
class CrisisPhraseMatch:
    concern_level: str
    label: str
    is_critical: bool


# (concern_level, pattern, label, is_critical)
CRISIS_PHRASE_RULES: list[tuple[str, re.Pattern[str], str, bool]] = [
    # 一、心理危机 / 轻生自伤（最高优先级）
    (
        "urgent",
        re.compile(
            r"活着.{0,8}没意思|没什么意思|太累了|太累.{0,8}不想.{0,4}坚持|不想再坚持"
            r"|没人烦你们|消失了.{0,10}更好|我消失|不在乎疼|再见了"
        ),
        "检测到可能的轻生/自伤求救信号",
        True,
    ),
    # 二、暴力威胁 / 冲突
    (
        "urgent",
        re.compile(
            r"迟早.{0,6}教训|不放过你|敢惹我|鱼死网破|放学后.{0,6}等着|你等着"
            r"|对你动手|信不信我"
        ),
        "检测到暴力威胁或报复冲突信号",
        True,
    ),
    # 三、极端赌气 / 冲动（需情绪疏导，进成长关注）
    (
        "watch",
        re.compile(r"不配管我|偏要做|谁也拦不住|学我不上了|不想上学|这个学.{0,4}不上"),
        "检测到极端赌气或冲动表达",
        False,
    ),
    # 四、危险行为暗示（玩火、攀爬、危险游戏等）
    (
        "urgent",
        re.compile(r"摔下去也没事|高处.{0,6}没事|不怕出事|玩起来很刺激|玩.{0,4}刺激"),
        "检测到危险行为暗示信号",
        True,
    ),
]

CRITICAL_CRISIS_PATTERNS: list[re.Pattern[str]] = [
    pattern for _, pattern, _, is_critical in CRISIS_PHRASE_RULES if is_critical
]


def detect_crisis_phrases(text: str | None) -> list[CrisisPhraseMatch]:
    normalized = (text or "").strip()
    if not normalized:
        return []

    matches: list[CrisisPhraseMatch] = []
    seen_labels: set[str] = set()
    for concern, pattern, label, is_critical in CRISIS_PHRASE_RULES:
        if pattern.search(normalized) and label not in seen_labels:
            seen_labels.add(label)
            matches.append(
                CrisisPhraseMatch(
                    concern_level=concern,
                    label=label,
                    is_critical=is_critical,
                )
            )
    return matches


def note_has_critical_crisis(text: str | None) -> bool:
    normalized = (text or "").strip()
    if not normalized:
        return False
    return any(pattern.search(normalized) for pattern in CRITICAL_CRISIS_PATTERNS)
