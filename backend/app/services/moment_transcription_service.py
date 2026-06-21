"""语音转文字：DashScope Paraformer，失败时不阻断故事保存。"""

from __future__ import annotations

import asyncio
from pathlib import Path

import httpx
from loguru import logger

from app.core.config import settings

ASR_TIMEOUT_SEC = 45.0


class MomentTranscriptionService:
    async def transcribe(self, file_path: Path) -> str:
        if not settings.QWEN_API_KEY:
            raise RuntimeError("未配置 QWEN_API_KEY")
        if not file_path.is_file():
            raise FileNotFoundError(str(file_path))

        file_id = await self._upload_file(file_path)
        text = await self._run_transcription(file_id)
        cleaned = (text or "").strip()
        if not cleaned:
            raise RuntimeError("识别结果为空")
        return cleaned

    async def _upload_file(self, file_path: Path) -> str:
        url = f"{settings.QWEN_DASHSCOPE_BASE_URL.rstrip('/')}/files"
        headers = {"Authorization": f"Bearer {settings.QWEN_API_KEY}"}
        async with httpx.AsyncClient(timeout=ASR_TIMEOUT_SEC) as client:
            with file_path.open("rb") as handle:
                response = await client.post(
                    url,
                    headers=headers,
                    files={
                        "file": (
                            file_path.name,
                            handle,
                            "audio/mp4",
                        )
                    },
                    data={"purpose": "file-extract"},
                )
            response.raise_for_status()
            payload = response.json()
            file_id = payload.get("id") or payload.get("file_id")
            if not file_id:
                raise RuntimeError(f"文件上传响应无效: {payload}")
            return str(file_id)

    async def _run_transcription(self, file_id: str) -> str:
        submit_url = (
            f"{settings.QWEN_DASHSCOPE_BASE_URL.rstrip('/')}"
            "/services/audio/asr/transcription"
        )
        headers = {
            "Authorization": f"Bearer {settings.QWEN_API_KEY}",
            "Content-Type": "application/json",
            "X-DashScope-Async": "enable",
        }
        body = {
            "model": settings.QWEN_ASR_MODEL,
            "input": {"file_ids": [file_id]},
            "parameters": {"language_hints": ["zh", "en"]},
        }
        async with httpx.AsyncClient(timeout=ASR_TIMEOUT_SEC) as client:
            submit = await client.post(submit_url, headers=headers, json=body)
            submit.raise_for_status()
            task_id = submit.json().get("output", {}).get("task_id")
            if not task_id:
                raise RuntimeError(f"ASR 任务创建失败: {submit.text}")

            status_url = (
                f"{settings.QWEN_DASHSCOPE_BASE_URL.rstrip('/')}"
                f"/tasks/{task_id}"
            )
            for _ in range(30):
                await asyncio.sleep(1.5)
                poll = await client.get(
                    status_url,
                    headers={"Authorization": f"Bearer {settings.QWEN_API_KEY}"},
                )
                poll.raise_for_status()
                output = poll.json().get("output", {})
                status = output.get("task_status")
                if status == "SUCCEEDED":
                    return self._extract_text(output)
                if status in {"FAILED", "CANCELED"}:
                    raise RuntimeError(f"ASR 任务失败: {output}")
            raise TimeoutError("ASR 任务超时")

    @staticmethod
    def _extract_text(output: dict) -> str:
        results = output.get("results") or []
        if not results:
            transcription = output.get("transcription") or output.get("text")
            return str(transcription or "")
        chunks: list[str] = []
        for item in results:
            if isinstance(item, dict):
                text = item.get("transcription") or item.get("text") or ""
                if text:
                    chunks.append(str(text).strip())
        return " ".join(chunks).strip()
