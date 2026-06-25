"""启动时确保 companion_roles 表有基础种子数据。"""

from __future__ import annotations

from sqlalchemy import select

from app.core.companion_roles import COMPANION_ROLE_SEEDS
from app.database.database import AsyncSessionLocal
from app.models.companion_role import CompanionRole


async def ensure_companion_roles_seeded() -> None:
    async with AsyncSessionLocal() as session:
        for item in COMPANION_ROLE_SEEDS:
            role_id = str(item["id"])
            existing = await session.scalar(
                select(CompanionRole).where(CompanionRole.id == role_id)
            )
            if existing is None:
                session.add(
                    CompanionRole(
                        id=role_id,
                        display_name=str(item["display_name"]),
                        render_key=str(item["render_key"]),
                        is_active=bool(item["is_active"]),
                        sort_order=int(item["sort_order"]),
                    )
                )
                continue
            existing.display_name = str(item["display_name"])
            existing.render_key = str(item["render_key"])
            existing.is_active = bool(item["is_active"])
            existing.sort_order = int(item["sort_order"])
        await session.commit()
