from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.ai import (
    AIChatRequest,
    AIChatResponse,
    AITaskResponse,
    ImageToVideoRequest,
    TextToImageRequest,
)
from app.schemas.common import ResponseModel
from app.services.ai_service import AIService

router = APIRouter(prefix="/ai", tags=["AI能力"])


@router.post("/text/chat", response_model=ResponseModel[AIChatResponse], summary="文生文")
async def text_chat(payload: AIChatRequest, _: User = Depends(get_current_user)):
    return ResponseModel(data=await AIService().chat(payload))


@router.post("/chat", response_model=ResponseModel[AIChatResponse], summary="文生文（兼容旧路径）")
async def chat_with_qwen(payload: AIChatRequest, _: User = Depends(get_current_user)):
    return ResponseModel(data=await AIService().chat(payload))


@router.post("/text-to-image", response_model=ResponseModel[AITaskResponse], summary="文生图")
async def text_to_image(payload: TextToImageRequest, _: User = Depends(get_current_user)):
    return ResponseModel(data=await AIService().text_to_image(payload))


@router.post("/image-to-video", response_model=ResponseModel[AITaskResponse], summary="图生视频")
async def image_to_video(payload: ImageToVideoRequest, _: User = Depends(get_current_user)):
    return ResponseModel(data=await AIService().image_to_video(payload))


@router.get("/tasks/{task_id}", response_model=ResponseModel[AITaskResponse], summary="查询异步任务")
async def get_ai_task(task_id: str, _: User = Depends(get_current_user)):
    return ResponseModel(data=await AIService().get_task(task_id))
