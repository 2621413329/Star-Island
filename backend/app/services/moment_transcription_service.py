"""语音转文字：DashScope Paraformer ASR，转写结果供 AI 打标。"""

from __future__ import annotations

import asyncio
import json
import uuid
from pathlib import Path
from urllib.parse import quote

import httpx
from loguru import logger

from app.core.config import settings

ASR_TIMEOUT_SEC = 60.0
ASR_POLL_INTERVAL_SEC = 1.5
ASR_POLL_MAX_ATTEMPTS = 40


class MomentTranscriptionService:
    async def transcribe(
        self,
        file_path: Path,
        *,
        voice_url: str | None = None,
    ) -> str:
        if not settings.QWEN_API_KEY:
            raise RuntimeError("未配置 QWEN_API_KEY")
        if not file_path.is_file():
            raise FileNotFoundError(str(file_path))

        file_url, oss_resolve = await self._resolve_file_url(file_path, voice_url)
        logger.info(
            "voice ASR submit file={} url_kind={}",
            file_path.name,
            "oss" if oss_resolve else "http",
        )
        task_id = await self._submit_transcription(file_url, oss_resolve=oss_resolve)
        output = await self._poll_transcription(task_id, oss_resolve=oss_resolve)
        text = await self._extract_transcription_text(output)
        cleaned = text.strip()
        if not cleaned:
            raise RuntimeError("识别结果为空")
        return cleaned

    async def _resolve_file_url(
        self, file_path: Path, voice_url: str | None
    ) -> tuple[str, bool]:
        """返回 (file_url, 是否需要 X-DashScope-OssResourceResolve)。"""
        public_base = (settings.PUBLIC_API_BASE_URL or "").strip().rstrip("/")
        if public_base and voice_url:
            path = voice_url if voice_url.startswith("/") else f"/{voice_url}"
            encoded = quote(path, safe="/%")
            return f"{public_base}{encoded}", False

        return await self._upload_to_dashscope_temp(file_path), True

    async def _upload_to_dashscope_temp(self, file_path: Path) -> str:
        base = settings.QWEN_DASHSCOPE_BASE_URL.rstrip("/")
        headers = {"Authorization": f"Bearer {settings.QWEN_API_KEY}"}
        params = {
            "action": "getPolicy",
            "model": settings.QWEN_ASR_MODEL,
        }
        async with httpx.AsyncClient(timeout=ASR_TIMEOUT_SEC) as client:
            policy_resp = await client.get(
                f"{base}/uploads",
                headers=headers,
                params=params,
            )
            policy_resp.raise_for_status()
            policy_data = policy_resp.json().get("data") or {}
            if not policy_data.get("upload_host"):
                raise RuntimeError(f"获取上传凭证失败: {policy_resp.text}")

            unique_name = f"{uuid.uuid4().hex}{file_path.suffix or '.m4a'}"
            key = f"{policy_data['upload_dir']}/{unique_name}"
            form = {
                "OSSAccessKeyId": policy_data["oss_access_key_id"],
                "Signature": policy_data["signature"],
                "policy": policy_data["policy"],
                "x-oss-object-acl": policy_data["x_oss_object_acl"],
                "x-oss-forbid-overwrite": policy_data["x_oss_forbid_overwrite"],
                "key": key,
                "success_action_status": "200",
            }
            with file_path.open("rb") as handle:
                upload_resp = await client.post(
                    policy_data["upload_host"],
                    data=form,
                    files={"file": (unique_name, handle, "audio/mp4")},
                )
            upload_resp.raise_for_status()
            return f"oss://{key}"

    async def _submit_transcription(
        self, file_url: str, *, oss_resolve: bool
    ) -> str:
        url = (
            f"{settings.QWEN_DASHSCOPE_BASE_URL.rstrip('/')}"
            "/services/audio/asr/transcription"
        )
        headers = {
            "Authorization": f"Bearer {settings.QWEN_API_KEY}",
            "Content-Type": "application/json",
            "X-DashScope-Async": "enable",
        }
        if oss_resolve:
            headers["X-DashScope-OssResourceResolve"] = "enable"

        body = {
            "model": settings.QWEN_ASR_MODEL,
            "input": {"file_urls": [file_url]},
            "parameters": {
                "channel_id": [0],
                "language_hints": ["zh", "en"],
            },
        }
        async with httpx.AsyncClient(timeout=ASR_TIMEOUT_SEC) as client:
            response = await client.post(url, headers=headers, json=body)
            response.raise_for_status()
            task_id = response.json().get("output", {}).get("task_id")
            if not task_id:
                raise RuntimeError(f"ASR 任务创建失败: {response.text}")
            return str(task_id)

    async def _poll_transcription(
        self, task_id: str, *, oss_resolve: bool
    ) -> dict:
        status_url = (
            f"{settings.QWEN_DASHSCOPE_BASE_URL.rstrip('/')}/tasks/{task_id}"
        )
        headers = {"Authorization": f"Bearer {settings.QWEN_API_KEY}"}
        if oss_resolve:
            headers["X-DashScope-OssResourceResolve"] = "enable"

        async with httpx.AsyncClient(timeout=ASR_TIMEOUT_SEC) as client:
            for _ in range(ASR_POLL_MAX_ATTEMPTS):
                await asyncio.sleep(ASR_POLL_INTERVAL_SEC)
                poll = await client.get(status_url, headers=headers)
                poll.raise_for_status()
                output = poll.json().get("output", {})
                status = output.get("task_status")
                if status == "SUCCEEDED":
                    return output
                if status in {"FAILED", "CANCELED"}:
                    raise RuntimeError(f"ASR 任务失败: {output}")
            raise TimeoutError("ASR 任务超时")

    async def _extract_transcription_text(self, output: dict) -> str:
        results = output.get("results") or []
        for item in results:
            if not isinstance(item, dict):
                continue
            subtask_status = item.get("subtask_status")
            if subtask_status == "FAILED":
                raise RuntimeError(
                    item.get("message") or item.get("code") or "ASR 子任务失败"
                )
            inline = item.get("transcription") or item.get("text")
            if inline:
                return str(inline).strip()

            transcription_url = item.get("transcription_url")
            if transcription_url:
                text = await self._fetch_transcription_json(transcription_url)
                if text:
                    return text

        fallback = output.get("transcription") or output.get("text")
        return str(fallback or "").strip()

    async def _fetch_transcription_json(self, url: str) -> str:
        async with httpx.AsyncClient(timeout=ASR_TIMEOUT_SEC) as client:
            response = await client.get(url)
            response.raise_for_status()
            payload = response.json()

        transcripts = payload.get("transcripts") or []
        chunks: list[str] = []
        for item in transcripts:
            if not isinstance(item, dict):
                continue
            text = str(item.get("text") or "").strip()
            if text:
                chunks.append(text)
        if chunks:
            return " ".join(chunks)

        sentences = payload.get("sentences") or []
        for item in sentences:
            if isinstance(item, dict):
                text = str(item.get("text") or "").strip()
                if text:
                    chunks.append(text)
        return " ".join(chunks).strip()

    @staticmethod
    def parse_transcription_payload(payload: dict | str) -> str:
        """供单元测试使用的同步解析 helper。"""
        data = json.loads(payload) if isinstance(payload, str) else payload
        transcripts = data.get("transcripts") or []
        parts = [
            str(item.get("text") or "").strip()
            for item in transcripts
            if isinstance(item, dict) and str(item.get("text") or "").strip()
        ]
        return " ".join(parts).strip()
