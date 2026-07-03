from app.core.text_utils import soft_truncate


def test_soft_truncate_keeps_short_text():
    assert soft_truncate("今天很开心。", 120) == "今天很开心。"


def test_soft_truncate_breaks_at_punctuation():
    text = "这周写了三条日常，工作有点忙，但周末去公园散步了，心情慢慢好起来。"
    trimmed = soft_truncate(text, 30)
    assert len(trimmed) <= 30
    assert trimmed.endswith(("。", "！", "？", "…", "，", "、"))


def test_soft_truncate_uses_ellipsis_without_break():
    trimmed = soft_truncate("abcdefghijklmnopqrstuvwxyz", 10)
    assert trimmed.endswith("…")
    assert len(trimmed) <= 10
