param(
    [string]$Version,
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
}

Write-Host "Publishing all Android APKs with version $Version ($Configuration)..."

& (Join-Path $PSScriptRoot "publish-remotecontrol-apk.ps1") -Version $Version -Configuration $Configuration
& (Join-Path $PSScriptRoot "publish-esp32-apk.ps1") -Version $Version -Configuration $Configuration

Write-Host "All APK publish steps completed."
