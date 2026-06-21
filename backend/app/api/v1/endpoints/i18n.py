from fastapi import APIRouter, Depends, Query

from app.api.deps import DBSession, get_current_admin
from app.models.user import User
from app.repositories.i18n_string_repository import I18nStringRepository
from app.schemas.common import ResponseModel
from app.schemas.i18n import I18nConfigRead, I18nStringCreate, I18nStringRead, I18nStringUpdate
from app.services.i18n_service import I18nService

router = APIRouter(prefix="/i18n", tags=["国际化"])
admin_router = APIRouter(prefix="/admin/i18n", tags=["国际化管理"])


@router.get("/config", response_model=ResponseModel[I18nConfigRead])
async def get_i18n_config(db: DBSession):
    service = I18nService(I18nStringRepository(db))
    return ResponseModel(data=service.get_config())


@router.get("/bundle", response_model=ResponseModel[dict[str, str]])
async def get_i18n_bundle(
    db: DBSession,
    locale: str = Query(default="zh_CN", min_length=2, max_length=16),
):
    service = I18nService(I18nStringRepository(db))
    return ResponseModel(data=await service.get_bundle(locale))


@admin_router.get("/strings", response_model=ResponseModel[list[I18nStringRead]])
async def admin_list_strings(
    db: DBSession,
    _: User = Depends(get_current_admin),
    locale: str | None = Query(default=None),
):
    service = I18nService(I18nStringRepository(db))
    rows = await service.admin_list(locale=locale)
    return ResponseModel(data=rows)


@admin_router.post("/strings", response_model=ResponseModel[I18nStringRead])
async def admin_create_string(
    payload: I18nStringCreate,
    db: DBSession,
    _: User = Depends(get_current_admin),
):
    service = I18nService(I18nStringRepository(db))
    row = await service.admin_create(payload)
    return ResponseModel(data=row)


@admin_router.patch("/strings/{string_id}", response_model=ResponseModel[I18nStringRead])
async def admin_update_string(
    string_id: str,
    payload: I18nStringUpdate,
    db: DBSession,
    _: User = Depends(get_current_admin),
):
    service = I18nService(I18nStringRepository(db))
    row = await service.admin_update(string_id, payload)
    return ResponseModel(data=row)
