from pathlib import Path

from fastapi.testclient import TestClient

from app.main import app

_LEGAL_DIR = Path(__file__).resolve().parents[1] / "static" / "legal"


def test_legal_static_files_exist():
    assert (_LEGAL_DIR / "terms.html").is_file()
    assert (_LEGAL_DIR / "privacy.html").is_file()
    assert (_LEGAL_DIR / "index.html").is_file()


def test_legal_pages_are_publicly_reachable():
    client = TestClient(app)

    terms = client.get("/legal/terms")
    assert terms.status_code == 200
    assert "text/html" in terms.headers.get("content-type", "")
    assert "Terms of Use" in terms.text
    assert "用户协议" in terms.text
    assert "星屿会员" in terms.text

    privacy = client.get("/legal/privacy")
    assert privacy.status_code == 200
    assert "text/html" in privacy.headers.get("content-type", "")
    assert "Privacy Policy" in privacy.text
    assert "隐私政策" in privacy.text

    index = client.get("/legal/")
    assert index.status_code == 200
    assert "法律信息" in index.text
