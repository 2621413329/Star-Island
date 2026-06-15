# 单实例启动后端，避免多个 uvicorn 占满 9000 导致客户端连接超时。
# 使用 0.0.0.0 以便 Android 真机 / 模拟器通过局域网 IP 访问。
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host ">> 释放 9000 端口上的旧进程..." -ForegroundColor Yellow
Get-NetTCPConnection -LocalPort 9000 -State Listen -ErrorAction SilentlyContinue |
    ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
Start-Sleep -Seconds 1

if (-not (Test-Path ".\.venv\Scripts\Activate.ps1")) {
    throw "未找到 .venv，请先在 backend 目录执行: python -m venv .venv; pip install -r requirements.txt"
}
. .\.venv\Scripts\Activate.ps1

$lanIp = (
    Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object {
        $_.IPAddress -notlike '127.*' -and
        $_.IPAddress -notlike '169.254.*' -and
        $_.PrefixOrigin -ne 'WellKnown'
    } |
    Select-Object -First 1 -ExpandProperty IPAddress
)
if ($lanIp) {
    Write-Host ">> 局域网 API: http://${lanIp}:9000" -ForegroundColor Green
    Write-Host ">> Android 打包: flutter build apk --release --dart-define=API_BASE_URL=http://${lanIp}:9000" -ForegroundColor DarkGray
}

Write-Host ">> 启动 uvicorn http://0.0.0.0:9000" -ForegroundColor Cyan
uvicorn app.main:app --host 0.0.0.0 --port 9000 --reload
