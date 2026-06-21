from types import SimpleNamespace

from app.core.moment_content import get_story_content, is_voice_moment


def test_get_story_content_text():
    moment = SimpleNamespace(content_type="text", note="今天很开心", speech_text=None)
    assert get_story_content(moment) == "今天很开心"
    assert not is_voice_moment(moment)


def test_get_story_content_voice():
    moment = SimpleNamespace(
        content_type="voice",
        note=None,
        speech_text="今天踢足球了",
    )
    assert get_story_content(moment) == "今天踢足球了"
    assert is_voice_moment(moment)
