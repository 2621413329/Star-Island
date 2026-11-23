from datetime import date, datetime, timedelta, timezone

from app.services.growth_points_service import GrowthPointsService, MAX_LEVEL


class _Moment:
    def __init__(
        self,
        *,
        moment_date: date,
        note: str | None,
        event_tags: list[str],
        created_at: datetime | None = None,
    ):
        self.moment_date = moment_date
        self.note = note
        self.event_tags = event_tags
        self.created_at = created_at
        self.content_type = "text"
        self.speech_text = None


def test_story_with_detail_grants_detail_and_story_xp():
    today = date(2026, 6, 12)
    svc = GrowthPointsService()
    summary = svc.compute(
        moments=[
            _Moment(
                moment_date=today,
                note="今天发生了让我开心的事情",
                event_tags=["学习"],
            )
        ],
        reports=[],
        today=today,
        profile_today_mood="happy",
    )
    # 心情 +10，10 字故事 +5，写今日故事 +5
    assert summary.growth_value == 20


def test_backfilled_diary_does_not_increase_growth():
    today = date(2026, 6, 12)
    yesterday = today - timedelta(days=1)
    # 上海 6 月 12 日中午完成：当日日记计入，补录昨天不计入。
    completed_at = datetime(2026, 6, 12, 4, 0, tzinfo=timezone.utc)
    today_moment = _Moment(
        moment_date=today,
        note="今天发生了让我开心的事情",
        event_tags=["学习"],
        created_at=completed_at,
    )
    backfill = _Moment(
        moment_date=yesterday,
        note="补上昨天没写完的一段日常记录",
        event_tags=["生活"],
        created_at=completed_at,
    )
    svc = GrowthPointsService()
    before = svc.compute(
        moments=[today_moment],
        reports=[],
        today=today,
        profile_today_mood=None,
    )
    after = svc.compute(
        moments=[today_moment, backfill],
        reports=[],
        today=today,
        profile_today_mood=None,
    )
    assert after.growth_value == before.growth_value
    assert after.streak_days == before.streak_days
    assert after.max_streak_days == before.max_streak_days


def test_diary_written_on_its_own_day_still_counts():
    day = date(2026, 6, 11)
    today = date(2026, 6, 12)
    svc = GrowthPointsService()
    summary = svc.compute(
        moments=[
            _Moment(
                moment_date=day,
                note="当天写下的一段值得记住的日常",
                event_tags=["学习"],
                created_at=datetime(2026, 6, 11, 4, 0, tzinfo=timezone.utc),
            )
        ],
        reports=[],
        today=today,
        profile_today_mood=None,
    )
    assert summary.growth_value == 20


def test_story_without_report_still_grants_story_xp():
    today = date(2026, 6, 12)
    svc = GrowthPointsService()
    summary = svc.compute(
        moments=[_Moment(moment_date=today, note=None, event_tags=["学习"])],
        reports=[],
        today=today,
        profile_today_mood=None,
    )
    # 有故事即 +5（心情 +10 来自故事记录，今日故事 +5）
    assert summary.growth_value == 15


def test_ninety_day_full_attendance_reaches_level_twenty():
    today = date(2026, 6, 30)
    start = today - timedelta(days=89)
    moments = [
        _Moment(
            moment_date=start + timedelta(days=i),
            note="今天发生了值得记录的事情，留下一点成长足迹",
            event_tags=["学习"],
        )
        for i in range(90)
    ]
    svc = GrowthPointsService()
    summary = svc.compute(
        moments=moments,
        reports=[],
        today=today,
        profile_today_mood=None,
    )
    assert summary.growth_value >= 2480
    assert summary.level == MAX_LEVEL
    assert summary.level_title == "岛屿传说"
