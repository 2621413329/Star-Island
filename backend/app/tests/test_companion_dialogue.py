from app.services.companion_action_ai_service import CompanionActionAIService


def test_story_summary_lines_with_nickname():
    svc = CompanionActionAIService()
    lines = svc._story_summary_lines_from_context(
        ["生活", "日常"],
        "calm",
        "今天加班到很晚",
        "加班夜",
        nickname="小明",
    )
    assert any("小明" in line for line in lines)
    assert any("怎么样" in line or "辛苦" in line for line in lines)
    assert len(lines) == 3


def test_story_summary_lines_without_nickname():
    svc = CompanionActionAIService()
    lines = svc._story_summary_lines_from_context(
        ["生活"],
        "calm",
        None,
        "平静一刻",
        nickname=None,
    )
    assert all("小明" not in line for line in lines)
    assert len(lines) == 3
