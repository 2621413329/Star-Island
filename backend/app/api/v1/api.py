from fastapi import APIRouter
from app.api.v1.endpoints import auth, growth_tags, island_styles, profile

api_router = APIRouter(prefix="/api/v1")
api_router.include_router(auth.router)
api_router.include_router(profile.router)
api_router.include_router(island_styles.router)
api_router.include_router(growth_tags.router)
api_router.include_router(growth_tags.admin_router)
