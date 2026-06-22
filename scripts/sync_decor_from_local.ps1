# 将本地装饰素材同步到 stday/assets/images/decor
# 用法（PowerShell）:
#   .\scripts\sync_decor_from_local.ps1
#   .\scripts\sync_decor_from_local.ps1 -SourceDir "D:\your\path\to\decor"

param(
    [string]$SourceDir = "D:\tradition\med\mobile\build\app\outputs\apk\release\2",
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$TargetDir = Join-Path $RepoRoot "stday\assets\images\decor"

$RequiredFiles = @(
    "grass_01.png", "grass_02.png", "grass_03.png",
    "flower_01.png", "flower_02.png", "flower_03.png",
    "stone_01.png", "stone_02.png",
    "bush_01.png", "bush_02.png",
    "tree_small_01.png", "tree_small_02.png", "tree_small_03.png",
    "mushroom_01.png", "wood_01.png",
    "butterfly_01.png",
    "tree_large_01.png",
    "cloud_01.png", "cloud_02.png", "cloud_03.png",
    "flower_field_01.png",
    "bird_01.png",
    "tree_large_02.png",
    "pond_01.png",
    "bird_02.png", "bird_03.png", "cloud_04.png",
    "firefly_01.png",
    "rare_flower_01.png",
    "rainbow_cloud_01.png",
    "seagull_group_01.png",
    "life_tree_01.png"
)

if (-not (Test-Path $SourceDir)) {
    Write-Error "源目录不存在: $SourceDir"
}

if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

Write-Host "源目录: $SourceDir"
Write-Host "目标目录: $TargetDir"
Write-Host ""

$copied = 0
$missing = @()

foreach ($file in $RequiredFiles) {
    $src = Join-Path $SourceDir $file
    $dst = Join-Path $TargetDir $file
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $dst -Force
        Write-Host "[复制] $file"
        $copied++
    } else {
        Write-Host "[缺失] $file" -ForegroundColor Yellow
        $missing += $file
    }
}

# 同步源目录中其他同名 png（可选扩展资源）
Get-ChildItem -Path $SourceDir -Filter "*.png" | ForEach-Object {
    if ($RequiredFiles -contains $_.Name) { return }
    $dst = Join-Path $TargetDir $_.Name
    Copy-Item -Path $_.FullName -Destination $dst -Force
    Write-Host "[额外] $($_.Name)"
}

Write-Host ""
Write-Host "完成: 已复制 $copied / $($RequiredFiles.Count) 项必需装饰"
if ($missing.Count -gt 0) {
    Write-Host "以下文件在源目录中未找到，请检查命名:" -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  - $_" }
    exit 1
}

Write-Host "全部必需装饰已同步，可执行 git add / commit / push"
