import uuid

from fastapi import APIRouter, Depends, Query

from app.api.deps import DBSession, get_current_admin
from app.models.user import User
from app.repositories.rule_repository import RuleRepository
from app.schemas.common import Pagination, ResponseModel
from app.schemas.rule import StoryRuleCreate, StoryRuleRead, StoryRuleUpdate
from app.services.rule_service import RuleService

router = APIRouter(prefix="/rules", tags=["规则系统"])


@router.post("/create", response_model=ResponseModel[StoryRuleRead])
async def create_rule(payload: StoryRuleCreate, db: DBSession, current_user: User = Depends(get_current_admin)):
    rule = await RuleService(RuleRepository(db)).create(payload, current_user.id)
    return ResponseModel(data=rule)


@router.get("/list", response_model=ResponseModel[Pagination])
async def list_rules(
    db: DBSession,
    _: User = Depends(get_current_admin),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    active_only: bool = False,
):
    total, items = await RuleService(RuleRepository(db)).list(page, page_size, active_only)
    return ResponseModel(data=Pagination(total=total, page=page, page_size=page_size, items=items))


@router.put("/{rule_id}", response_model=ResponseModel[StoryRuleRead])
async def update_rule(rule_id: uuid.UUID, payload: StoryRuleUpdate, db: DBSession, _: User = Depends(get_current_admin)):
    rule = await RuleService(RuleRepository(db)).update(rule_id, payload)
    return ResponseModel(data=rule)
