"""文本软截断：尽量在标点处截断，避免句中硬切。"""

from __future__ import annotations

import re

_BREAKERS = "。！？…；，、.!?,;"


def soft_truncate(text: str, max_len: int) -> str:
    cleaned = re.sub(r"\s+", "", (text or "").strip())
    if max_len <= 0 or len(cleaned) <= max_len:
        return cleaned
    slice_ = cleaned[:max_len]
    min_index = int(max_len * 0.55)
    for i in range(len(slice_) - 1, min_index - 1, -1):
        if slice_[i] in _BREAKERS:
            return slice_[: i + 1]
    if max_len >= 2:
        return slice_[: max_len - 1] + "…"
    return "…"
