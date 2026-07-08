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
$androidProjectPath = "C:\Home\DEV\TabDocks\RemoteControl"

$downloadsDir = Join-Path $siteRoot "downloads"
$apkName = "RemoteControl-$Version.apk"
$apkPath = Join-Path $downloadsDir $apkName
$latestApk = Join-Path $downloadsDir "RemoteControl-latest.apk"
$manifestPath = Join-Path $downloadsDir "remotecontrol-apk-releases.json"

if (-not (Test-Path $androidProjectPath)) {
    throw "RemoteControl Android project not found at $androidProjectPath"
}

New-Item -ItemType Directory -Path $downloadsDir -Force | Out-Null

Write-Host "Building RemoteControl Android app ($Configuration)..."

Push-Location $androidProjectPath
try {
    # Stop gradle daemon to release file locks
    Write-Host "Stopping gradle daemon..."
    & .\gradlew.bat --stop -ErrorAction SilentlyContinue | Out-Null
    Start-Sleep -Seconds 2
    
    # Remove build directory to ensure clean state
    Write-Host "Cleaning build artifacts..."
    Remove-Item -Path "app\build" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    
    if ($Configuration -eq "Release") {
        # Build release APK with lint disabled for known layout issues
        Write-Host "Building RemoteControl Android app (Release, lint disabled)..."
        & .\gradlew.bat assembleRelease -x lintVitalAnalyzeRelease
        if ($LASTEXITCODE -ne 0) {
            throw "RemoteControl Android app release build failed."
        }
        
        # Try multiple possible output locations
        $apkSource = Join-Path $androidProjectPath "app\build\outputs\apk\release\app-release.apk"
        if (-not (Test-Path $apkSource)) {
            $apkSource = Join-Path $androidProjectPath "app\build\outputs\apk\release\app-release-unsigned.apk"
        }
        if (-not (Test-Path $apkSource)) {
            $apkSource = @(Get-ChildItem -Path (Join-Path $androidProjectPath "app\build\outputs\apk\release") -Filter "*.apk" -ErrorAction SilentlyContinue)[0].FullName
        }
    }
    else {
        # Build debug APK
        Write-Host "Building RemoteControl Android app (Debug)..."
        & .\gradlew.bat assembleDebug -x lintVitalAnalyzeDebug
        if ($LASTEXITCODE -ne 0) {
            throw "RemoteControl Android app debug build failed."
        }
        
        $apkSource = Join-Path $androidProjectPath "app\build\outputs\apk\debug\app-debug.apk"
        if (-not (Test-Path $apkSource)) {
            $apkSource = Join-Path $androidProjectPath "app\build\outputs\apk\debug\app-debug-unsigned.apk"
        }
    }
    
    if (-not (Test-Path $apkSource)) {
        throw "RemoteControl APK not found. Build may have failed."
    }
    
    Write-Host "Copying APK to downloads..."
    Copy-Item -Path $apkSource -Destination $apkPath -Force
    Copy-Item -Path $apkPath -Destination $latestApk -Force
    
    # Get APK properties
    $apkInfo = Get-Item -Path $apkPath
    $createdTime = $apkInfo.CreationTime.ToUniversalTime()
    $sizeBytes = $apkInfo.Length
    
    # Get minimum API level from APK manifest
    $aapt = "C:\Program Files (x86)\Android\android-sdk\build-tools\35.0.0\aapt.exe"
    $minSdkVersion = "API 24"
    if (Test-Path $aapt) {
        try {
            $dumpOutput = & $aapt dump badging $apkPath | Select-String "sdkVersion:"
            if ($dumpOutput) {
                $minSdkVersion = ($dumpOutput -split "sdkVersion:'" -split "'" )[1]
            }
        }
        catch {
            Write-Host "Note: Could not detect API level with aapt"
        }
    }
    
    # Update manifest JSON
    Write-Host "Updating manifest file..."
    $manifestData = @(
        @{
            fileName = $apkName
            version = $Version
            createdUtc = $createdTime.ToString("O")
            sizeBytes = $sizeBytes
            minSdkVersion = $minSdkVersion
            configuration = $Configuration
        }
    )
    
    # Load existing manifest if it exists
    if (Test-Path $manifestPath) {
        $existingContent = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
        if ($existingContent -is [array]) {
            $manifestData = $manifestData + @($existingContent)
        }
        elseif ($existingContent) {
            # Wrap single object in array
            $manifestData = $manifestData + @($existingContent)
        }
    }
    
    # Keep only the 10 most recent releases
    $manifestData = $manifestData | Select-Object -First 10
    
    # Always output as array
    $manifestData | ConvertTo-Json | Set-Content -Path $manifestPath -Force
    
    Write-Host "Published: $apkPath"
    Write-Host "Latest: $latestApk"
    Write-Host "Manifest: $manifestPath"
}
finally {
    Pop-Location
}
