from app.services.companion_scene_service import CompanionSceneService


def test_scene_from_event_tags():
    scene = CompanionSceneService().build(
        companion_style="chibi",
        emotion_tag="happy",
        event_tags=["朋友"],
    )
    assert "chibi" in scene["companion_scene"]
    assert "friendship" in scene["companion_scene"]


def test_scene_from_note_overrides():
    scene = CompanionSceneService().build(
        companion_style="normal",
        emotion_tag="calm",
        event_tags=["其它"],
        note="今天打球很开心",
    )
    assert "sport" in scene["companion_scene"]
