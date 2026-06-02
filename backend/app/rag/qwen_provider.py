from openai import APIError, APIConnectionError, APITimeoutError, AuthenticationError, RateLimitError

from app.core.config import settings
from app.exceptions.business import BusinessException
from app.rag.providers import BaseEmbeddingProvider, BaseLLMProvider


def _raise_qwen_error(exc: Exception) -> None:
    if isinstance(exc, AuthenticationError):
        raise BusinessException("千问 API Key 无效或未授权，请检查 QWEN_API_KEY", 502) from exc
    if isinstance(exc, RateLimitError):
        raise BusinessException("千问请求过于频繁，请稍后重试", 429) from exc
    if isinstance(exc, (APIConnectionError, APITimeoutError)):
        raise BusinessException("无法连接千问服务，请检查网络或 QWEN_BASE_URL", 502) from exc
    if isinstance(exc, APIError):
        message = getattr(exc, "message", None) or str(exc)
        raise BusinessException(f"千问接口调用失败: {message}", 502) from exc
    raise BusinessException(f"千问接口调用失败: {exc}", 502) from exc


class QwenLLMProvider(BaseLLMProvider):
    def __init__(self) -> None:
        if not settings.QWEN_API_KEY:
            raise BusinessException("未配置 QWEN_API_KEY，请在 backend/.env 中设置", 500)
        from openai import AsyncOpenAI

        self.client = AsyncOpenAI(api_key=settings.QWEN_API_KEY, base_url=settings.QWEN_BASE_URL)

    async def generate(self, prompt: str, **kwargs) -> str:
        try:
            response = await self.client.chat.completions.create(
                model=settings.QWEN_CHAT_MODEL,
                messages=[{"role": "user", "content": prompt}],
                **kwargs,
            )
        except Exception as exc:
            _raise_qwen_error(exc)
        return response.choices[0].message.content or ""


class QwenEmbeddingProvider(BaseEmbeddingProvider):
    def __init__(self) -> None:
        if not settings.QWEN_API_KEY:
            raise BusinessException("未配置 QWEN_API_KEY", 500)
        from openai import AsyncOpenAI

        self.client = AsyncOpenAI(api_key=settings.QWEN_API_KEY, base_url=settings.QWEN_BASE_URL)

    async def embed(self, text: str) -> list[float]:
        try:
            response = await self.client.embeddings.create(model=settings.QWEN_EMBEDDING_MODEL, input=text)
        except Exception as exc:
            _raise_qwen_error(exc)
        return response.data[0].embedding
