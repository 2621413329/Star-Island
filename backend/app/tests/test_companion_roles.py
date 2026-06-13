from app.core.companion_roles import (
    XIAO_GUANGBAO,
    XIAO_XINGZAI,
    is_valid_companion_role_id,
    migrate_gender_to_role_id,
    render_key_for_role,
    resolve_companion_role_id,
)


def test_migrate_gender_to_role_id():
    assert migrate_gender_to_role_id("male") == XIAO_XINGZAI
    assert migrate_gender_to_role_id("female") == XIAO_GUANGBAO
    assert migrate_gender_to_role_id("other") is None


def test_resolve_companion_role_id_prefers_role_column():
    assert (
        resolve_companion_role_id(
            companion_role_id=XIAO_GUANGBAO,
            legacy_gender="male",
        )
        == XIAO_GUANGBAO
    )
    assert (
        resolve_companion_role_id(
            companion_role_id=None,
            legacy_gender="female",
        )
        == XIAO_GUANGBAO
    )


def test_render_key_for_role():
    assert render_key_for_role(XIAO_XINGZAI) == "male"
    assert render_key_for_role(XIAO_GUANGBAO) == "female"
    assert is_valid_companion_role_id("unknown") is False
