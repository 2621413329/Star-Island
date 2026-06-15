# 初始化本机 PostgreSQL 库 island（与远程 stday 库隔离）
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not (Test-Path ".\.env")) {
    throw "未找到 backend/.env，请先 copy .env.example .env 并填写 DATABASE_URL"
}

$dbUrl = (Get-Content ".\.env" | Where-Object { $_ -match '^DATABASE_URL=' }) -replace '^DATABASE_URL=', ''
if (-not $dbUrl) {
    throw ".env 中缺少 DATABASE_URL"
}

if ($dbUrl -notmatch '/([^/?]+)(\?|$)') {
    throw "无法从 DATABASE_URL 解析数据库名: $dbUrl"
}
$dbName = $Matches[1]

Write-Host ">> 目标数据库: $dbName" -ForegroundColor Cyan

$psql = Get-Command psql -ErrorAction SilentlyContinue
if (-not $psql) {
    $candidates = @(
        "C:\Program Files\PostgreSQL\17\bin\psql.exe",
        "C:\Program Files\PostgreSQL\16\bin\psql.exe",
        "C:\Program Files\PostgreSQL\15\bin\psql.exe"
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            $psql = Get-Item $candidate
            break
        }
    }
}
if (-not $psql) {
    throw "未找到 psql，请安装 PostgreSQL 并将 bin 目录加入 PATH"
}
$psqlExe = if ($psql -is [System.Management.Automation.ApplicationInfo]) { $psql.Source } else { $psql.FullName }

$exists = & $psqlExe -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$dbName'" 2>$null
if ($exists -match '1') {
    Write-Host ">> 数据库 $dbName 已存在，跳过创建" -ForegroundColor Yellow
} else {
    Write-Host ">> 创建数据库 $dbName ..." -ForegroundColor Green
    & $psqlExe -U postgres -c "CREATE DATABASE $dbName ENCODING 'UTF8';"
}

if (-not (Test-Path ".\.venv\Scripts\Activate.ps1")) {
    throw "未找到 .venv，请先: python -m venv .venv; pip install -r requirements.txt"
}
. .\.venv\Scripts\Activate.ps1

Write-Host ">> 执行 Alembic 迁移 ..." -ForegroundColor Cyan
alembic upgrade head

Write-Host ">> 完成。当前 backend 使用独立库 $dbName" -ForegroundColor Green
