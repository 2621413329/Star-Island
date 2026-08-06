from pydantic import BaseModel, Field


class AppVersionPolicy(BaseModel):
    platform: str = Field(description="平台标识，当前仅支持 ios")
    latest_version: str = Field(description="最新商店版本（营销版本号）")
    min_supported_version: str = Field(description="最低可用版本；低于此版本需强制更新")
    title: str
    message: str
    store_url: str = Field(description="App Store 产品页链接")
    apple_app_id: int
