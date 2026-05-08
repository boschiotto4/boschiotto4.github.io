param(
    [string]$Version,
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

$siteRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\")).Path
$tabDocksRoot = "C:\Home\DEV\TabDocks"
$publisher = Join-Path $tabDocksRoot "publish_release_to_portal.ps1"

if (-not (Test-Path $publisher)) {
    throw "TabDocks publish script not found at $publisher"
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
}

Write-Host "Publishing TabDocks $Version ($Configuration)..."
& $publisher -Version $Version -Configuration $Configuration -GithubSitePath $siteRoot

if ($LASTEXITCODE -ne 0) {
    throw "TabDocks publish failed."
}

Write-Host "Done. Artifact copied into $siteRoot\downloads"
