# 单实例启动后端，避免多个 uvicorn 占满 8000 导致客户端连接超时。
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host ">> 释放 8000 端口上的旧进程..." -ForegroundColor Yellow
Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue |
    ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
Start-Sleep -Seconds 1

if (-not (Test-Path ".\.venv\Scripts\Activate.ps1")) {
    throw "未找到 .venv，请先在 backend 目录执行: python -m venv .venv; pip install -r requirements.txt"
}
. .\.venv\Scripts\Activate.ps1

Write-Host ">> 启动 uvicorn http://127.0.0.1:8000" -ForegroundColor Cyan
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
