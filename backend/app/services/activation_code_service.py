"""激活码生成与兑换。"""

from __future__ import annotations

import secrets
import string
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone

from app.core.member_constants import (
    ActivationCodeStatus,
    MemberRecordStatus,
    MemberSource,
    MembershipType,
)
from app.exceptions.business import BusinessException
from app.models.member import ActivationCode, UserMembership
from app.repositories.activation_code_repository import ActivationCodeRepository
from app.services.member_service import MemberRecordInput, MemberService


_CODE_ALPHABET = string.ascii_uppercase + string.digits


@dataclass(frozen=True)
class ActivationCodeCreateResult:
    id: uuid.UUID
    code: str
    membership_type: str
    duration_days: int | None
    status: str
    reusable: bool
    batch_no: str | None
    expire_time: datetime | None


class ActivationCodeService:
    def __init__(
        self,
        code_repo: ActivationCodeRepository,
        member_service: MemberService,
    ) -> None:
        self.code_repo = code_repo
        self.member_service = member_service

    async def generate_code(
        self,
        *,
        membership_type: str,
        duration_days: int | None = None,
        batch_no: str | None = None,
        remark: str | None = None,
        code_expire_time: datetime | None = None,
        code_length: int = 12,
        reusable: bool = False,
    ) -> ActivationCodeCreateResult:
        self._validate_membership_type(membership_type, duration_days)
        code_value = await self._generate_unique_code(code_length)
        row = ActivationCode(
            code=code_value,
            membership_type=membership_type,
            duration_days=duration_days,
            status=ActivationCodeStatus.UNUSED,
            reusable=reusable,
            batch_no=batch_no,
            remark=remark,
            expire_time=code_expire_time,
        )
        saved = await self.code_repo.create(row)
        return self._to_create_result(saved)

    async def generate_batch(
        self,
        *,
        count: int,
        membership_type: str,
        duration_days: int | None = None,
        batch_no: str | None = None,
        remark: str | None = None,
        code_expire_time: datetime | None = None,
        code_length: int = 12,
        reusable: bool = False,
    ) -> list[ActivationCodeCreateResult]:
        if count < 1 or count > 1000:
            raise BusinessException("批量数量需在 1~1000 之间", 400)
        self._validate_membership_type(membership_type, duration_days)
        batch_no = batch_no or datetime.now(timezone.utc).strftime("B%Y%m%d%H%M%S")
        rows: list[ActivationCode] = []
        for _ in range(count):
            code_value = await self._generate_unique_code(code_length)
            rows.append(
                ActivationCode(
                    code=code_value,
                    membership_type=membership_type,
                    duration_days=duration_days,
                    status=ActivationCodeStatus.UNUSED,
                    reusable=reusable,
                    batch_no=batch_no,
                    remark=remark,
                    expire_time=code_expire_time,
                )
            )
        saved_rows = await self.code_repo.create_many(rows)
        return [self._to_create_result(row) for row in saved_rows]

    async def redeem_code(self, user_id: uuid.UUID, code: str) -> UserMembership:
        activation_code = await self.code_repo.get_by_code(code)
        if activation_code is None:
            raise BusinessException("激活码不存在", 404)
        if activation_code.status == ActivationCodeStatus.DISABLED:
            raise BusinessException("激活码已停用", 400)
        if activation_code.status == ActivationCodeStatus.USED:
            raise BusinessException("激活码已使用", 400)
        if activation_code.status == ActivationCodeStatus.EXPIRED:
            raise BusinessException("激活码已失效", 400)
        now = datetime.now(timezone.utc)
        if activation_code.expire_time is not None and activation_code.expire_time <= now:
            activation_code.status = ActivationCodeStatus.EXPIRED
            await self.code_repo.save(activation_code)
            raise BusinessException("激活码已过期", 400)
        if activation_code.reusable:
            existing = await self.member_service.record_repo.get_active_by_user_activation_code(
                user_id,
                activation_code.id,
                now=now,
            )
            if existing is not None:
                return await self.member_service.refresh_user_membership(user_id)

        start_time = now
        end_time = self.member_service.calculate_end_time(
            start_time,
            activation_code.membership_type,
            activation_code.duration_days,
        )
        membership = await self.member_service.create_record_and_refresh(
            MemberRecordInput(
                user_id=user_id,
                source=MemberSource.ACTIVATION_CODE,
                membership_type=activation_code.membership_type,
                start_time=start_time,
                end_time=end_time,
                status=MemberRecordStatus.ACTIVE,
                activation_code_id=activation_code.id,
                remark=activation_code.remark,
            )
        )

        if not activation_code.reusable:
            activation_code.status = ActivationCodeStatus.USED
            activation_code.user_id = user_id
            activation_code.used_time = now
            await self.code_repo.save(activation_code)
        return membership

    async def disable_code(self, code_id: uuid.UUID) -> ActivationCode:
        row = await self._get_code_or_404(code_id)
        if row.status == ActivationCodeStatus.USED:
            raise BusinessException("已使用的激活码不能停用", 400)
        row.status = ActivationCodeStatus.DISABLED
        return await self.code_repo.save(row)

    async def expire_code(self, code_id: uuid.UUID) -> ActivationCode:
        row = await self._get_code_or_404(code_id)
        if row.status == ActivationCodeStatus.USED:
            raise BusinessException("已使用的激活码不能失效", 400)
        row.status = ActivationCodeStatus.EXPIRED
        return await self.code_repo.save(row)

    async def list_codes(
        self,
        *,
        status: str | None = None,
        batch_no: str | None = None,
        limit: int = 200,
    ) -> list[ActivationCode]:
        return await self.code_repo.list_all(status=status, batch_no=batch_no, limit=limit)

    async def _get_code_or_404(self, code_id: uuid.UUID) -> ActivationCode:
        row = await self.code_repo.get_by_id(code_id)
        if row is None:
            raise BusinessException("激活码不存在", 404)
        return row

    async def _generate_unique_code(self, length: int) -> str:
        for _ in range(10):
            code = "".join(secrets.choice(_CODE_ALPHABET) for _ in range(length))
            existing = await self.code_repo.get_by_code(code)
            if existing is None:
                return code
        raise BusinessException("激活码生成失败，请重试", 500)

    @staticmethod
    def _validate_membership_type(membership_type: str, duration_days: int | None) -> None:
        allowed = {
            MembershipType.MONTHLY,
            MembershipType.QUARTERLY,
            MembershipType.YEARLY,
            MembershipType.LIFETIME,
        }
        if membership_type not in allowed:
            raise BusinessException("不支持的会员类型", 400)
        if membership_type == MembershipType.LIFETIME and duration_days is not None:
            raise BusinessException("终身会员不需要 duration_days", 400)

    @staticmethod
    def _to_create_result(row: ActivationCode) -> ActivationCodeCreateResult:
        return ActivationCodeCreateResult(
            id=row.id,
            code=row.code,
            membership_type=row.membership_type,
            duration_days=row.duration_days,
            status=row.status,
            reusable=row.reusable,
            batch_no=row.batch_no,
            expire_time=row.expire_time,
        )
