import time
from fastapi import Request
from loguru import logger
from starlette.middleware.base import BaseHTTPMiddleware
class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        started_at = time.perf_counter()
        response = await call_next(request)
        cost_ms = (time.perf_counter() - started_at) * 1000
        logger.info("{} {} -> {} ({:.2f} ms)", request.method, request.url.path, response.status_code, cost_ms)
        return response
