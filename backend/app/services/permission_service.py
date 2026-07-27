"""会员权限判断。"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from app.core.member_constants import DEFAULT_ENTITLEMENT, MembershipStatus
from app.models.member import UserMembership
from app.repositories.user_membership_repository import UserMembershipRepository
from app.services.member_service import MemberService


class PermissionService:
    def __init__(
        self,
        membership_repo: UserMembershipRepository,
        member_service: MemberService | None = None,
    ) -> None:
        self.membership_repo = membership_repo
        self.member_service = member_service

    async def has_vip(self, user_id: uuid.UUID, *, refresh: bool = False) -> bool:
        membership = await self._get_membership(user_id, refresh=refresh)
        return self.is_vip_membership(membership)

    async def has_permission(
        self,
        user_id: uuid.UUID,
        permission: str,
        *,
        refresh: bool = False,
    ) -> bool:
        if permission == DEFAULT_ENTITLEMENT or permission == "vip":
            return await self.has_vip(user_id, refresh=refresh)
        return False

    async def _get_membership(
        self,
        user_id: uuid.UUID,
        *,
        refresh: bool,
    ) -> UserMembership | None:
        if refresh and self.member_service is not None:
            return await self.member_service.refresh_user_membership(user_id)
        return await self.membership_repo.get_by_user_id(user_id)

    @staticmethod
    def is_vip_membership(membership: UserMembership | None) -> bool:
        if membership is None:
            return False
        if membership.status != MembershipStatus.ACTIVE:
            return False
        if membership.end_time is None:
            return True
        return membership.end_time > datetime.now(timezone.utc)
