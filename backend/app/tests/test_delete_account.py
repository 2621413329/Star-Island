from pathlib import Path
from uuid import uuid4

from app.services.auth_service import AuthService


def test_remove_user_media_deletes_directory(tmp_path: Path):
    user_dir = tmp_path / str(uuid4())
    nested = user_dir / "moments" / "a"
    nested.mkdir(parents=True)
    (nested / "photo.jpg").write_bytes(b"demo")

    AuthService._remove_user_media(user_dir)

    assert not user_dir.exists()


def test_remove_user_media_missing_directory_is_ok(tmp_path: Path):
    missing = tmp_path / "missing-user"
    AuthService._remove_user_media(missing)
    assert not missing.exists()
