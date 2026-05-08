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
$leftyRoot = "C:\Home\DEV\Android\Lefty"
$downloadsDir = Join-Path $siteRoot "downloads"
$outputApk = Join-Path $downloadsDir "Lefty-$Version.apk"
$latestApk = Join-Path $downloadsDir "Lefty-latest.apk"
$manifestPath = Join-Path $downloadsDir "lefty-releases.json"

if (-not (Test-Path (Join-Path $leftyRoot "gradlew.bat"))) {
    throw "gradlew.bat not found in $leftyRoot"
}

New-Item -ItemType Directory -Path $downloadsDir -Force | Out-Null

Push-Location $leftyRoot
try {
    if ($Configuration -eq "Release") {
        & .\gradlew.bat clean assembleRelease
        $apkSource = Join-Path $leftyRoot "app\build\outputs\apk\release\app-release.apk"
    }
    else {
        & .\gradlew.bat clean assembleDebug
        $apkSource = Join-Path $leftyRoot "app\build\outputs\apk\debug\app-debug.apk"
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Lefty Gradle build failed."
    }

    if (-not (Test-Path $apkSource)) {
        throw "Expected APK not found at $apkSource"
    }

    Copy-Item -Path $apkSource -Destination $outputApk -Force
    Copy-Item -Path $apkSource -Destination $latestApk -Force
}
finally {
    Pop-Location
}

$sizeBytes = (Get-Item $outputApk).Length
$createdUtc = (Get-Date).ToUniversalTime().ToString("o")
$hash = (Get-FileHash -Path $outputApk -Algorithm SHA256).Hash.ToLowerInvariant()

$entries = @()
if (Test-Path $manifestPath) {
    try {
        $raw = Get-Content -Raw -Path $manifestPath
        if (-not [string]::IsNullOrWhiteSpace($raw)) {
            $decoded = $raw | ConvertFrom-Json
            if ($decoded -is [System.Array]) {
                $entries = @($decoded)
            }
            elseif ($decoded -is [pscustomobject]) {
                $entries = @($decoded)
            }
        }
    }
    catch {
        $entries = @()
    }
}

$fileName = [IO.Path]::GetFileName($outputApk)
$entries = @($entries | Where-Object { $_.fileName -ne $fileName })
$newEntry = [pscustomobject]@{
    fileName = $fileName
    version = $Version
    configuration = $Configuration
    createdUtc = $createdUtc
    sizeBytes = [int64]$sizeBytes
    sha256 = $hash
}

@($newEntry + $entries) | Select-Object -First 25 | ConvertTo-Json -Depth 3 | Set-Content -Path $manifestPath -Encoding UTF8

Write-Host "Published: $outputApk"
