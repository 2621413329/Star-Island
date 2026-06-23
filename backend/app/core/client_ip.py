from fastapi import Request


def get_client_ip(request: Request) -> str:
    """优先读取反向代理透传的真实 IP（Nginx X-Real-IP / X-Forwarded-For）。"""
    real_ip = request.headers.get("X-Real-IP")
    if real_ip:
        return real_ip.strip()

    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        return forwarded_for.split(",")[0].strip()

    if request.client and request.client.host:
        return request.client.host
    return "unknown"
