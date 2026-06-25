"""扩展心情目录：五档手动心情 + AI 感受标签。"""

from __future__ import annotations

from dataclasses import dataclass

LEGACY_MOOD_LABELS: dict[str, str] = {
    "happy": "超开心",
    "calm": "开心",
    "thinking": "平静",
    "sad": "低落",
    "angry": "生气",
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

EXTENDED_EMOTION_LABELS: dict[str, str] = {
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

EMOTION_LABELS: dict[str, str] = {
    **LEGACY_MOOD_LABELS,
    **EXTENDED_EMOTION_LABELS,
}

EMOTION_LEGACY_MOOD: dict[str, str] = {
    **{k: k for k in LEGACY_MOOD_LABELS},
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


@dataclass(frozen=True)
class EffectiveEmotion:
    emotion_id: str
    label: str
    legacy_mood_id: str


def effective_emotion_for_moment(moment) -> EffectiveEmotion:
    ai = (getattr(moment, "ai_emotion", None) or "").strip()
    if not ai:
        payload = getattr(moment, "visual_payload", None) or {}
        if isinstance(payload, dict):
            raw = payload.get("ai_emotion")
            if isinstance(raw, str):
                ai = raw.strip()
    if ai:
        emotion_id = AI_LABEL_TO_EMOTION_ID.get(ai)
        if emotion_id:
            return EffectiveEmotion(
                emotion_id=emotion_id,
                label=EMOTION_LABELS[emotion_id],
                legacy_mood_id=EMOTION_LEGACY_MOOD[emotion_id],
            )
    legacy = (getattr(moment, "emotion_tag", None) or "calm").strip()
    return EffectiveEmotion(
        emotion_id=legacy,
        label=LEGACY_MOOD_LABELS.get(legacy, legacy),
        legacy_mood_id=legacy,
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
