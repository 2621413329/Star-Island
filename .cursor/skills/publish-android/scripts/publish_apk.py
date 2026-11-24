"""Publish one Android APK into the staweb download directories.

Run on the server as root:
  python3 publish_apk.py /tmp/xingyu.apk 1.4.0 349277208
"""

import json
import os
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import quote

DIRS = (
    (Path("/home/dream/stweb/staweb/public/downloads"), "dream", "dream"),
    (Path("/home/dream/stweb/staweb/dist/downloads"), "dream", "dream"),
    (Path("/usr/share/nginx/html/staweb/downloads"), "nginx", "nginx"),
)
NAME = "\u6210\u957f\u5c0f\u5c9b Android \u7248"
DESCRIPTION = (
    "\u516c\u5f00\u6d4b\u8bd5\u7248\uff0c\u9002\u7528\u4e8e Android "
    "\u624b\u673a\u4e0e\u5e73\u677f\u3002"
)


def publish(directory: Path, src: Path, filename: str, version: str, uid: str, gid: str) -> None:
    directory.mkdir(parents=True, exist_ok=True)
    dest = directory / filename
    shutil.copy2(src, dest)
    os.chmod(dest, 0o644)
    size = dest.stat().st_size
    updated = datetime.fromtimestamp(dest.stat().st_mtime, timezone.utc).strftime("%Y-%m-%d")
    config = {
        "packages": [
            {
                "filename": filename,
                "name": NAME,
                "version": version,
                "platform": "android",
                "description": DESCRIPTION,
            }
        ]
    }
    manifest = {
        "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z"),
        "packages": [
            {
                "id": filename.rsplit(".", 1)[0],
                "filename": filename,
                "url": "/downloads/" + quote(filename),
                "version": version,
                "size": f"{size / (1024 * 1024):.0f} MB",
                "sizeBytes": size,
                "platform": "android",
                "name": NAME,
                "description": DESCRIPTION,
                "updatedAt": updated,
            }
        ],
    }
    (directory / "downloads.config.json").write_text(
        json.dumps(config, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    (directory / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    for old in directory.glob("*.apk"):
        if old.resolve() != dest.resolve():
            old.unlink()
            print("removed", old)
    shutil.chown(directory, uid, gid)
    for child in directory.iterdir():
        shutil.chown(child, uid, gid)
    print("ok", dest, size)


def main() -> int:
    if len(sys.argv) != 4:
        print("usage: publish_apk.py <apk> <version> <expected-bytes>", file=sys.stderr)
        return 2
    src = Path(sys.argv[1])
    version = sys.argv[2]
    expected = int(sys.argv[3])
    actual = src.stat().st_size
    if actual != expected:
        print(f"size mismatch: {actual} != {expected}", file=sys.stderr)
        return 1
    filename = f"\u661f\u5c7f{version}.apk"
    for directory, uid, gid in DIRS:
        publish(directory, src, filename, version, uid, gid)
    if src.is_file() and str(src).startswith("/tmp/"):
        src.unlink()
        print("tmp removed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
