"""用户故事照片：按用户/故事分目录存储，不参与 AI 分析。"""

from __future__ import annotations

import shutil
import uuid
from datetime import datetime, timezone
from pathlib import Path

from fastapi import UploadFile

from app.core.config import settings
from app.exceptions.business import BusinessException

ALLOWED_CONTENT_TYPES = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}
MAX_PHOTO_BYTES = 5 * 1024 * 1024
MAX_PHOTOS_PER_MOMENT = 6


class MomentPhotoService:
    def __init__(self, root: Path | None = None) -> None:
        self.root = (root or Path(settings.USER_MEDIA_ROOT)).resolve()

    def user_moments_root(self, user_id: uuid.UUID) -> Path:
        return self.root / str(user_id) / "moments"

    def moment_dir(self, user_id: uuid.UUID, moment_id: uuid.UUID) -> Path:
        return self.user_moments_root(user_id) / str(moment_id)

    @staticmethod
    def public_url_path(user_id: uuid.UUID, moment_id: uuid.UUID, filename: str) -> str:
        return f"/media/users/{user_id}/moments/{moment_id}/{filename}"

    async def save_upload(
        self,
        *,
        user_id: uuid.UUID,
        moment_id: uuid.UUID,
        upload: UploadFile,
        existing_count: int,
    ) -> dict:
        if existing_count >= MAX_PHOTOS_PER_MOMENT:
            raise BusinessException(f"每条故事最多上传 {MAX_PHOTOS_PER_MOMENT} 张照片", 400)

        content_type = (upload.content_type or "").split(";")[0].strip().lower()
        if content_type not in ALLOWED_CONTENT_TYPES:
            raise BusinessException("仅支持 JPG、PNG、WEBP 图片", 400)

        raw = await upload.read()
        if not raw:
            raise BusinessException("图片文件为空", 400)
        if len(raw) > MAX_PHOTO_BYTES:
            raise BusinessException("单张照片不能超过 5MB", 400)

        photo_id = str(uuid.uuid4())
        ext = ALLOWED_CONTENT_TYPES[content_type]
        filename = f"{photo_id}{ext}"
        target_dir = self.moment_dir(user_id, moment_id)
        target_dir.mkdir(parents=True, exist_ok=True)
        target_path = target_dir / filename
        target_path.write_bytes(raw)

        now = datetime.now(timezone.utc).isoformat()
        return {
            "id": photo_id,
            "filename": filename,
            "content_type": content_type,
            "size_bytes": len(raw),
            "url_path": self.public_url_path(user_id, moment_id, filename),
            "created_at": now,
        }

    def delete_photo_file(
        self,
        *,
        user_id: uuid.UUID,
        moment_id: uuid.UUID,
        filename: str,
    ) -> None:
        path = self.moment_dir(user_id, moment_id) / filename
        if path.is_file():
            path.unlink(missing_ok=True)

    def delete_moment_dir(self, user_id: uuid.UUID, moment_id: uuid.UUID) -> None:
        shutil.rmtree(self.moment_dir(user_id, moment_id), ignore_errors=True)
