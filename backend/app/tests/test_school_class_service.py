import pytest

from app.exceptions.business import BusinessException
from app.models.school_class import SchoolClass
from app.repositories.school_class_repository import SchoolClassRepository
from app.services.school_class_service import SchoolClassService


class _Repo:
    def __init__(self, rows: list[SchoolClass]):
        self._rows = rows

    async def list_active(self) -> list[SchoolClass]:
        return [row for row in self._rows if row.is_active]

    async def get_by_name(self, name: str) -> SchoolClass | None:
        for row in self._rows:
            if row.name == name.strip():
                return row
        return None


def _row(name: str, *, active: bool = True) -> SchoolClass:
    return SchoolClass(name=name, is_active=active)


@pytest.mark.asyncio
async def test_resolve_active_class():
    svc = SchoolClassService(_Repo([_row("测试班")]))
    resolved = await svc.resolve_active("测试班")
    assert resolved.name == "测试班"


@pytest.mark.asyncio
async def test_resolve_rejects_unknown_class():
    svc = SchoolClassService(_Repo([_row("测试班")]))
    with pytest.raises(BusinessException):
        await svc.resolve_active("家人测试班")
