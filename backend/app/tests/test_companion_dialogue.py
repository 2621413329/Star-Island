from app.core.companion_dialogue import (
    NICKNAME_PLACEHOLDER,
    apply_nickname_to_template,
    normalize_dialogue_template,
    normalize_dialogue_templates,
)
from app.services.companion_action_ai_service import CompanionActionAIService


def test_story_summary_lines_use_nickname_placeholder():
    svc = CompanionActionAIService()
    lines = svc._story_summary_lines_from_context(
        ["生活", "日常"],
        "calm",
        "今天加班到很晚",
        "加班夜",
    )
    assert all(NICKNAME_PLACEHOLDER in line for line in lines[:2])
    assert len(lines) == 3


def test_story_summary_lines_apply_nickname():
    svc = CompanionActionAIService()
    lines = svc._story_summary_lines_from_context(
        ["生活"],
        "calm",
        None,
        "平静一刻",
    )
    rendered = [apply_nickname_to_template(line, "小明") for line in lines]
    assert any("小明" in line for line in rendered)
    assert NICKNAME_PLACEHOLDER not in "".join(rendered)


def test_normalize_dialogue_template_replaces_legacy_nickname():
    line = "小明，今天辛苦啦"
    assert normalize_dialogue_template(line, legacy_nickname="小明") == (
        f"{NICKNAME_PLACEHOLDER}，今天辛苦啦"
    )


def test_normalize_dialogue_templates_batch():
    lines = ["小明，今天辛苦啦", "今天生活对我们小明怎么样呀？"]
    migrated = normalize_dialogue_templates(lines, legacy_nickname="小明")
    assert migrated == [
        f"{NICKNAME_PLACEHOLDER}，今天辛苦啦",
        f"今天生活对我们{NICKNAME_PLACEHOLDER}怎么样呀？",
    ]


def test_apply_nickname_to_template_without_nickname():
    line = f"{NICKNAME_PLACEHOLDER}，今天辛苦啦"
    assert apply_nickname_to_template(line, None) == "今天辛苦啦"
    assert apply_nickname_to_template(
        f"今天生活对我们{NICKNAME_PLACEHOLDER}怎么样呀？", None
    ) == "今天生活对你怎么样呀？"
