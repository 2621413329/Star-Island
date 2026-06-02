from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from loguru import logger
from sqlalchemy.exc import SQLAlchemyError
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.exceptions.business import BusinessException


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(BusinessException)
    async def business_exception_handler(_: Request, exc: BusinessException) -> JSONResponse:
        return JSONResponse(status_code=exc.code, content={"code": exc.code, "message": exc.message, "data": None})

    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(_: Request, exc: StarletteHTTPException) -> JSONResponse:
        message = exc.detail if isinstance(exc.detail, str) else "请求处理失败"
        return JSONResponse(status_code=exc.status_code, content={"code": exc.status_code, "message": message, "data": None})

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(_: Request, exc: RequestValidationError) -> JSONResponse:
        return JSONResponse(status_code=422, content={"code": 422, "message": "参数校验失败", "data": exc.errors()})

    @app.exception_handler(SQLAlchemyError)
    async def sqlalchemy_exception_handler(_: Request, exc: SQLAlchemyError) -> JSONResponse:
        logger.exception("Database error: {}", exc)
        return JSONResponse(status_code=500, content={"code": 500, "message": "数据库操作失败", "data": None})

    @app.exception_handler(Exception)
    async def global_exception_handler(_: Request, exc: Exception) -> JSONResponse:
        logger.exception("Unhandled error: {}", exc)
        return JSONResponse(status_code=500, content={"code": 500, "message": "服务器内部错误", "data": None})
