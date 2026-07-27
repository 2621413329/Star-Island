"""会员系统常量。"""


class MemberSource:
    APPLE = "apple"
    ACTIVATION_CODE = "activation_code"
    ADMIN = "admin"


class MembershipType:
    MONTHLY = "monthly"
    QUARTERLY = "quarterly"
    YEARLY = "yearly"
    LIFETIME = "lifetime"


class MemberRecordStatus:
    ACTIVE = "active"
    EXPIRED = "expired"
    REVOKED = "revoked"
    CANCELLED = "cancelled"


class MembershipStatus:
    ACTIVE = "active"
    INACTIVE = "inactive"
    EXPIRED = "expired"
    CANCELLED = "cancelled"


class ActivationCodeStatus:
    UNUSED = "unused"
    USED = "used"
    EXPIRED = "expired"
    DISABLED = "disabled"


DEFAULT_ENTITLEMENT = "vip"

SUPPORTED_APPLE_NOTIFICATION_TYPES = frozenset({
    "SUBSCRIBED",
    "DID_RENEW",
    "EXPIRED",
    "REFUND",
    "REVOKE",
})
