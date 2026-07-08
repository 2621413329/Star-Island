"""会员中心核心服务：流水写入与 user_membership 统一刷新。"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from app.core.member_constants import (
    MemberRecordStatus,
    MemberSource,
    MembershipStatus,
    MembershipType,
)
from app.exceptions.business import BusinessException
from app.models.member import MemberProduct, MemberRecord, UserMembership
from app.repositories.member_product_repository import MemberProductRepository
from app.repositories.member_record_repository import MemberRecordRepository
from app.repositories.user_membership_repository import UserMembershipRepository
from app.repositories.user_repository import UserRepository


@dataclass(frozen=True)
class MemberMeSnapshot:
    is_vip: bool
    membership_type: str | None
    expire_time: datetime | None
    source: str | None


@dataclass(frozen=True)
class MemberRecordInput:
    user_id: uuid.UUID
    source: str
    membership_type: str
    start_time: datetime
    end_time: datetime | None
    status: str
    product_id: uuid.UUID | None = None
    transaction_id: str | None = None
    original_transaction_id: str | None = None
    activation_code_id: uuid.UUID | None = None
    admin_id: uuid.UUID | None = None
    remark: str | None = None


class MemberService:
    def __init__(
        self,
        product_repo: MemberProductRepository,
        record_repo: MemberRecordRepository,
        membership_repo: UserMembershipRepository,
        *,
        user_repo: UserRepository | None = None,
    ) -> None:
        self.product_repo = product_repo
        self.record_repo = record_repo
        self.membership_repo = membership_repo
        self.user_repo = user_repo

    async def get_member_me(self, user_id: uuid.UUID) -> MemberMeSnapshot:
        await self._ensure_user_exists(user_id)
        membership = await self.refresh_user_membership(user_id)
        return self.to_member_me_snapshot(membership)

    async def create_record_and_refresh(self, payload: MemberRecordInput) -> UserMembership:
        await self._ensure_user_exists(payload.user_id)
        if payload.transaction_id:
            existing = await self.record_repo.get_by_transaction_id(payload.transaction_id)
            if existing is not None:
                if existing.user_id != payload.user_id:
                    raise BusinessException("交易已绑定其他用户", 409)
                existing.status = payload.status
                existing.start_time = payload.start_time
                existing.end_time = payload.end_time
                existing.original_transaction_id = payload.original_transaction_id
                if payload.product_id is not None:
                    existing.product_id = payload.product_id
                if payload.remark:
                    existing.remark = payload.remark
                await self.record_repo.save(existing)
                return await self.refresh_user_membership(payload.user_id)

        record = MemberRecord(
            user_id=payload.user_id,
            product_id=payload.product_id,
            source=payload.source,
            transaction_id=payload.transaction_id,
            original_transaction_id=payload.original_transaction_id,
            activation_code_id=payload.activation_code_id,
            admin_id=payload.admin_id,
            membership_type=payload.membership_type,
            start_time=payload.start_time,
            end_time=payload.end_time,
            status=payload.status,
            remark=payload.remark,
        )
        await self.record_repo.create(record)
        return await self.refresh_user_membership(payload.user_id)

    async def refresh_user_membership(self, user_id: uuid.UUID) -> UserMembership:
        now = datetime.now(timezone.utc)
        records = await self.record_repo.list_by_user_id(user_id, limit=500)
        for record in records:
            self._sync_record_status(record, now=now)
            if record.status == MemberRecordStatus.ACTIVE:
                await self.record_repo.save(record)

        best_record = self._select_best_record(records, now=now)
        existing = await self.membership_repo.get_by_user_id(user_id)

        if best_record is None:
            if existing is None:
                membership = UserMembership(
                    user_id=user_id,
                    membership_type=None,
                    status=MembershipStatus.INACTIVE,
                    start_time=None,
                    end_time=None,
                    source=None,
                    latest_record_id=None,
                )
                return await self.membership_repo.create(membership)

            existing.membership_type = None
            existing.status = MembershipStatus.EXPIRED
            existing.start_time = None
            existing.end_time = None
            existing.source = None
            existing.latest_record_id = None
            return await self.membership_repo.save(existing)

        if existing is None:
            membership = UserMembership(
                user_id=user_id,
                membership_type=best_record.membership_type,
                status=MembershipStatus.ACTIVE,
                start_time=best_record.start_time,
                end_time=best_record.end_time,
                source=best_record.source,
                latest_record_id=best_record.id,
            )
            return await self.membership_repo.create(membership)

        existing.membership_type = best_record.membership_type
        existing.status = MembershipStatus.ACTIVE
        existing.start_time = best_record.start_time
        existing.end_time = best_record.end_time
        existing.source = best_record.source
        existing.latest_record_id = best_record.id
        return await self.membership_repo.save(existing)

    async def gift_membership(
        self,
        *,
        user_id: uuid.UUID,
        membership_type: str,
        duration_days: int | None,
        admin_id: uuid.UUID,
        remark: str | None = None,
    ) -> UserMembership:
        start_time = datetime.now(timezone.utc)
        end_time = self.calculate_end_time(start_time, membership_type, duration_days)
        return await self.create_record_and_refresh(
            MemberRecordInput(
                user_id=user_id,
                source=MemberSource.ADMIN,
                membership_type=membership_type,
                start_time=start_time,
                end_time=end_time,
                status=MemberRecordStatus.ACTIVE,
                admin_id=admin_id,
                remark=remark,
            )
        )

    async def cancel_membership(
        self,
        user_id: uuid.UUID,
        *,
        admin_id: uuid.UUID,
        remark: str | None = None,
    ) -> UserMembership:
        await self._ensure_user_exists(user_id)
        records = await self.record_repo.list_active_by_user_id(user_id)
        for record in records:
            record.status = MemberRecordStatus.CANCELLED
            if remark:
                record.remark = remark
            record.admin_id = admin_id
            await self.record_repo.save(record)
        return await self.refresh_user_membership(user_id)

    async def get_apple_product(self, apple_product_id: str) -> MemberProduct:
        product = await self.product_repo.get_by_apple_product_id(apple_product_id)
        if product is None:
            raise BusinessException("商品不存在", 404)
        if not product.enable:
            raise BusinessException("商品已下架", 400)
        if product.source != MemberSource.APPLE:
            raise BusinessException("非 Apple 商品", 400)
        return product

    @staticmethod
    def calculate_end_time(
        start_time: datetime,
        membership_type: str,
        duration_days: int | None,
    ) -> datetime | None:
        if membership_type == MembershipType.LIFETIME:
            return None
        days = duration_days
        if days is None:
            days = {
                MembershipType.MONTHLY: 30,
                MembershipType.QUARTERLY: 90,
                MembershipType.YEARLY: 365,
            }.get(membership_type, 30)
        return start_time + timedelta(days=days)

    @staticmethod
    def to_member_me_snapshot(membership: UserMembership | None) -> MemberMeSnapshot:
        if membership is None:
            return MemberMeSnapshot(
                is_vip=False,
                membership_type=None,
                expire_time=None,
                source=None,
            )
        is_vip = membership.status == MembershipStatus.ACTIVE and (
            membership.end_time is None or membership.end_time > datetime.now(timezone.utc)
        )
        return MemberMeSnapshot(
            is_vip=is_vip,
            membership_type=membership.membership_type,
            expire_time=membership.end_time,
            source=membership.source,
        )

    async def _ensure_user_exists(self, user_id: uuid.UUID) -> None:
        if self.user_repo is None:
            return
        user = await self.user_repo.get_by_id(user_id)
        if user is None:
            raise BusinessException("用户不存在", 404)

    @staticmethod
    def _sync_record_status(record: MemberRecord, *, now: datetime) -> None:
        if record.status in {MemberRecordStatus.CANCELLED, MemberRecordStatus.REVOKED}:
            return
        if record.end_time is not None and record.end_time <= now:
            record.status = MemberRecordStatus.EXPIRED

    @staticmethod
    def _select_best_record(
        records: list[MemberRecord],
        *,
        now: datetime,
    ) -> MemberRecord | None:
        best: MemberRecord | None = None
        for record in records:
            if record.status != MemberRecordStatus.ACTIVE:
                continue
            if record.end_time is not None and record.end_time <= now:
                continue
            if best is None:
                best = record
                continue
            if best.end_time is None:
                continue
            if record.end_time is None or record.end_time > best.end_time:
                best = record
        return best
