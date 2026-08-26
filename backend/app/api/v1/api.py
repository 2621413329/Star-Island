from fastapi import APIRouter
from app.api.v1.endpoints import (
    app_version,
    auth,
    growth_tags,
    i18n,
    iap,
    island_styles,
    member,
    profile,
)

api_router = APIRouter(prefix="/api/v1")
api_router.include_router(app_version.router)
api_router.include_router(auth.router)
api_router.include_router(profile.router)
api_router.include_router(island_styles.router)
api_router.include_router(growth_tags.router)
api_router.include_router(growth_tags.admin_router)
api_router.include_router(i18n.router)
api_router.include_router(i18n.admin_router)
api_router.include_router(iap.router)
api_router.include_router(member.router)
api_router.include_router(member.admin_router)
