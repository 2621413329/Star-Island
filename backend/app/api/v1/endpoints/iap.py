from typing import Annotated

from fastapi import APIRouter, Depends

from app.api.deps import DBSession, get_current_user
from app.models.user import User
from app.repositories.member_record_repository import MemberRecordRepository
from app.repositories.member_product_repository import MemberProductRepository
from app.repositories.user_membership_repository import UserMembershipRepository
from app.repositories.user_repository import UserRepository
from app.schemas.common import ResponseModel
from app.schemas.iap import (
    AppleNotificationRequest,
    AppleNotificationResponse,
    IapEntitlementRead,
    IapMeResponse,
    IapRestoreRequest,
    IapRestoreResponse,
    IapVerifyRequest,
    IapVerifyResponse,
)
from app.services.apple_service import AppleService
from app.services.iap_service import IapService
from app.services.member_service import MemberService

router = APIRouter(prefix="/iap", tags=["内购"])


def get_member_service(db: DBSession) -> MemberService:
    return MemberService(
        product_repo=MemberProductRepository(db),
        record_repo=MemberRecordRepository(db),
        membership_repo=UserMembershipRepository(db),
        user_repo=UserRepository(db),
    )


def get_iap_service(db: DBSession) -> IapService:
    return IapService(
        member_service=get_member_service(db),
        record_repo=MemberRecordRepository(db),
        apple_service=AppleService(),
        user_repo=UserRepository(db),
    )


IapServiceDep = Annotated[IapService, Depends(get_iap_service)]


@router.post("/verify", response_model=ResponseModel[IapVerifyResponse])
async def verify_purchase(
    payload: IapVerifyRequest,
    service: IapServiceDep,
    current_user: User = Depends(get_current_user),
):
    result = await service.process_verify(
        current_user.id,
        payload.signed_transaction,
        receipt=payload.receipt,
    )
    return ResponseModel(data=IapVerifyResponse.from_result(result))


@router.post("/restore", response_model=ResponseModel[IapRestoreResponse])
async def restore_purchases(
    payload: IapRestoreRequest,
    service: IapServiceDep,
    current_user: User = Depends(get_current_user),
):
    outcome = await service.process_restore(current_user.id, payload.signed_transactions)
    return ResponseModel(
        data=IapRestoreResponse(
            entitlements=[
                IapEntitlementRead.from_snapshot(item) for item in outcome.entitlements
            ],
            restored=outcome.restored,
            skipped=outcome.skipped,
        )
    )


@router.get("/me", response_model=ResponseModel[IapMeResponse])
async def get_my_entitlements(
    service: IapServiceDep,
    current_user: User = Depends(get_current_user),
):
    snapshots = await service.list_my_entitlements(current_user.id)
    return ResponseModel(
        data=IapMeResponse(
            entitlements=[IapEntitlementRead.from_snapshot(item) for item in snapshots]
        )
    )


@router.post("/apple/notification", response_model=ResponseModel[AppleNotificationResponse])
async def apple_server_notification(
    payload: AppleNotificationRequest,
    service: IapServiceDep,
):
    result = await service.process_apple_notification(payload.signedPayload)
    return ResponseModel(data=AppleNotificationResponse.from_result(result))
