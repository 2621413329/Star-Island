import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.services.activation_code_service import ActivationCodeCreateResult
from app.services.member_service import MemberMeSnapshot


class MemberMeResponse(BaseModel):
    is_vip: bool
    membership_type: str | None = None
    expire_time: datetime | None = None
    source: str | None = None

    model_config = ConfigDict(from_attributes=True)

    @classmethod
    def from_snapshot(cls, snapshot: MemberMeSnapshot) -> "MemberMeResponse":
        return cls.model_validate(snapshot)


class MemberRedeemRequest(BaseModel):
    code: str = Field(min_length=4, max_length=64)


class ActivationCodeCreateRequest(BaseModel):
    membership_type: str
    duration_days: int | None = None
    batch_no: str | None = None
    remark: str | None = None
    code_expire_time: datetime | None = None
    code_length: int = Field(default=12, ge=8, le=24)


class ActivationCodeBatchCreateRequest(BaseModel):
    count: int = Field(ge=1, le=1000)
    membership_type: str
    duration_days: int | None = None
    batch_no: str | None = None
    remark: str | None = None
    code_expire_time: datetime | None = None
    code_length: int = Field(default=12, ge=8, le=24)


class ActivationCodeRead(BaseModel):
    id: uuid.UUID
    code: str
    membership_type: str
    duration_days: int | None
    status: str
    batch_no: str | None = None
    expire_time: datetime | None = None

    model_config = ConfigDict(from_attributes=True)

    @classmethod
    def from_result(cls, result: ActivationCodeCreateResult) -> "ActivationCodeRead":
        return cls.model_validate(result)


class ActivationCodeDetailRead(ActivationCodeRead):
    user_id: uuid.UUID | None = None
    used_time: datetime | None = None
    remark: str | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class MemberGiftRequest(BaseModel):
    user_id: uuid.UUID
    membership_type: str
    duration_days: int | None = None
    remark: str | None = None


class MemberCancelRequest(BaseModel):
    user_id: uuid.UUID
    remark: str | None = None


class MemberRecordRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    product_id: uuid.UUID | None
    source: str
    transaction_id: str | None
    original_transaction_id: str | None
    activation_code_id: uuid.UUID | None
    admin_id: uuid.UUID | None
    membership_type: str
    start_time: datetime
    end_time: datetime | None
    status: str
    remark: str | None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
