from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.api import api_router
from app.core.config import settings
from app.core.logging import setup_logging
from app.exceptions.handlers import register_exception_handlers
from app.middleware.logging import RequestLoggingMiddleware

setup_logging()

app = FastAPI(title=settings.PROJECT_NAME, debug=settings.DEBUG, docs_url="/docs", redoc_url="/redoc")
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


@app.get("/health", tags=["系统"])
async def health_check():
    return {"code": 200, "message": "success", "data": {"status": "ok"}}
