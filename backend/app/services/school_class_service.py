from app.core.school_classes import CLASS_OPTIONS, DEFAULT_CLASS_NAME
from app.exceptions.business import BusinessException
from app.models.school_class import SchoolClass
from app.repositories.school_class_repository import SchoolClassRepository


class SchoolClassService:
    def __init__(self, repo: SchoolClassRepository):
        self.repo = repo

    async def list_active_names(self) -> list[str]:
        rows = await self.repo.list_active()
        if rows:
            return [row.name for row in rows]
        return list(CLASS_OPTIONS)

    async def default_class_name(self) -> str:
        rows = await self.repo.list_active()
        if rows:
            return rows[0].name
        return DEFAULT_CLASS_NAME

    async def resolve_active(self, class_name: str) -> SchoolClass:
        name = class_name.strip()
        if not name:
            raise BusinessException("请选择班级", 400)
        row = await self.repo.get_by_name(name)
        if not row or not row.is_active:
            active = await self.list_active_names()
            hint = "、".join(active) if active else DEFAULT_CLASS_NAME
            raise BusinessException(f"无效班级，请选择：{hint}", 400)
        return row
