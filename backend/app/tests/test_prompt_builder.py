from datetime import datetime, timezone
from types import SimpleNamespace
from uuid import uuid4

from app.story_engine.prompt_builder import PromptBuilder
from app.story_engine.types import StoryPlan


def test_prompt_builder_enforces_output_constraints():
    record = SimpleNamespace(
        id=uuid4(),
        student_id=uuid4(),
        event_type="人际关系",
        event_title="主动帮助同学",
        event_content="课间主动帮助同学整理材料。",
        emotion_tag="warm",
        growth_dimension="social",
        created_at=datetime.now(timezone.utc),
    )
    plan = StoryPlan(
        title_seed="主动帮助同学",
        style="neutral",
        sections=["event", "emotion_flow", "context"],
        template_name="daily_growth_narrative",
        required_fields=["story_title", "story_body"],
    )

    prompt = PromptBuilder().build(record, plan, selected_rule=None)

    assert "不评价学生" in prompt
    assert "不提出建议" in prompt
    assert "不做心理诊断" in prompt
    assert "story_title" in prompt
    assert "emotion_flow" in prompt
