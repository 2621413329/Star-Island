"""用户故事语音：按 voices/年/月 分目录存储，数据库仅存 URL 元数据。"""

from __future__ import annotations

import uuid
from datetime import date, datetime, timezone
from pathlib import Path

from fastapi import UploadFile

from app.core.config import settings
from app.exceptions.business import BusinessException

ALLOWED_VOICE_CONTENT_TYPES = {
    "audio/mp4": ".m4a",
    "audio/x-m4a": ".m4a",
    "audio/m4a": ".m4a",
    "audio/aac": ".m4a",
    "audio/mpeg": ".m4a",
    "application/octet-stream": ".m4a",
}
MAX_VOICE_BYTES = 15 * 1024 * 1024
MAX_VOICE_DURATION_SEC = 120


class MomentVoiceService:
    def __init__(self, root: Path | None = None) -> None:
        self.root = (root or Path(settings.USER_MEDIA_ROOT)).resolve()

    def voice_dir(self, user_id: uuid.UUID, *, on_date: date | None = None) -> Path:
        day = on_date or date.today()
        return (
            self.root
            / str(user_id)
            / "voices"
            / str(day.year)
            / f"{day.month:02d}"
        )

    @staticmethod
    public_url_path(
        user_id: uuid.UUID, *, on_date: date, filename: str
    ) -> str:
        return (
            f"/media/users/{user_id}/voices/{on_date.year}/"
            f"{on_date.month:02d}/{filename}"
        )

    def resolve_file_path(self, voice_url: str) -> Path | None:
        prefix = "/media/users/"
        if not voice_url.startswith(prefix):
            return None
        rel = voice_url[len(prefix) :]
        path = (self.root / rel).resolve()
        if not str(path).startswith(str(self.root)):
            return None
        return path

    async def save_upload(
        self,
        *,
        user_id: uuid.UUID,
        upload: UploadFile,
        voice_duration: int,
        on_date: date | None = None,
    ) -> dict:
        if voice_duration <= 0:
            raise BusinessException("录音时长无效", 400)
        if voice_duration > MAX_VOICE_DURATION_SEC:
            raise BusinessException(
                f"单条语音不能超过 {MAX_VOICE_DURATION_SEC} 秒", 400
            )

        content_type = (upload.content_type or "").split(";")[0].strip().lower()
        if content_type not in ALLOWED_VOICE_CONTENT_TYPES:
            raise BusinessException("仅支持 m4a 格式语音", 400)

        raw = await upload.read()
        if not raw:
            raise BusinessException("语音文件为空", 400)
        if len(raw) > MAX_VOICE_BYTES:
            raise BusinessException("单条语音不能超过 15MB", 400)

        day = on_date or date.today()
        voice_id = str(uuid.uuid4())
        ext = ALLOWED_VOICE_CONTENT_TYPES[content_type]
        filename = f"{voice_id}{ext}"
        target_dir = self.voice_dir(user_id, on_date=day)
        target_dir.mkdir(parents=True, exist_ok=True)
        target_path = target_dir / filename
        target_path.write_bytes(raw)

        now = datetime.now(timezone.utc).isoformat()
        url_path = self.public_url_path(user_id, on_date=day, filename=filename)
        return {
            "voice_id": voice_id,
            "filename": filename,
            "content_type": content_type,
            "size_bytes": len(raw),
            "url_path": url_path,
            "file_path": str(target_path),
            "voice_duration": voice_duration,
            "created_at": now,
        }

    def delete_voice_file(self, voice_url: str | None) -> None:
        if not voice_url:
            return
        path = self.resolve_file_path(voice_url)
        if path and path.is_file():
            path.unlink(missing_ok=True)
