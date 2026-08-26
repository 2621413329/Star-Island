from app.core.config import Settings


def test_ios_app_store_url_uses_configured_app_id():
    settings = Settings(
        DATABASE_URL="postgresql+asyncpg://u:p@127.0.0.1:5432/t",
        JWT_SECRET_KEY="x" * 32,
        DEBUG=True,
        APPLE_APP_ID=6782086773,
    )
    assert settings.ios_app_store_url == "https://apps.apple.com/app/id6782086773"


def test_ios_min_supported_version_defaults():
    settings = Settings(
        DATABASE_URL="postgresql+asyncpg://u:p@127.0.0.1:5432/t",
        JWT_SECRET_KEY="x" * 32,
        DEBUG=True,
    )
    assert settings.IOS_MIN_SUPPORTED_VERSION == "1.0.0"
    assert settings.APPLE_APP_ID == 6782086773
