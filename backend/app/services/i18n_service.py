"""多语言文案服务。"""

import uuid

from app.core.config import settings
from app.exceptions.business import BusinessException
from app.models.i18n_string import I18nString
from app.repositories.i18n_string_repository import I18nStringRepository
from app.schemas.i18n import I18nStringCreate, I18nStringUpdate

SUPPORTED_LANGUAGES = ["zh_CN", "zh_TW", "en_US", "ja_JP", "ko_KR"]

FALLBACK_CHAIN = {
    "zh_TW": ["zh_CN"],
    "en_US": ["zh_CN"],
    "ja_JP": ["en_US", "zh_CN"],
    "ko_KR": ["en_US", "zh_CN"],
}


class I18nService:
    def __init__(self, repo: I18nStringRepository) -> None:
        self.repo = repo

    def get_config(self) -> dict:
        return {
            "default_language": settings.DEFAULT_LANGUAGE,
            "supported_languages": SUPPORTED_LANGUAGES,
        }

    async def get_bundle(self, locale: str) -> dict[str, str]:
        bundle: dict[str, str] = {}
        for tag in _fallback_tags(locale):
            rows = await self.repo.list_active_by_locale(tag)
            for row in rows:
                bundle.setdefault(row.key, row.value)
        return bundle

    async def admin_list(self, locale: str | None = None) -> list[I18nString]:
        return await self.repo.list_all(locale=locale)

    async def admin_create(self, payload: I18nStringCreate) -> I18nString:
        existing = await self.repo.get_by_key_locale(payload.key, payload.locale)
        if existing:
            raise BusinessException("该 key 在此语言下已存在", 400)
        row = I18nString(
            key=payload.key,
            locale=payload.locale,
            value=payload.value,
            status=payload.status,
        )
        return await self.repo.save(row)

    async def admin_update(
        self, string_id: str, payload: I18nStringUpdate
    ) -> I18nString:
        try:
            row_id = uuid.UUID(string_id)
        except ValueError as exc:
            raise BusinessException("文案 ID 无效", 400) from exc
        row = await self.repo.get_by_id(row_id)
        if not row:
            raise BusinessException("文案不存在", 404)
        if payload.value is not None:
            row.value = payload.value
        if payload.status is not None:
            row.status = payload.status
        return await self.repo.save(row)


def _fallback_tags(locale: str) -> list[str]:
    tags = [locale]
    tags.extend(FALLBACK_CHAIN.get(locale, ["zh_CN"]))
    if "zh_CN" not in tags:
        tags.append("zh_CN")
    seen: set[str] = set()
    ordered: list[str] = []
    for tag in tags:
        if tag in seen:
            continue
        seen.add(tag)
        ordered.append(tag)
    return ordered
