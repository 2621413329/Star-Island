from pydantic import BaseModel, Field


class AIChatRequest(BaseModel):
    prompt: str = Field(min_length=1, description="文生文：用户输入")


class AIChatResponse(BaseModel):
    content: str


class TextToImageRequest(BaseModel):
    prompt: str = Field(min_length=1, description="文生图：画面描述")
    negative_prompt: str | None = Field(default=None, description="反向提示词")
    size: str = Field(default="1024*1024", description="分辨率，如 1024*1024")
    n: int = Field(default=1, ge=1, le=4, description="生成张数")
    wait: bool = Field(default=False, description="是否服务端轮询直至完成")


class ImageToVideoRequest(BaseModel):
    prompt: str = Field(min_length=1, description="图生视频：动作/镜头描述")
    image_url: str = Field(min_length=1, description="首帧图片公网 URL 或 data:image/...;base64,...")
    negative_prompt: str | None = Field(default=None, description="反向提示词")
    resolution: str = Field(default="720P", description="480P / 720P / 1080P")
    duration: int = Field(default=5, ge=2, le=15, description="视频时长（秒）")
    prompt_extend: bool = Field(default=True, description="是否智能扩写提示词")
    wait: bool = Field(default=False, description="是否服务端轮询直至完成")


class AITaskResponse(BaseModel):
    task_id: str
    task_status: str
    images: list[str] | None = None
    video_url: str | None = None
    request_id: str | None = None
