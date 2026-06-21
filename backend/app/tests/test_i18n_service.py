from app.services.i18n_service import FALLBACK_CHAIN, I18nService, _fallback_tags


def test_fallback_tags_prefers_primary_then_zh_cn():
    tags = _fallback_tags("en_US")
    assert tags[0] == "en_US"
    assert "zh_CN" in tags


def test_fallback_chain_has_expected_locales():
    assert FALLBACK_CHAIN["ja_JP"] == ["en_US", "zh_CN"]


def test_i18n_service_config_default_language(monkeypatch):
    monkeypatch.setattr(
        "app.services.i18n_service.settings.DEFAULT_LANGUAGE",
        "en_US",
    )
    service = I18nService(repo=type("Repo", (), {})())
    config = service.get_config()
    assert config["default_language"] == "en_US"
    assert "zh_CN" in config["supported_languages"]
