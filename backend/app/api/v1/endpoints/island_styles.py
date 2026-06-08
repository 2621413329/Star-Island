from fastapi import APIRouter, Depends

from app.api.deps import DBSession, get_current_admin, get_current_user
from app.models.user import User
from app.repositories.mood_island_repository import MoodIslandRepository
from app.schemas.common import ResponseModel
from app.schemas.mood_island import MoodIslandStyleRead, MoodIslandStyleUpdate

router = APIRouter(prefix="/profile/island-styles", tags=["心情岛屿样式"])


@router.get("", response_model=ResponseModel[list[MoodIslandStyleRead]])
async def list_island_styles(db: DBSession, _: User = Depends(get_current_user)):
    styles = await MoodIslandRepository(db).list_active()
    return ResponseModel(data=styles)


@router.get("/{mood_id}", response_model=ResponseModel[MoodIslandStyleRead])
async def get_island_style(mood_id: str, db: DBSession, _: User = Depends(get_current_user)):
    style = await MoodIslandRepository(db).get(mood_id)
    if not style or not style.is_active:
        from app.exceptions.business import BusinessException

        raise BusinessException("心情岛屿样式不存在", 404)
    return ResponseModel(data=style)


@router.patch("/{mood_id}", response_model=ResponseModel[MoodIslandStyleRead])
async def update_island_style(
    mood_id: str,
    payload: MoodIslandStyleUpdate,
    db: DBSession,
    _: User = Depends(get_current_admin),
):
    repo = MoodIslandRepository(db)
    style = await repo.get(mood_id)
    if not style:
        from app.exceptions.business import BusinessException

        raise BusinessException("心情岛屿样式不存在", 404)
    data = payload.model_dump(exclude_unset=True)
    for key, value in data.items():
        setattr(style, key, value)
    style = await repo.save(style)
    return ResponseModel(data=style)
