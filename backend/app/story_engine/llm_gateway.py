from app.rag.qwen_provider import QwenLLMProvider


class LLMGateway:
    def __init__(self, provider: QwenLLMProvider | None = None):
        self.provider = provider

    async def generate(self, prompt: str) -> str:
        provider = self.provider or QwenLLMProvider()
        return await provider.generate(prompt, temperature=0.3)
