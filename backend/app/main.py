from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text
from starlette import status
from starlette.responses import FileResponse, JSONResponse, RedirectResponse

from app.api.v1.api import api_router
from app.core.config import settings
from app.database.database import AsyncSessionLocal
from app.core.logging import setup_logging
from app.core.redis import close_redis, init_redis
from app.exceptions.handlers import register_exception_handlers
from app.middleware.logging import RequestLoggingMiddleware

setup_logging()

_LEGAL_STATIC_DIR = Path(__file__).resolve().parent / "static" / "legal"


@asynccontextmanager
async def lifespan(_: FastAPI):
    if settings.RATE_LIMIT_ENABLED:
        await init_redis()
    yield
    if settings.RATE_LIMIT_ENABLED:
        await close_redis()


app = FastAPI(
    title=settings.PROJECT_NAME,
    debug=settings.DEBUG,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    lifespan=lifespan,
)
if settings.DEBUG:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
app.add_middleware(RequestLoggingMiddleware)
register_exception_handlers(app)
app.include_router(api_router)

_user_media_root = settings.user_media_root_path
_user_media_root.mkdir(parents=True, exist_ok=True)
app.mount("/media/users", StaticFiles(directory=str(_user_media_root)), name="user_media")


@app.get("/legal", include_in_schema=False)
async def legal_index_redirect():
    return RedirectResponse(url="/legal/", status_code=status.HTTP_307_TEMPORARY_REDIRECT)


@app.get("/legal/terms", include_in_schema=False)
async def legal_terms_alias():
    return FileResponse(_LEGAL_STATIC_DIR / "terms.html")


@app.get("/legal/privacy", include_in_schema=False)
async def legal_privacy_alias():
    return FileResponse(_LEGAL_STATIC_DIR / "privacy.html")


app.mount(
    "/legal",
    StaticFiles(directory=str(_LEGAL_STATIC_DIR), html=True),
    name="legal_docs",
)


@app.get("/health", tags=["系统"])
async def health_check():
    try:
        async with AsyncSessionLocal() as session:
            await session.execute(text("SELECT 1"))
    except Exception:
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={"code": 503, "message": "database unavailable", "data": {"status": "error"}},
        )
    return {"code": 200, "message": "success", "data": {"status": "ok"}}


@app.get("/health/media", tags=["系统"])
async def media_health_check():
    marker = _user_media_root / ".write_check"
    writable = True
    try:
        marker.write_text("ok", encoding="utf-8")
        marker.unlink(missing_ok=True)
    except Exception:
        writable = False
    return {
        "code": 200,
        "message": "success",
        "data": {
            "media_root": str(_user_media_root),
            "exists": _user_media_root.exists(),
            "writable": writable,
            "mount": "/media/users",
        },
    }
