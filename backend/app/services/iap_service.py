"""iOS 内购接入层：验签后写入 member_records，统一走 MemberService。"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import datetime, timezone

from app.core.member_constants import (
    SUPPORTED_APPLE_NOTIFICATION_TYPES,
    MemberRecordStatus,
    MemberSource,
    MembershipStatus,
)
from app.exceptions.business import BusinessException
from app.models.member import UserMembership
from app.repositories.member_record_repository import MemberRecordRepository
from app.repositories.user_repository import UserRepository
from app.services.apple_service import AppleService, AppleTransactionInfo
from app.services.member_service import MemberRecordInput, MemberService


@dataclass(frozen=True)
class IapVerifiedPurchase:
    product_id: str
    transaction_id: str
    original_transaction_id: str
    purchase_date: datetime
    expire_time: datetime | None
    environment: str
    is_active: bool
    receipt: str | None = None


@dataclass(frozen=True)
class IapVerifyResult:
    product_id: str
    transaction_id: str
    expire_time: datetime | None
    environment: str
    is_active: bool
    entitlement_status: str


@dataclass(frozen=True)
class IapEntitlementSnapshot:
    entitlement: str
    status: str
    start_time: datetime
    end_time: datetime | None


@dataclass(frozen=True)
class IapAppleNotificationResult:
    notification_type: str
    notification_uuid: str | None
    product_id: str | None
    transaction_id: str | None
    entitlement_status: str | None
    skipped: bool = False
    skip_reason: str | None = None


class IapService:
    def __init__(
        self,
        member_service: MemberService,
        record_repo: MemberRecordRepository,
        apple_service: AppleService,
        *,
        user_repo: UserRepository | None = None,
    ) -> None:
        self.member_service = member_service
        self.record_repo = record_repo
        self.apple_service = apple_service
        self.user_repo = user_repo

    async def verify_purchase(
        self,
        user_id: uuid.UUID,
        signed_transaction: str,
        *,
        receipt: str | None = None,
    ) -> IapVerifiedPurchase:
        await self._ensure_user_exists(user_id)
        transaction = self.apple_service.verify_and_parse_transaction(signed_transaction)
        await self.member_service.get_apple_product(transaction.product_id)

        existing = await self.record_repo.get_by_transaction_id(transaction.transaction_id)
        if existing is not None and existing.user_id != user_id:
            raise BusinessException("交易已绑定其他用户", 409)

        return self._to_verified_purchase(transaction, receipt=receipt)

    async def process_verify(
        self,
        user_id: uuid.UUID,
        signed_transaction: str,
        *,
        receipt: str | None = None,
    ) -> IapVerifyResult:
        verified = await self.verify_purchase(user_id, signed_transaction, receipt=receipt)
        membership = await self._sync_apple_record(user_id, verified)
        return IapVerifyResult(
            product_id=verified.product_id,
            transaction_id=verified.transaction_id,
            expire_time=verified.expire_time,
            environment=verified.environment,
            is_active=verified.is_active,
            entitlement_status=membership.status,
        )

    async def process_restore(
        self,
        user_id: uuid.UUID,
        signed_transactions: list[str],
    ) -> list[IapEntitlementSnapshot]:
        for signed_transaction in signed_transactions:
            try:
                verified = await self.verify_purchase(user_id, signed_transaction)
                await self._sync_apple_record(user_id, verified)
            except BusinessException:
                continue

        membership = await self.member_service.refresh_user_membership(user_id)
        return [self._to_entitlement_snapshot(membership)]

    async def process_apple_notification(self, signed_payload: str) -> IapAppleNotificationResult:
        notification = self.apple_service.verify_and_parse_notification(signed_payload)
        if notification.notification_type not in SUPPORTED_APPLE_NOTIFICATION_TYPES:
            return IapAppleNotificationResult(
                notification_type=notification.notification_type,
                notification_uuid=notification.notification_uuid,
                product_id=None,
                transaction_id=None,
                entitlement_status=None,
                skipped=True,
                skip_reason="unsupported_notification_type",
            )

        transaction = notification.transaction
        if transaction is None:
            raise BusinessException("通知缺少交易信息", 400)

        user_id = await self._resolve_user_id_for_transaction(transaction)
        if user_id is None:
            return IapAppleNotificationResult(
                notification_type=notification.notification_type,
                notification_uuid=notification.notification_uuid,
                product_id=transaction.product_id,
                transaction_id=transaction.transaction_id,
                entitlement_status=None,
                skipped=True,
                skip_reason="user_not_found",
            )

        verified = self._to_verified_purchase(transaction)
        status = self._resolve_record_status_for_notification(
            notification.notification_type,
            verified,
        )
        membership = await self._sync_apple_record(user_id, verified, status=status)
        return IapAppleNotificationResult(
            notification_type=notification.notification_type,
            notification_uuid=notification.notification_uuid,
            product_id=transaction.product_id,
            transaction_id=transaction.transaction_id,
            entitlement_status=membership.status,
            skipped=False,
        )

    async def list_my_entitlements(self, user_id: uuid.UUID) -> list[IapEntitlementSnapshot]:
        membership = await self.member_service.refresh_user_membership(user_id)
        return [self._to_entitlement_snapshot(membership)]

    async def _sync_apple_record(
        self,
        user_id: uuid.UUID,
        verified: IapVerifiedPurchase,
        *,
        status: str | None = None,
    ) -> UserMembership:
        product = await self.member_service.get_apple_product(verified.product_id)
        record_status = status or self._resolve_record_status_from_verified(verified)
        return await self.member_service.create_record_and_refresh(
            MemberRecordInput(
                user_id=user_id,
                product_id=product.id,
                source=MemberSource.APPLE,
                transaction_id=verified.transaction_id,
                original_transaction_id=verified.original_transaction_id,
                membership_type=product.membership_type,
                start_time=verified.purchase_date,
                end_time=verified.expire_time,
                status=record_status,
                remark=verified.receipt,
            )
        )

    async def _ensure_user_exists(self, user_id: uuid.UUID) -> None:
        if self.user_repo is None:
            return
        user = await self.user_repo.get_by_id(user_id)
        if user is None:
            raise BusinessException("用户不存在", 404)

    async def _resolve_user_id_for_transaction(
        self,
        transaction: AppleTransactionInfo,
    ) -> uuid.UUID | None:
        record = await self.record_repo.get_by_transaction_id(transaction.transaction_id)
        if record is not None:
            return record.user_id
        record = await self.record_repo.get_latest_by_original_transaction_id(
            transaction.original_transaction_id
        )
        if record is not None:
            return record.user_id
        return None

    @staticmethod
    def _resolve_record_status_from_verified(verified: IapVerifiedPurchase) -> str:
        if verified.is_active:
            return MemberRecordStatus.ACTIVE
        if verified.expire_time is not None:
            return MemberRecordStatus.EXPIRED
        return MemberRecordStatus.REVOKED

    @staticmethod
    def _resolve_record_status_for_notification(
        notification_type: str,
        verified: IapVerifiedPurchase,
    ) -> str:
        if notification_type in {"SUBSCRIBED", "DID_RENEW"}:
            return MemberRecordStatus.ACTIVE
        if notification_type == "EXPIRED":
            return MemberRecordStatus.EXPIRED
        if notification_type in {"REFUND", "REVOKE"}:
            return MemberRecordStatus.REVOKED
        return IapService._resolve_record_status_from_verified(verified)

    @staticmethod
    def _to_verified_purchase(
        transaction: AppleTransactionInfo,
        *,
        receipt: str | None = None,
    ) -> IapVerifiedPurchase:
        return IapVerifiedPurchase(
            product_id=transaction.product_id,
            transaction_id=transaction.transaction_id,
            original_transaction_id=transaction.original_transaction_id,
            purchase_date=transaction.purchase_date,
            expire_time=transaction.expire_time,
            environment=transaction.environment,
            is_active=transaction.is_active,
            receipt=receipt,
        )

    @staticmethod
    def _to_entitlement_snapshot(membership: UserMembership) -> IapEntitlementSnapshot:
        status = (
            "active"
            if membership.status == MembershipStatus.ACTIVE
            else "expired"
        )
        start_time = membership.start_time or datetime.now(timezone.utc)
        return IapEntitlementSnapshot(
            entitlement="vip",
            status=status,
            start_time=start_time,
            end_time=membership.end_time,
        )
