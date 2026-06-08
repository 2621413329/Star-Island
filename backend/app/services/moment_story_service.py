"""教师端：将学生瞬间格式化为「分类-故事」展示文案。"""

from __future__ import annotations

from app.models.profile import DailyMoment
from app.services.daily_mood_report_service import CATEGORY_LABELS


def format_moment_story_detail(moment: DailyMoment, *, include_note: bool = False) -> str:
    tags = moment.event_tags or []
    main = CATEGORY_LABELS.get(tags[0], tags[0]) if tags else "其它"
    subs = [t for t in tags[1:] if t]
    head = f"{main}-{'-'.join(subs)}" if subs else main
    if not include_note:
        return head
    note = (moment.note or "").strip()
    if note:
        return f"{head}：{note}"
    return head


def moment_category_label(moment: DailyMoment) -> str:
    tags = moment.event_tags or []
    if not tags:
        return "其它"
    return CATEGORY_LABELS.get(tags[0], tags[0])
