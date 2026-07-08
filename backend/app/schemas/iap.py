from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.services.iap_service import IapAppleNotificationResult, IapEntitlementSnapshot, IapVerifyResult


class IapVerifyRequest(BaseModel):
    signed_transaction: str = Field(min_length=1)
    receipt: str | None = None


class IapRestoreRequest(BaseModel):
    signed_transactions: list[str] = Field(min_length=1)


class IapVerifyResponse(BaseModel):
    product_id: str
    transaction_id: str
    expire_time: datetime | None
    environment: str
    is_active: bool
    entitlement_status: str

    model_config = ConfigDict(from_attributes=True)

    @classmethod
    def from_result(cls, result: IapVerifyResult) -> "IapVerifyResponse":
        return cls.model_validate(result)


class IapEntitlementRead(BaseModel):
    entitlement: str
    status: str
    start_time: datetime
    end_time: datetime | None

    model_config = ConfigDict(from_attributes=True)

    @classmethod
    def from_snapshot(cls, snapshot: IapEntitlementSnapshot) -> "IapEntitlementRead":
        return cls.model_validate(snapshot)


class IapMeResponse(BaseModel):
    entitlements: list[IapEntitlementRead]


class IapRestoreResponse(BaseModel):
    entitlements: list[IapEntitlementRead]


class AppleNotificationRequest(BaseModel):
    signedPayload: str = Field(min_length=1)


class AppleNotificationResponse(BaseModel):
    notification_type: str
    notification_uuid: str | None = None
    product_id: str | None = None
    transaction_id: str | None = None
    entitlement_status: str | None = None
    skipped: bool = False
    skip_reason: str | None = None

    model_config = ConfigDict(from_attributes=True)

    @classmethod
    def from_result(cls, result: IapAppleNotificationResult) -> "AppleNotificationResponse":
        return cls.model_validate(result)
