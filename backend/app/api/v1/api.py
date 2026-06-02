from fastapi import APIRouter
from app.api.v1.endpoints import ai, auth, island_styles, observations, profile, records, rules, stories, students
api_router = APIRouter(prefix="/api/v1")
api_router.include_router(ai.router)
api_router.include_router(auth.router)
api_router.include_router(profile.router)
api_router.include_router(island_styles.router)
api_router.include_router(rules.router)
api_router.include_router(records.router)
api_router.include_router(stories.router)
api_router.include_router(stories.timeline_router)
api_router.include_router(students.router)
api_router.include_router(observations.router)
