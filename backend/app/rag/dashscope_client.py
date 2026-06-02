import asyncio
import time
from typing import Any

import httpx

from app.core.config import settings
from app.exceptions.business import BusinessException


def _api_error_message(data: dict[str, Any], fallback: str) -> str:
    return (
        data.get("message")
        or (data.get("error") or {}).get("message")
        or data.get("code")
        or fallback
    )


class DashScopeClient:
    """阿里云 DashScope 原生 API（文生图、图生视频、任务查询）。"""

    def __init__(self) -> None:
        if not settings.QWEN_API_KEY:
            raise BusinessException("未配置 QWEN_API_KEY，请在 backend/.env 中设置", 500)
        self._api_key = settings.QWEN_API_KEY
        self._base = settings.QWEN_DASHSCOPE_BASE_URL.rstrip("/")

    def _auth_headers(self, *, async_task: bool = False) -> dict[str, str]:
        headers = {
            "Authorization": f"Bearer {self._api_key}",
            "Content-Type": "application/json",
        }
        if async_task:
            headers["X-DashScope-Async"] = "enable"
        return headers

    async def _request(
        self,
        method: str,
        path: str,
        *,
        async_task: bool = False,
        json: dict[str, Any] | None = None,
        timeout: float = 60.0,
    ) -> dict[str, Any]:
        url = f"{self._base}{path}"
        try:
            async with httpx.AsyncClient(timeout=httpx.Timeout(timeout)) as client:
                response = await client.request(
                    method,
                    url,
                    headers=self._auth_headers(async_task=async_task),
                    json=json,
                )
        except httpx.RequestError as exc:
            raise BusinessException(f"无法连接千问服务: {exc}", 502) from exc

        try:
            data: dict[str, Any] = response.json() if response.content else {}
        except ValueError as exc:
            raise BusinessException(f"千问返回非 JSON 响应: {response.text[:200]}", 502) from exc

        if response.status_code >= 400:
            raise BusinessException(
                f"千问接口调用失败: {_api_error_message(data, response.text[:200])}",
                502,
            )
        return data

    async def create_text_to_image_task(
        self,
        *,
        prompt: str,
        negative_prompt: str | None = None,
        size: str,
        n: int,
    ) -> dict[str, Any]:
        input_body: dict[str, Any] = {"prompt": prompt}
        if negative_prompt:
            input_body["negative_prompt"] = negative_prompt
        body = {
            "model": settings.QWEN_T2I_MODEL,
            "input": input_body,
            "parameters": {"size": size, "n": n},
        }
        return await self._request(
            "POST",
            "/services/aigc/text2image/image-synthesis",
            async_task=True,
            json=body,
        )

    async def create_image_to_video_task(
        self,
        *,
        prompt: str,
        image_url: str,
        negative_prompt: str | None = None,
        resolution: str,
        duration: int,
        prompt_extend: bool,
    ) -> dict[str, Any]:
        input_body: dict[str, Any] = {"prompt": prompt, "img_url": image_url}
        if negative_prompt:
            input_body["negative_prompt"] = negative_prompt
        body = {
            "model": settings.QWEN_I2V_MODEL,
            "input": input_body,
            "parameters": {
                "resolution": resolution,
                "duration": duration,
                "prompt_extend": prompt_extend,
            },
        }
        return await self._request(
            "POST",
            "/services/aigc/video-generation/video-synthesis",
            async_task=True,
            json=body,
            timeout=120.0,
        )

    async def get_task(self, task_id: str) -> dict[str, Any]:
        return await self._request("GET", f"/tasks/{task_id}", async_task=False, timeout=30.0)

    async def wait_for_task(self, task_id: str) -> dict[str, Any]:
        deadline = time.monotonic() + settings.QWEN_TASK_POLL_TIMEOUT_SEC
        interval = settings.QWEN_TASK_POLL_INTERVAL_SEC
        while time.monotonic() < deadline:
            data = await self.get_task(task_id)
            output = data.get("output") or {}
            status = output.get("task_status", "")
            if status in {"SUCCEEDED", "FAILED", "CANCELED", "UNKNOWN"}:
                if status == "FAILED":
                    raise BusinessException(
                        output.get("message") or output.get("code") or "千问任务执行失败",
                        502,
                    )
                if status in {"CANCELED", "UNKNOWN"}:
                    raise BusinessException(f"千问任务状态异常: {status}", 502)
                return data
            await asyncio.sleep(interval)
        raise BusinessException(
            f"任务处理超时（>{settings.QWEN_TASK_POLL_TIMEOUT_SEC}s），请稍后使用 task_id 查询",
            504,
        )


def extract_task_brief(data: dict[str, Any]) -> dict[str, Any]:
    output = data.get("output") or {}
    images = [
        item["url"]
        for item in output.get("results", [])
        if isinstance(item, dict) and item.get("url")
    ]
    return {
        "task_id": output.get("task_id"),
        "task_status": output.get("task_status"),
        "images": images or None,
        "video_url": output.get("video_url") or None,
        "request_id": data.get("request_id"),
    }
