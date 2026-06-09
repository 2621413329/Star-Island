from app.services.growth_points_service import aggregate_emotion_fragments


class _Moment:
    def __init__(self, emotion_tag: str):
        self.emotion_tag = emotion_tag


def test_aggregate_emotion_fragments():
    moments = [
        _Moment("happy"),
        _Moment("happy"),
        _Moment("calm"),
    ]
    count, totals = aggregate_emotion_fragments(moments)
    assert count == 3
    assert totals == {"happy": 2, "calm": 1}
