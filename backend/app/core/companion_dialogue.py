"""小人对话台词：昵称占位符，展示时按当前昵称替换。"""

from __future__ import annotations

NICKNAME_PLACEHOLDER = "{nickname}"


def normalize_dialogue_template(line: str, *, legacy_nickname: str | None = None) -> str:
    """将台词规范为模板：已有占位符则保留，否则把旧昵称替换为占位符。"""
    text = (line or "").strip()
    if not text:
        return text
    if NICKNAME_PLACEHOLDER in text:
        return text
    legacy = (legacy_nickname or "").strip()
    if legacy and legacy in text:
        return text.replace(legacy, NICKNAME_PLACEHOLDER)
    return text


def normalize_dialogue_templates(
    lines: list[str], *, legacy_nickname: str | None = None
) -> list[str]:
    return [normalize_dialogue_template(line, legacy_nickname=legacy_nickname) for line in lines if line]


def apply_nickname_to_template(line: str, nickname: str | None) -> str:
    """展示时将占位符替换为当前昵称（服务端预览/测试用）。"""
    text = (line or "").strip()
    if NICKNAME_PLACEHOLDER not in text:
        return text
    name = (nickname or "").strip()
    if name:
        return text.replace(NICKNAME_PLACEHOLDER, name)
    result = text.replace(f"对我们{NICKNAME_PLACEHOLDER}", "对你")
    result = result.replace(f"{NICKNAME_PLACEHOLDER}，", "")
    result = result.replace(f"{NICKNAME_PLACEHOLDER},", "")
    return result.replace(NICKNAME_PLACEHOLDER, "你")
