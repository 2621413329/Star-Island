"""AI 感受心情目录（用户唯一可见的心情体系）。"""

from __future__ import annotations

from dataclasses import dataclass

DEFAULT_EMOTION_ID = "ping_jing"

LEGACY_TAG_TO_EMOTION_ID: dict[str, str] = {
    "happy": "kai_xin",
    "calm": "ping_jing",
    "thinking": "jiao_lv",
    "sad": "shi_luo",
    "angry": "fen_nu",
}

AI_LABEL_TO_EMOTION_ID: dict[str, str] = {
    "开心": "kai_xin",
    "平静": "ping_jing",
    "焦虑": "jiao_lv",
    "压力": "ya_li",
    "兴奋": "xing_fen",
    "感动": "gan_dong",
    "失落": "shi_luo",
    "愤怒": "fen_nu",
    "生气": "fen_nu",
    "自我觉察": "zi_wo_jue_cha",
    "身体关怀": "shen_ti_guan_huai",
    "满足": "kai_xin",
    "难过": "shi_luo",
    "思考": "jiao_lv",
}

EMOTION_LABELS: dict[str, str] = {
    "kai_xin": "开心",
    "ping_jing": "平静",
    "jiao_lv": "焦虑",
    "ya_li": "压力",
    "xing_fen": "兴奋",
    "gan_dong": "感动",
    "shi_luo": "失落",
    "fen_nu": "愤怒",
    "zi_wo_jue_cha": "自我觉察",
    "shen_ti_guan_huai": "身体关怀",
}

EMOTION_LEGACY_MOOD: dict[str, str] = {
    "kai_xin": "happy",
    "ping_jing": "calm",
    "jiao_lv": "thinking",
    "ya_li": "thinking",
    "xing_fen": "happy",
    "gan_dong": "happy",
    "shi_luo": "sad",
    "fen_nu": "angry",
    "zi_wo_jue_cha": "thinking",
    "shen_ti_guan_huai": "calm",
}

EMOTION_COMPANION_EXPRESSION: dict[str, str] = {
    "kai_xin": "happy",
    "ping_jing": "calm",
    "jiao_lv": "thinking",
    "ya_li": "thinking",
    "xing_fen": "happy",
    "gan_dong": "hopeful",
    "shi_luo": "sad",
    "fen_nu": "angry",
    "zi_wo_jue_cha": "thinking",
    "shen_ti_guan_huai": "hopeful",
}

EMOTION_ID_PATTERN = (
    "^(kai_xin|ping_jing|jiao_lv|ya_li|xing_fen|gan_dong|"
    "shi_luo|fen_nu|zi_wo_jue_cha|shen_ti_guan_huai)$"
)

# 旧五档标签，仅供内部氛围/兼容读取。
LEGACY_MOOD_LABELS: dict[str, str] = {
    "happy": "开心",
    "calm": "平静",
    "thinking": "焦虑",
    "sad": "失落",
    "angry": "愤怒",
}


def normalize_emotion_id(raw: str | None) -> str:
    key = (raw or "").strip()
    if not key:
        return DEFAULT_EMOTION_ID
    if key in EMOTION_LABELS:
        return key
    mapped = LEGACY_TAG_TO_EMOTION_ID.get(key)
    if mapped:
        return mapped
    mapped = AI_LABEL_TO_EMOTION_ID.get(key)
    if mapped:
        return mapped
    return DEFAULT_EMOTION_ID


@dataclass(frozen=True)
class EffectiveEmotion:
    emotion_id: str
    label: str
    legacy_mood_id: str
    companion_expression: str


def effective_emotion_for_moment(moment) -> EffectiveEmotion:
    ai = (getattr(moment, "ai_emotion", None) or "").strip()
    if not ai:
        payload = getattr(moment, "visual_payload", None) or {}
        if isinstance(payload, dict):
            raw = payload.get("ai_emotion")
            if isinstance(raw, str):
                ai = raw.strip()
    if ai:
        emotion_id = AI_LABEL_TO_EMOTION_ID.get(ai, normalize_emotion_id(ai))
    else:
        legacy = (getattr(moment, "emotion_tag", None) or DEFAULT_EMOTION_ID).strip()
        emotion_id = normalize_emotion_id(legacy)
    return EffectiveEmotion(
        emotion_id=emotion_id,
        label=EMOTION_LABELS[emotion_id],
        legacy_mood_id=EMOTION_LEGACY_MOOD[emotion_id],
        companion_expression=EMOTION_COMPANION_EXPRESSION[emotion_id],
    )


def dominant_emotion_by_count(counts: dict[str, int]) -> str | None:
    if not counts:
        return None
    best_id: str | None = None
    best_count = -1
    for emotion_id, count in counts.items():
        if count > best_count:
            best_count = count
            best_id = emotion_id
    return best_id if best_count > 0 else None


def legacy_mood_from_emotion_id(emotion_id: str | None) -> str:
    normalized = normalize_emotion_id(emotion_id)
    return EMOTION_LEGACY_MOOD[normalized]
