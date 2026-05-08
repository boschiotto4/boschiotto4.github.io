param(
    [string]$Version,
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",
    [switch]$SkipLefty
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
}

Write-Host "Publishing all artifacts with version $Version ($Configuration)..."

& (Join-Path $PSScriptRoot "publish-tabdocks.ps1") -Version $Version -Configuration $Configuration
& (Join-Path $PSScriptRoot "publish-controllerdll.ps1") -Version $Version -Configuration $Configuration
& (Join-Path $PSScriptRoot "publish-remotecontroldll.ps1") -Version $Version -Configuration $Configuration

if (-not $SkipLefty) {
    & (Join-Path $PSScriptRoot "publish-lefty.ps1") -Version $Version -Configuration $Configuration
}

Write-Host "All publish steps completed."
