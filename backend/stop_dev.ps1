# 停止由 run_dev.ps1 -Background 或前台启动占用 9000 端口的后端。
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$PidFile = Join-Path $PSScriptRoot "logs\uvicorn.pid"
if (Test-Path $PidFile) {
    $saved = Get-Content $PidFile -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($saved -match '^\d+$') {
        & taskkill.exe /PID $saved /T /F 2>$null | Out-Null
    }
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
}

Get-NetTCPConnection -LocalPort 9000 -State Listen -ErrorAction SilentlyContinue |
    ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }

Write-Host ">> 9000 端口上的后端已停止" -ForegroundColor Yellow
