"""Apple StoreKit 2 交易验签与解析（无数据库依赖）。"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from functools import lru_cache
from pathlib import Path
from typing import Any

from app.core.config import settings
from app.exceptions.business import BusinessException

_APPLE_CERT_DIR = Path(__file__).resolve().parent.parent / "certs" / "apple"


@dataclass(frozen=True)
class AppleTransactionInfo:
    product_id: str
    transaction_id: str
    original_transaction_id: str
    purchase_date: datetime
    expire_time: datetime | None
    environment: str
    is_active: bool


@dataclass(frozen=True)
class AppleNotificationInfo:
    notification_type: str
    notification_uuid: str | None
    subtype: str | None
    transaction: AppleTransactionInfo | None


class AppleTransactionError(BusinessException):
    def __init__(self, message: str = "Apple 交易验证失败", code: int = 400):
        super().__init__(message, code)


@lru_cache(maxsize=1)
def _load_app_store_server_library() -> tuple[Any, Any, type[Exception]]:
    try:
        from appstoreserverlibrary.models.Environment import Environment
        from appstoreserverlibrary.signed_data_verifier import (
            SignedDataVerifier,
            VerificationException,
        )
    except ModuleNotFoundError as exc:
        raise AppleTransactionError(
            "未安装 app-store-server-library，请先在后端虚拟环境运行 pip install -r requirements.txt",
            500,
        ) from exc
    return Environment, SignedDataVerifier, VerificationException


@lru_cache(maxsize=1)
def _load_root_certificates(cert_dir: str) -> tuple[bytes, ...]:
    directory = Path(cert_dir)
    if not directory.is_dir():
        raise AppleTransactionError(f"Apple 根证书目录不存在: {directory}")

    certificates = tuple(path.read_bytes() for path in sorted(directory.glob("*.cer")))
    if not certificates:
        raise AppleTransactionError(f"Apple 根证书目录为空: {directory}")
    return certificates


def _ms_to_datetime(value: int | None) -> datetime | None:
    if value is None:
        return None
    return datetime.fromtimestamp(value / 1000, tz=timezone.utc)


def _resolve_environment(payload: Any) -> str:
    if payload.environment is not None:
        return payload.environment.value
    if payload.rawEnvironment:
        return payload.rawEnvironment
    return ""


def _is_transaction_active(
    payload: Any,
    *,
    now: datetime | None = None,
) -> bool:
    current = now or datetime.now(timezone.utc)
    if payload.revocationDate is not None:
        return False
    if payload.expiresDate is not None:
        expire_time = _ms_to_datetime(payload.expiresDate)
        return expire_time is not None and expire_time > current
    return True


class AppleService:
    """验证并解析 StoreKit 2 签名交易（JWS）。"""

    def __init__(
        self,
        *,
        bundle_id: str | None = None,
        app_apple_id: int | None = None,
        enable_online_checks: bool | None = None,
        root_cert_dir: Path | str | None = None,
    ) -> None:
        self._bundle_id = bundle_id or settings.APPLE_BUNDLE_ID
        self._app_apple_id = app_apple_id if app_apple_id is not None else settings.APPLE_APP_ID
        self._enable_online_checks = (
            settings.APPLE_ENABLE_ONLINE_CHECKS
            if enable_online_checks is None
            else enable_online_checks
        )
        cert_dir = Path(root_cert_dir) if root_cert_dir is not None else _APPLE_CERT_DIR
        self._root_certificates = list(_load_root_certificates(str(cert_dir.resolve())))

    def verify_and_parse_transaction(self, signed_transaction: str) -> AppleTransactionInfo:
        """验证 Apple 签名交易并返回解析结果。"""
        token = signed_transaction.strip()
        if not token:
            raise AppleTransactionError("交易数据不能为空")
        if not self._bundle_id:
            raise AppleTransactionError("未配置 APPLE_BUNDLE_ID")

        last_error: Exception | None = None
        Environment, _, VerificationException = _load_app_store_server_library()
        for environment in (Environment.PRODUCTION, Environment.SANDBOX):
            try:
                verifier = self._build_verifier(environment)
                payload = verifier.verify_and_decode_signed_transaction(token)
                return self._to_transaction_info(payload)
            except VerificationException as exc:
                last_error = exc
            except ValueError as exc:
                last_error = exc

        message = "Apple 交易签名验证失败"
        if last_error is not None:
            message = f"{message}: {last_error}"
        raise AppleTransactionError(message) from last_error

    def verify_and_parse_notification(self, signed_payload: str) -> AppleNotificationInfo:
        """验证并解析 App Store Server Notifications V2。"""
        token = signed_payload.strip()
        if not token:
            raise AppleTransactionError("通知数据不能为空")
        if not self._bundle_id:
            raise AppleTransactionError("未配置 APPLE_BUNDLE_ID")

        last_error: Exception | None = None
        Environment, _, VerificationException = _load_app_store_server_library()
        for environment in (Environment.PRODUCTION, Environment.SANDBOX):
            try:
                verifier = self._build_verifier(environment)
                payload = verifier.verify_and_decode_notification(token)
                transaction: AppleTransactionInfo | None = None
                if payload.data and payload.data.signedTransactionInfo:
                    decoded = verifier.verify_and_decode_signed_transaction(
                        payload.data.signedTransactionInfo
                    )
                    transaction = self._to_transaction_info(decoded)

                notification_type = payload.rawNotificationType or ""
                if payload.notificationType is not None:
                    notification_type = payload.notificationType.value

                subtype = payload.rawSubtype
                if subtype is None and payload.subtype is not None:
                    subtype = payload.subtype.value

                return AppleNotificationInfo(
                    notification_type=notification_type,
                    notification_uuid=payload.notificationUUID,
                    subtype=subtype,
                    transaction=transaction,
                )
            except VerificationException as exc:
                last_error = exc
            except ValueError as exc:
                last_error = exc

        message = "Apple 通知签名验证失败"
        if last_error is not None:
            message = f"{message}: {last_error}"
        raise AppleTransactionError(message) from last_error

    def _build_verifier(self, environment: Any) -> Any:
        Environment, SignedDataVerifier, _ = _load_app_store_server_library()
        if environment == Environment.PRODUCTION and self._app_apple_id is None:
            raise ValueError("Production 环境验签需要配置 APPLE_APP_ID")
        return SignedDataVerifier(
            self._root_certificates,
            self._enable_online_checks,
            environment,
            self._bundle_id,
            self._app_apple_id,
        )

    def _to_transaction_info(self, payload: Any) -> AppleTransactionInfo:
        product_id = (payload.productId or "").strip()
        transaction_id = (payload.transactionId or "").strip()
        original_transaction_id = (payload.originalTransactionId or transaction_id).strip()
        if not product_id or not transaction_id:
            raise AppleTransactionError("交易数据缺少 productId 或 transactionId")
        if payload.purchaseDate is None:
            raise AppleTransactionError("交易数据缺少 purchaseDate")

        environment = _resolve_environment(payload)
        if not environment:
            raise AppleTransactionError("交易数据缺少 environment")

        return AppleTransactionInfo(
            product_id=product_id,
            transaction_id=transaction_id,
            original_transaction_id=original_transaction_id,
            purchase_date=_ms_to_datetime(payload.purchaseDate),
            expire_time=_ms_to_datetime(payload.expiresDate),
            environment=environment,
            is_active=_is_transaction_active(payload),
        )
