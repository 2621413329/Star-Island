from fastapi import APIRouter, Depends

from app.api.deps import DBSession, get_current_admin, get_current_user
from app.exceptions.business import BusinessException
from app.models.user import User
from app.repositories.growth_tag_repository import GrowthTagRepository
from app.schemas.common import ResponseModel
from app.schemas.growth_tag import (
    GrowthTagCategoryCreate,
    GrowthTagCategoryRead,
    GrowthTagCategoryUpdate,
    GrowthTagCreate,
    GrowthTagRead,
    GrowthTagUpdate,
)
from app.models.growth_tag import GrowthTag, GrowthTagCategory

router = APIRouter(prefix="/growth-tags", tags=["成长标签"])
admin_router = APIRouter(prefix="/admin/growth-tags", tags=["成长标签管理"])


@router.get("", response_model=ResponseModel[list[GrowthTagCategoryRead]])
async def list_growth_tags(db: DBSession, _: User = Depends(get_current_user)):
    categories = await GrowthTagRepository(db).list_categories(active_only=True)
    return ResponseModel(data=categories)


@admin_router.get("", response_model=ResponseModel[list[GrowthTagCategoryRead]])
async def admin_list_growth_tags(db: DBSession, _: User = Depends(get_current_admin)):
    categories = await GrowthTagRepository(db).list_categories(active_only=False)
    return ResponseModel(data=categories)


@admin_router.post("/categories", response_model=ResponseModel[GrowthTagCategoryRead])
async def create_category(
    payload: GrowthTagCategoryCreate,
    db: DBSession,
    _: User = Depends(get_current_admin),
):
    repo = GrowthTagRepository(db)
    if await repo.get_category(payload.id):
        raise BusinessException("一级标签 ID 已存在", 400)
    category = GrowthTagCategory(
        id=payload.id,
        label=payload.label,
        icon=payload.icon,
        color=payload.color,
        sort_order=payload.sort_order,
        is_active=payload.is_active,
    )
    saved = await repo.save_category(category)
    saved.tags = []
    return ResponseModel(data=saved)


@admin_router.patch(
    "/categories/{category_id}",
    response_model=ResponseModel[GrowthTagCategoryRead],
)
async def update_category(
    category_id: str,
    payload: GrowthTagCategoryUpdate,
    db: DBSession,
    _: User = Depends(get_current_admin),
):
    repo = GrowthTagRepository(db)
    category = await repo.get_category(category_id)
    if not category:
        raise BusinessException("一级标签不存在", 404)
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(category, key, value)
    saved = await repo.save_category(category)
    return ResponseModel(data=saved)


@admin_router.post(
    "/categories/{category_id}/tags",
    response_model=ResponseModel[GrowthTagRead],
)
async def create_tag(
    category_id: str,
    payload: GrowthTagCreate,
    db: DBSession,
    _: User = Depends(get_current_admin),
):
    repo = GrowthTagRepository(db)
    category = await repo.get_category(category_id)
    if not category:
        raise BusinessException("一级标签不存在", 404)
    tag_id = repo.slug_tag_id(category_id, payload.label)
    if await repo.get_tag(tag_id):
        raise BusinessException("二级标签已存在", 400)
    tag = GrowthTag(
        id=tag_id,
        category_id=category_id,
        label=payload.label,
        sort_order=payload.sort_order,
        is_active=payload.is_active,
    )
    saved = await repo.save_tag(tag)
    return ResponseModel(data=saved)


@admin_router.patch("/tags/{tag_id}", response_model=ResponseModel[GrowthTagRead])
async def update_tag(
    tag_id: str,
    payload: GrowthTagUpdate,
    db: DBSession,
    _: User = Depends(get_current_admin),
):
    repo = GrowthTagRepository(db)
    tag = await repo.get_tag(tag_id)
    if not tag:
        raise BusinessException("二级标签不存在", 404)
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(tag, key, value)
    saved = await repo.save_tag(tag)
    return ResponseModel(data=saved)


@admin_router.delete("/tags/{tag_id}", response_model=ResponseModel[dict])
async def delete_tag(
    tag_id: str,
    db: DBSession,
    _: User = Depends(get_current_admin),
):
    repo = GrowthTagRepository(db)
    tag = await repo.get_tag(tag_id)
    if not tag:
        raise BusinessException("二级标签不存在", 404)
    await repo.delete_tag(tag)
    return ResponseModel(data={"deleted": True})
