# Windows launcher: fixes missing ephemeral (C1083). Do NOT double-click .ps1 (may open in Notepad).
# Use: run_windows.bat | run_windows_release.bat | repair_windows.bat
param(
    [string]$ApiBaseUrl = "http://127.0.0.1:8000",
    [ValidateSet("debug", "profile", "release")]
    [string]$Mode = "profile",
    [switch]$RepairOnly
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$marker = Join-Path $PSScriptRoot "windows\flutter\ephemeral\cpp_client_wrapper\core_implementations.cc"

function Stop-StaleRunner {
    cmd /c "taskkill /F /IM stday.exe /T 2>nul" | Out-Null
}

function Repair-Ephemeral {
    param([string]$BuildMode = "debug")
    Write-Host ">> Repairing Windows ephemeral (build mode: $BuildMode)..." -ForegroundColor Yellow
    Stop-StaleRunner
    if (Test-Path ".dart_tool\flutter_build") {
        Remove-Item -Recurse -Force ".dart_tool\flutter_build"
    }
    if (Test-Path "build\windows") {
        Remove-Item -Recurse -Force "build\windows"
    }
    if (Test-Path "windows\flutter\ephemeral") {
        try {
            Remove-Item -Recurse -Force "windows\flutter\ephemeral" -ErrorAction Stop
        } catch {
            cmd /c "rd /s /q `"$PSScriptRoot\windows\flutter\ephemeral`"" | Out-Null
        }
    }
    flutter clean | Out-Null
    flutter pub get
    $buildArgs = @(
        "build", "windows",
        "--dart-define=API_BASE_URL=$ApiBaseUrl"
    )
    if ($BuildMode -eq "release") {
        $buildArgs += "--release"
    } else {
        $buildArgs += "--debug"
    }
    flutter @buildArgs
    if (-not (Test-Path $marker)) {
        throw "Repair failed: cpp_client_wrapper still missing. Run: flutter doctor -v"
    }
    Write-Host ">> Repair done." -ForegroundColor Green
}

function Test-EphemeralReady {
    $wrapper = Join-Path $PSScriptRoot "windows\flutter\ephemeral\cpp_client_wrapper"
    if (-not (Test-Path $marker)) { return $false }
    $required = @(
        "core_implementations.cc",
        "standard_codec.cc",
        "flutter_engine.cc",
        "flutter_view_controller.cc",
        "plugin_registrar.cc"
    )
    foreach ($name in $required) {
        if (-not (Test-Path (Join-Path $wrapper $name))) { return $false }
    }
    return $true
}

$repairBuildMode = if ($Mode -eq "release") { "release" } else { "debug" }
if (-not (Test-EphemeralReady)) {
    Repair-Ephemeral -BuildMode $repairBuildMode
}

if ($RepairOnly) {
    Write-Host ">> Repair-only finished." -ForegroundColor Green
    exit 0
}

Stop-StaleRunner
$runArgs = @(
    "run",
    "-d", "windows",
    "--dart-define=API_BASE_URL=$ApiBaseUrl"
)
switch ($Mode) {
    "profile" { $runArgs += "--profile" }
    "release" { $runArgs += "--release" }
    default   { }
}
Write-Host ">> Flutter mode: $Mode" -ForegroundColor Cyan
flutter @runArgs @args
