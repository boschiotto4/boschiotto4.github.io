param(
    [string]$Version,
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",
    [switch]$SkipLefty,
    [switch]$SkipApks
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
}

Write-Host "Publishing all artifacts with version $Version ($Configuration)..."

& (Join-Path $PSScriptRoot "publish-tabdocks.ps1") -Version $Version -Configuration $Configuration
& (Join-Path $PSScriptRoot "publish-controllerdll.ps1") -Version $Version -Configuration $Configuration
& (Join-Path $PSScriptRoot "publish-remotecontroldll.ps1") -Version $Version -Configuration $Configuration
& (Join-Path $PSScriptRoot "publish-esp32.ps1") -Version $Version -Configuration $Configuration

if (-not $SkipLefty) {
    & (Join-Path $PSScriptRoot "publish-lefty.ps1") -Version $Version -Configuration $Configuration
}

if (-not $SkipApks) {
    Write-Host "Publishing Android APKs..."
    & (Join-Path $PSScriptRoot "publish-remotecontrol-apk.ps1") -Version $Version -Configuration $Configuration
    & (Join-Path $PSScriptRoot "publish-esp32-apk.ps1") -Version $Version -Configuration $Configuration
}

Write-Host "All publish steps completed."
