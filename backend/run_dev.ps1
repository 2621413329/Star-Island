# 单实例启动后端，避免多个 uvicorn 占满 9000 导致客户端连接超时。
# 使用 0.0.0.0 以便 Android 真机 / 模拟器通过局域网 IP 访问。
# 后台：.\run_dev.ps1 -Background   停止：.\stop_dev.ps1
param(
    [switch]$Background
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$LogDir = Join-Path $PSScriptRoot "logs"
$PidFile = Join-Path $LogDir "uvicorn.pid"
$LogFile = Join-Path $LogDir "uvicorn.log"

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

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

if ($Background) {
    $python = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
    if (-not (Test-Path $python)) {
        throw "未找到 $python"
    }
    # 标准输出和错误写进同一份日志；隐藏窗口，关掉启动窗口后进程继续跑。
    $proc = Start-Process -FilePath "cmd.exe" `
        -ArgumentList "/c", "`"$python`" -m uvicorn app.main:app --host 0.0.0.0 --port 9000 --reload >> `"$LogFile`" 2>&1" `
        -WorkingDirectory $PSScriptRoot `
        -WindowStyle Hidden `
        -PassThru
    Set-Content -Path $PidFile -Value $proc.Id -Encoding ascii
    Write-Host ">> 已在后台启动 uvicorn http://0.0.0.0:9000  PID=$($proc.Id)" -ForegroundColor Cyan
    Write-Host ">> 日志: $LogFile" -ForegroundColor DarkGray
    Write-Host ">> 停止: .\stop_dev.ps1" -ForegroundColor DarkGray
    exit 0
}

Write-Host ">> 启动 uvicorn http://0.0.0.0:9000（关闭此窗口即停止）" -ForegroundColor Cyan
uvicorn app.main:app --host 0.0.0.0 --port 9000 --reload
