"""登岛伙伴角色 id 与历史 gender 字段的映射。"""

from __future__ import annotations

XIAO_XINGZAI = "xiao_xingzai"
XIAO_GUANGBAO = "xiao_guangbao"
YUAN = "yuan"
MENG = "meng"

DEFAULT_COMPANION_ROLE_ID = XIAO_XINGZAI

COMPANION_ROLE_SEEDS: tuple[dict[str, str | int | bool], ...] = (
    {
        "id": XIAO_XINGZAI,
        "display_name": "小星仔",
        "render_key": "male",
        "is_active": True,
        "sort_order": 0,
    },
    {
        "id": XIAO_GUANGBAO,
        "display_name": "小光宝",
        "render_key": "female",
        "is_active": True,
        "sort_order": 1,
    },
    {
        "id": YUAN,
        "display_name": "小元",
        "render_key": "yuan",
        "is_active": True,
        "sort_order": 2,
    },
    {
        "id": MENG,
        "display_name": "小萌",
        "render_key": "meng",
        "is_active": True,
        "sort_order": 3,
    },
)

PREMIUM_COMPANION_ROLE_IDS = {YUAN, MENG}

_LEGACY_GENDER_TO_ROLE = {
    "male": XIAO_XINGZAI,
    "female": XIAO_GUANGBAO,
}

_ROLE_TO_RENDER_KEY = {
    XIAO_XINGZAI: "male",
    XIAO_GUANGBAO: "female",
    YUAN: "yuan",
    MENG: "meng",
}

_ROLE_DISPLAY_NAMES = {
    XIAO_XINGZAI: "小星仔",
    XIAO_GUANGBAO: "小光宝",
    YUAN: "小元",
    MENG: "小萌",
}


def is_valid_companion_role_id(role_id: str | None) -> bool:
    if not role_id:
        return False
    return role_id in _ROLE_TO_RENDER_KEY


def is_premium_companion_role_id(role_id: str | None) -> bool:
    return role_id in PREMIUM_COMPANION_ROLE_IDS


def migrate_gender_to_role_id(gender: str | None) -> str | None:
    if not gender:
        return None
    return _LEGACY_GENDER_TO_ROLE.get(gender.strip().lower())


def render_key_for_role(role_id: str | None) -> str | None:
    if not role_id:
        return None
    return _ROLE_TO_RENDER_KEY.get(role_id)


def display_name_for_role(
    role_id: str | None,
    *,
    legacy_gender: str | None = None,
) -> str:
    resolved = (
        resolve_companion_role_id(
            companion_role_id=role_id,
            legacy_gender=legacy_gender,
        )
        or DEFAULT_COMPANION_ROLE_ID
    )
    return _ROLE_DISPLAY_NAMES.get(
        resolved, _ROLE_DISPLAY_NAMES[DEFAULT_COMPANION_ROLE_ID]
    )


def resolve_companion_role_id(
    *,
    companion_role_id: str | None,
    legacy_gender: str | None = None,
) -> str | None:
    if is_valid_companion_role_id(companion_role_id):
        return companion_role_id
    return migrate_gender_to_role_id(legacy_gender)
