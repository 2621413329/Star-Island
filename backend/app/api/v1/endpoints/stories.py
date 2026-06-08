import uuid
from datetime import date

from fastapi import APIRouter, Depends, Query

from app.api.deps import DBSession, get_current_admin
from app.models.user import User
from app.repositories.observation_repository import ObservationRepository
from app.repositories.rule_repository import RuleRepository, StoryTemplateRepository
from app.repositories.story_repository import StoryRepository
from app.schemas.common import Pagination, ResponseModel
from app.schemas.story import StoryGenerateRequest, StoryRead, StoryTimelineItem
from app.services.story_service import StoryService

router = APIRouter(prefix="/story", tags=["成长故事"])
timeline_router = APIRouter(prefix="/timeline", tags=["成长时间线"])


def get_story_service(db: DBSession) -> StoryService:
    return StoryService(
        StoryRepository(db),
        ObservationRepository(db),
        RuleRepository(db),
        StoryTemplateRepository(db),
    )


@router.post("/generate", response_model=ResponseModel[StoryRead])
async def generate_story(payload: StoryGenerateRequest, db: DBSession, current_user: User = Depends(get_current_admin)):
    story = await get_story_service(db).generate(payload, current_user.id)
    return ResponseModel(data=story)


@router.get("/daily", response_model=ResponseModel[list[StoryRead]])
async def get_daily_story(
    student_id: uuid.UUID,
    db: DBSession,
    _: User = Depends(get_current_admin),
    target_date: date | None = None,
):
    stories = await get_story_service(db).list_daily(student_id, target_date)
    return ResponseModel(data=stories)


@router.get("/week", response_model=ResponseModel[list[StoryRead]])
async def get_week_story(
    student_id: uuid.UUID,
    db: DBSession,
    _: User = Depends(get_current_admin),
    target_date: date | None = None,
):
    stories = await get_story_service(db).list_week(student_id, target_date)
    return ResponseModel(data=stories)


@router.get("/{story_id}", response_model=ResponseModel[StoryRead])
async def get_story(story_id: uuid.UUID, db: DBSession, _: User = Depends(get_current_admin)):
    story = await get_story_service(db).get(story_id)
    return ResponseModel(data=story)


@timeline_router.get("", response_model=ResponseModel[Pagination])
async def get_timeline(
    db: DBSession,
    _: User = Depends(get_current_admin),
    student_id: uuid.UUID | None = None,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
):
    observation_repo = ObservationRepository(db)
    story_service = get_story_service(db)
    fetch_size = page * page_size
    total_records, observations = await observation_repo.list(page=1, page_size=fetch_size, student_id=student_id)
    total_stories, stories = await story_service.list(page=1, page_size=fetch_size, student_id=student_id)
    items = [
        StoryTimelineItem(
            type="record",
            id=record.id,
            student_id=record.student_id,
            title=record.event_title,
            content=record.event_content,
            occurred_at=record.created_at,
        )
        for record in observations
    ] + [
        StoryTimelineItem(
            type="story",
            id=story.id,
            student_id=story.student_id,
            title=story.title,
            content=story.body,
            occurred_at=story.created_at,
        )
        for story in stories
    ]
    items = sorted(items, key=lambda item: item.occurred_at, reverse=True)
    start = (page - 1) * page_size
    paged_items = items[start : start + page_size]
    return ResponseModel(data=Pagination(total=total_records + total_stories, page=page, page_size=page_size, items=paged_items))
