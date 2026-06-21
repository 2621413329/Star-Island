from app.core.companion_prop_labels import ensure_visual_prop_label
from app.services.profile_service import ProfileService


def test_finalize_moment_scene_import_available():
    visual = {"prop_asset": "book"}
    scene = ProfileService._finalize_moment_scene(
        {"visual_payload": visual},
        primary_tag="study",
        secondary_tags=[],
        growth_points=[],
        ai_emotion=None,
    )
    ensure_visual_prop_label(scene["visual_payload"])
    assert scene["visual_payload"].get("prop_label")
