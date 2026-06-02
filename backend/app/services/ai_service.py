from app.exceptions.business import BusinessException
from app.rag.dashscope_client import DashScopeClient, extract_task_brief
from app.rag.providers import BaseLLMProvider
from app.rag.qwen_provider import QwenLLMProvider
from app.schemas.ai import (
    AIChatRequest,
    AIChatResponse,
    AITaskResponse,
    ImageToVideoRequest,
    TextToImageRequest,
)


class AIService:
    def __init__(self, llm_provider: BaseLLMProvider | None = None, dashscope: DashScopeClient | None = None):
        self.llm_provider = llm_provider or QwenLLMProvider()
        self.dashscope = dashscope or DashScopeClient()

    async def chat(self, payload: AIChatRequest) -> AIChatResponse:
        content = await self.llm_provider.generate(payload.prompt)
        return AIChatResponse(content=content)

    async def text_to_image(self, payload: TextToImageRequest) -> AITaskResponse:
        data = await self.dashscope.create_text_to_image_task(
            prompt=payload.prompt,
            negative_prompt=payload.negative_prompt,
            size=payload.size,
            n=payload.n,
        )
        brief = extract_task_brief(data)
        task_id = brief.get("task_id")
        if not task_id:
            raise BusinessException("千问未返回 task_id", 502)
        if payload.wait:
            data = await self.dashscope.wait_for_task(task_id)
            brief = extract_task_brief(data)
        return AITaskResponse(**brief)

    async def image_to_video(self, payload: ImageToVideoRequest) -> AITaskResponse:
        data = await self.dashscope.create_image_to_video_task(
            prompt=payload.prompt,
            image_url=payload.image_url,
            negative_prompt=payload.negative_prompt,
            resolution=payload.resolution,
            duration=payload.duration,
            prompt_extend=payload.prompt_extend,
        )
        brief = extract_task_brief(data)
        task_id = brief.get("task_id")
        if not task_id:
            raise BusinessException("千问未返回 task_id", 502)
        if payload.wait:
            data = await self.dashscope.wait_for_task(task_id)
            brief = extract_task_brief(data)
        return AITaskResponse(**brief)

    async def get_task(self, task_id: str) -> AITaskResponse:
        data = await self.dashscope.get_task(task_id)
        brief = extract_task_brief(data)
        if not brief.get("task_id"):
            brief["task_id"] = task_id
        return AITaskResponse(**brief)
