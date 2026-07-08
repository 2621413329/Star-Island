from typing import Annotated
import uuid

from fastapi import APIRouter, Depends, Query

from app.api.deps import DBSession, get_current_admin, get_current_user
from app.models.user import User
from app.repositories.activation_code_repository import ActivationCodeRepository
from app.repositories.member_product_repository import MemberProductRepository
from app.repositories.member_record_repository import MemberRecordRepository
from app.repositories.user_membership_repository import UserMembershipRepository
from app.repositories.user_repository import UserRepository
from app.schemas.common import ResponseModel
from app.schemas.member import (
    ActivationCodeBatchCreateRequest,
    ActivationCodeCreateRequest,
    ActivationCodeDetailRead,
    ActivationCodeRead,
    MemberCancelRequest,
    MemberGiftRequest,
    MemberMeResponse,
    MemberRecordRead,
    MemberRedeemRequest,
)
from app.services.activation_code_service import ActivationCodeService
from app.services.member_service import MemberService
from app.services.permission_service import PermissionService

router = APIRouter(prefix="/member", tags=["会员中心"])
admin_router = APIRouter(prefix="/admin/member", tags=["会员中心管理"])


def get_member_service(db: DBSession) -> MemberService:
    return MemberService(
        product_repo=MemberProductRepository(db),
        record_repo=MemberRecordRepository(db),
        membership_repo=UserMembershipRepository(db),
        user_repo=UserRepository(db),
    )


def get_activation_code_service(db: DBSession) -> ActivationCodeService:
    member_service = get_member_service(db)
    return ActivationCodeService(
        code_repo=ActivationCodeRepository(db),
        member_service=member_service,
    )


def get_permission_service(db: DBSession) -> PermissionService:
    member_service = get_member_service(db)
    return PermissionService(
        membership_repo=UserMembershipRepository(db),
        member_service=member_service,
    )


MemberServiceDep = Annotated[MemberService, Depends(get_member_service)]
ActivationCodeServiceDep = Annotated[ActivationCodeService, Depends(get_activation_code_service)]


@router.get("/me", response_model=ResponseModel[MemberMeResponse])
async def get_member_me(
    service: MemberServiceDep,
    current_user: User = Depends(get_current_user),
):
    snapshot = await service.get_member_me(current_user.id)
    return ResponseModel(data=MemberMeResponse.from_snapshot(snapshot))


@router.post("/redeem", response_model=ResponseModel[MemberMeResponse])
async def redeem_activation_code(
    payload: MemberRedeemRequest,
    service: MemberServiceDep,
    activation_service: ActivationCodeServiceDep,
    current_user: User = Depends(get_current_user),
):
    membership = await activation_service.redeem_code(current_user.id, payload.code)
    snapshot = service.to_member_me_snapshot(membership)
    return ResponseModel(data=MemberMeResponse.from_snapshot(snapshot))


@admin_router.post("/activation-codes", response_model=ResponseModel[ActivationCodeRead])
async def create_activation_code(
    payload: ActivationCodeCreateRequest,
    activation_service: ActivationCodeServiceDep,
    _: User = Depends(get_current_admin),
):
    result = await activation_service.generate_code(
        membership_type=payload.membership_type,
        duration_days=payload.duration_days,
        batch_no=payload.batch_no,
        remark=payload.remark,
        code_expire_time=payload.code_expire_time,
        code_length=payload.code_length,
        reusable=payload.reusable,
    )
    return ResponseModel(data=ActivationCodeRead.from_result(result))


@admin_router.post("/activation-codes/batch", response_model=ResponseModel[list[ActivationCodeRead]])
async def batch_create_activation_codes(
    payload: ActivationCodeBatchCreateRequest,
    activation_service: ActivationCodeServiceDep,
    _: User = Depends(get_current_admin),
):
    results = await activation_service.generate_batch(
        count=payload.count,
        membership_type=payload.membership_type,
        duration_days=payload.duration_days,
        batch_no=payload.batch_no,
        remark=payload.remark,
        code_expire_time=payload.code_expire_time,
        code_length=payload.code_length,
        reusable=payload.reusable,
    )
    return ResponseModel(data=[ActivationCodeRead.from_result(item) for item in results])


@admin_router.patch("/activation-codes/{code_id}/disable", response_model=ResponseModel[ActivationCodeDetailRead])
async def disable_activation_code(
    code_id: uuid.UUID,
    activation_service: ActivationCodeServiceDep,
    _: User = Depends(get_current_admin),
):
    row = await activation_service.disable_code(code_id)
    return ResponseModel(data=ActivationCodeDetailRead.model_validate(row))


@admin_router.patch("/activation-codes/{code_id}/expire", response_model=ResponseModel[ActivationCodeDetailRead])
async def expire_activation_code(
    code_id: uuid.UUID,
    activation_service: ActivationCodeServiceDep,
    _: User = Depends(get_current_admin),
):
    row = await activation_service.expire_code(code_id)
    return ResponseModel(data=ActivationCodeDetailRead.model_validate(row))


@admin_router.get("/activation-codes", response_model=ResponseModel[list[ActivationCodeDetailRead]])
async def list_activation_codes(
    db: DBSession,
    activation_service: ActivationCodeServiceDep,
    _: User = Depends(get_current_admin),
    status: str | None = Query(default=None),
    batch_no: str | None = Query(default=None),
):
    rows = await activation_service.list_codes(status=status, batch_no=batch_no)
    return ResponseModel(data=[ActivationCodeDetailRead.model_validate(row) for row in rows])


@admin_router.post("/gift", response_model=ResponseModel[MemberMeResponse])
async def gift_membership(
    payload: MemberGiftRequest,
    service: MemberServiceDep,
    current_admin: User = Depends(get_current_admin),
):
    membership = await service.gift_membership(
        user_id=payload.user_id,
        membership_type=payload.membership_type,
        duration_days=payload.duration_days,
        admin_id=current_admin.id,
        remark=payload.remark,
    )
    return ResponseModel(data=MemberMeResponse.from_snapshot(service.to_member_me_snapshot(membership)))


@admin_router.post("/cancel", response_model=ResponseModel[MemberMeResponse])
async def cancel_membership(
    payload: MemberCancelRequest,
    service: MemberServiceDep,
    current_admin: User = Depends(get_current_admin),
):
    membership = await service.cancel_membership(
        payload.user_id,
        admin_id=current_admin.id,
        remark=payload.remark,
    )
    return ResponseModel(data=MemberMeResponse.from_snapshot(service.to_member_me_snapshot(membership)))


@admin_router.get("/records", response_model=ResponseModel[list[MemberRecordRead]])
async def list_member_records(
    db: DBSession,
    _: User = Depends(get_current_admin),
    user_id: uuid.UUID | None = Query(default=None),
    source: str | None = Query(default=None),
):
    repo = MemberRecordRepository(db)
    rows = await repo.list_all(user_id=user_id, source=source)
    return ResponseModel(data=[MemberRecordRead.model_validate(row) for row in rows])
