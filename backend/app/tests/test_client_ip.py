from fastapi import Request

from app.core.client_ip import get_client_ip


def _build_request(headers: dict[str, str] | None = None, host: str = "10.0.0.1") -> Request:
    scope = {
        "type": "http",
        "method": "POST",
        "path": "/api/v1/auth/login",
        "headers": [(k.lower().encode(), v.encode()) for k, v in (headers or {}).items()],
        "client": (host, 12345),
        "server": ("testserver", 80),
        "scheme": "http",
        "http_version": "1.1",
    }
    return Request(scope)


def test_get_client_ip_prefers_x_real_ip():
    request = _build_request({"X-Real-IP": "203.0.113.10", "X-Forwarded-For": "198.51.100.1"})
    assert get_client_ip(request) == "203.0.113.10"


def test_get_client_ip_uses_first_x_forwarded_for():
    request = _build_request({"X-Forwarded-For": "203.0.113.10, 10.0.0.1"})
    assert get_client_ip(request) == "203.0.113.10"


def test_get_client_ip_falls_back_to_socket_client():
    request = _build_request(host="192.168.1.5")
    assert get_client_ip(request) == "192.168.1.5"
