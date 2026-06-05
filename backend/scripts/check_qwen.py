"""检查千问配置是否加载（不打印密钥）。"""
from app.core.config import settings

key = settings.QWEN_API_KEY
print("key_set:", bool(key and str(key).strip()))
if key:
    print("key_len:", len(str(key).strip()))
print("chat_model:", settings.QWEN_CHAT_MODEL)
print("fast_model:", settings.QWEN_FAST_MODEL)
print("base_url:", settings.QWEN_BASE_URL)
