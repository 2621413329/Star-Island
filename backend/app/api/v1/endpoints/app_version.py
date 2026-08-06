from fastapi import APIRouter, Query

from app.core.config import settings
from app.exceptions.business import BusinessException
from app.schemas.app_version import AppVersionPolicy
from app.schemas.common import ResponseModel

router = APIRouter(prefix="/app", tags=["应用"])


@router.get("/version", response_model=ResponseModel[AppVersionPolicy])
async def get_app_version_policy(
    platform: str = Query(default="ios", description="平台：ios"),
):
    """客户端启动时拉取版本策略（无需登录）。当前仅支持 iOS 强制更新。"""
    normalized = platform.strip().lower()
    if normalized != "ios":
        raise BusinessException("暂不支持该平台的版本策略", 400)

    app_id = settings.APPLE_APP_ID or 6782086773
    return ResponseModel(
        data=AppVersionPolicy(
            platform="ios",
            latest_version=settings.IOS_LATEST_VERSION.strip(),
            min_supported_version=settings.IOS_MIN_SUPPORTED_VERSION.strip(),
            title=settings.IOS_FORCE_UPDATE_TITLE,
            message=settings.IOS_FORCE_UPDATE_MESSAGE,
            store_url=settings.ios_app_store_url,
            apple_app_id=app_id,
        )
    )
