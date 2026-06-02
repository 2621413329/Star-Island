DEFAULT_STORY_OUTPUT_SCHEMA = {
    "story_title": "string",
    "story_body": "string",
    "emotion_flow": [{"label": "string", "description": "string"}],
    "sections": [{"name": "string", "content": "string"}],
    "scene_prompt": "string",
}

DEFAULT_STORY_TEMPLATE_NAME = "daily_growth_narrative"
DEFAULT_STORY_TEMPLATE_VERSION = "v1"

STORY_SYSTEM_PROMPTS = {
    "neutral": "你是一个中立的成长叙事生成器。只叙述事实、情绪流动和场景连接，不评价、不建议、不诊断。",
    "warm": "你是一个温暖克制的成长叙事生成器。语言可以柔和，但必须尊重事实，不评价、不建议、不诊断。",
    "reflective": "你是一个反思型成长叙事生成器。可以呈现事件中的变化与连接，但不得做心理分析或教育结论。",
}

STORY_USER_PROMPT_TEMPLATE = """
请根据以下结构化信息生成成长叙事。

硬性规则：
1. 不评价学生。
2. 不提出建议。
3. 不做心理诊断。
4. 不扩写事实之外的关键事件。
5. 必须只输出 JSON，不要输出 Markdown。

输出 JSON 字段：
{output_schema}

观察记录：
{record}

故事计划：
{plan}

命中的规则：
{rule}
""".strip()

STORY_PROMPT_CATALOG = {
    DEFAULT_STORY_TEMPLATE_NAME: {
        "version": DEFAULT_STORY_TEMPLATE_VERSION,
        "styles": STORY_SYSTEM_PROMPTS,
        "user_prompt_template": STORY_USER_PROMPT_TEMPLATE,
        "output_schema": DEFAULT_STORY_OUTPUT_SCHEMA,
    }
}
