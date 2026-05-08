param(
    [string]$Version,
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
}

$siteRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\")).Path
$repoRoot = "C:\Home\DEV\TabDocks"
$projectPath = Join-Path $repoRoot "RemoteControlDll\RemoteControlDll.csproj"

$outDir = Join-Path $repoRoot "artifacts\publish\RemoteControlDll\$Version"
$downloadsDir = Join-Path $siteRoot "downloads"
$zipName = "RemoteControlDll-$Version.zip"
$zipPath = Join-Path $downloadsDir $zipName
$latestPath = Join-Path $downloadsDir "RemoteControlDll-latest.zip"

if (-not (Test-Path $projectPath)) {
    throw "Project not found: $projectPath"
}

if (Test-Path $outDir) {
    Remove-Item -Path $outDir -Recurse -Force
}

New-Item -ItemType Directory -Path $outDir -Force | Out-Null
New-Item -ItemType Directory -Path $downloadsDir -Force | Out-Null

Write-Host "Building RemoteControlDll ($Configuration)..."
dotnet build $projectPath --configuration $Configuration /p:OutputPath="$outDir\" -v minimal
if ($LASTEXITCODE -ne 0) {
    throw "RemoteControlDll build failed."
}

if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}

Compress-Archive -Path (Join-Path $outDir "*") -DestinationPath $zipPath -CompressionLevel Optimal -Force
Copy-Item -Path $zipPath -Destination $latestPath -Force

Write-Host "Published: $zipPath"
