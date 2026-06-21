"""多语言文案仓储。"""

import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.i18n_string import I18nString


class I18nStringRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def list_active_by_locale(self, locale: str) -> list[I18nString]:
        result = await self.db.execute(
            select(I18nString)
            .where(I18nString.locale == locale, I18nString.status == "active")
            .order_by(I18nString.key)
        )
        return list(result.scalars().all())

    async def list_all(self, *, locale: str | None = None) -> list[I18nString]:
        stmt = select(I18nString).order_by(I18nString.key, I18nString.locale)
        if locale:
            stmt = stmt.where(I18nString.locale == locale)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_key_locale(self, key: str, locale: str) -> I18nString | None:
        result = await self.db.execute(
            select(I18nString).where(
                I18nString.key == key,
                I18nString.locale == locale,
            )
        )
        return result.scalar_one_or_none()

    async def get_by_id(self, string_id: uuid.UUID) -> I18nString | None:
        result = await self.db.execute(
            select(I18nString).where(I18nString.id == string_id)
        )
        return result.scalar_one_or_none()

    async def save(self, row: I18nString) -> I18nString:
        self.db.add(row)
        await self.db.flush()
        await self.db.refresh(row)
        return row

    async def delete(self, row: I18nString) -> None:
        await self.db.delete(row)
