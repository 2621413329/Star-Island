"""本机语音转文字服务（SenseVoice-Small）。不依赖云端，也不走 Ollama。

安装（建议单独的 Python 环境，不要和后端混用 CPU/GPU 大包）：

    pip install funasr modelscope torch torchaudio

启动：

    python scripts/local_sensevoice_server.py --host 127.0.0.1 --port 8091

模型默认下载到本机 ModelScope 缓存。可事先指定目录：

    set MODELSCOPE_CACHE=D:\\AI\\Models
    python scripts/local_sensevoice_server.py --port 8091

后端 .env：

    LOCAL_ASR_BASE_URL=http://127.0.0.1:8091
"""

from __future__ import annotations

import argparse
import json
import re
import tempfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

_TAG = re.compile(r"<\|[^|]*\|>")
_MODEL = None


def clean_sensevoice_text(raw: str) -> str:
    text = _TAG.sub("", raw or "")
    return " ".join(text.split()).strip()


def load_model(model_id: str, device: str):
    try:
        from funasr import AutoModel
    except ImportError as exc:
        raise SystemExit(
            "未安装 funasr。请执行：pip install funasr modelscope torch torchaudio"
        ) from exc
    return AutoModel(
        model=model_id,
        trust_remote_code=True,
        device=device,
        disable_update=True,
    )


def transcribe_file(path: Path) -> str:
    result = _MODEL.generate(
        input=str(path),
        cache={},
        language="zh",
        use_itn=True,
        batch_size_s=60,
    )
    if not result:
        return ""
    first = result[0]
    if isinstance(first, dict):
        return clean_sensevoice_text(str(first.get("text") or ""))
    return clean_sensevoice_text(str(first))


class Handler(BaseHTTPRequestHandler):
    server_version = "LocalSenseVoice/1.0"

    def do_GET(self) -> None:
        if self.path.rstrip("/") != "/health":
            self.send_error(404)
            return
        body = b'{"ok":true}'
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self) -> None:
        if self.path.rstrip("/") != "/transcribe":
            self.send_error(404)
            return
        length = int(self.headers.get("Content-Length") or "0")
        if length <= 0:
            self._json(400, {"text": "", "message": "语音文件为空"})
            return
        raw = self.rfile.read(length)
        filename = self.headers.get("X-Filename") or "voice.m4a"
        suffix = Path(filename).suffix or ".m4a"
        try:
            with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
                tmp.write(raw)
                tmp_path = Path(tmp.name)
            try:
                text = transcribe_file(tmp_path)
            finally:
                tmp_path.unlink(missing_ok=True)
        except Exception as exc:
            self._json(500, {"text": "", "message": str(exc)})
            return
        if not text:
            self._json(400, {"text": "", "message": "识别结果为空"})
            return
        self._json(200, {"text": text})

    def _json(self, status: int, payload: dict) -> None:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt: str, *args) -> None:
        print(f"[local-asr] {self.address_string()} {fmt % args}")


def main() -> None:
    global _MODEL
    parser = argparse.ArgumentParser(description="本地 SenseVoice 语音转文字")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8091)
    parser.add_argument("--model", default="iic/SenseVoiceSmall")
    parser.add_argument("--device", default="cpu", help="cpu 或 cuda:0")
    args = parser.parse_args()
    print(f"正在加载 {args.model}（首次会下载到 ModelScope 缓存）...")
    _MODEL = load_model(args.model, args.device)
    httpd = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f"本地语音识别已启动：http://{args.host}:{args.port}/transcribe")
    httpd.serve_forever()


if __name__ == "__main__":
    main()
