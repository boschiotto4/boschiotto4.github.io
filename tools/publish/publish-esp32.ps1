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
$esp32Root = "C:\Home\DEV\ESP32"
$downloadsDir = Join-Path $siteRoot "downloads"
$outputZip = Join-Path $downloadsDir "ESP32-Daikin-$Version.zip"
$latestZip = Join-Path $downloadsDir "ESP32-Daikin-latest.zip"
$manifestPath = Join-Path $downloadsDir "esp32-releases.json"

if (-not (Test-Path $esp32Root)) {
    throw "ESP32 project not found at $esp32Root"
}

New-Item -ItemType Directory -Path $downloadsDir -Force | Out-Null

Push-Location $esp32Root
try {
    Write-Host "Building ESP32 firmware..."
    
    # Build ESP32 firmware with PlatformIO
    & pio run --environment esp32dev
    if ($LASTEXITCODE -ne 0) {
        throw "ESP32 firmware build failed."
    }
    
    $firmwareBin = Join-Path $esp32Root ".pio\build\esp32dev\firmware.bin"
    if (-not (Test-Path $firmwareBin)) {
        throw "Firmware binary not found at $firmwareBin"
    }
    
    Write-Host "Building Android app..."
    
    # Build Android app
    Push-Location (Join-Path $esp32Root "android-app")
    try {
        if ($Configuration -eq "Release") {
            & .\gradlew.bat clean assembleRelease
            $apkSource = Join-Path $esp32Root "android-app\app\build\outputs\apk\release\app-release.apk"
            if (-not (Test-Path $apkSource)) {
                $apkSource = Join-Path $esp32Root "android-app\app\build\outputs\apk\release\app-release-unsigned.apk"
            }
        }
        else {
            & .\gradlew.bat clean assembleDebug
            $apkSource = Join-Path $esp32Root "android-app\app\build\outputs\apk\debug\app-debug.apk"
            if (-not (Test-Path $apkSource)) {
                $apkSource = Join-Path $esp32Root "android-app\app\build\outputs\apk\debug\app-debug-unsigned.apk"
            }
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "Android app build failed."
        }
        
        if (-not (Test-Path $apkSource)) {
            throw "APK not found at $apkSource"
        }
    }
    finally {
        Pop-Location
    }
    
    # Create release package
    Write-Host "Creating release package..."
    
    $tempDir = Join-Path $env:TEMP "esp32-daikin-$Version"
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Copy firmware
    $firmwareDir = Join-Path $tempDir "firmware"
    New-Item -ItemType Directory -Path $firmwareDir -Force | Out-Null
    Copy-Item -Path $firmwareBin -Destination (Join-Path $firmwareDir "firmware.bin") -Force
    
    # Copy bootloader and partition table from PlatformIO build
    $bootloaderBin = Join-Path $esp32Root ".pio\build\esp32dev\bootloader.bin"
    $partitionsBin = Join-Path $esp32Root ".pio\build\esp32dev\partitions.bin"
    if (Test-Path $bootloaderBin) {
        Copy-Item -Path $bootloaderBin -Destination (Join-Path $firmwareDir "bootloader.bin") -Force
    }
    if (Test-Path $partitionsBin) {
        Copy-Item -Path $partitionsBin -Destination (Join-Path $firmwareDir "partitions.bin") -Force
    }
    
    # Copy Android APK
    Copy-Item -Path $apkSource -Destination (Join-Path $tempDir "DaikinESP32Controller.apk") -Force
    
    # Copy documentation
    Copy-Item -Path (Join-Path $esp32Root "ANDROID_ESP32_SETUP.md") -Destination $tempDir -Force
    if (Test-Path (Join-Path $esp32Root "ROUTINE_DURATION_GUIDE.md")) {
        Copy-Item -Path (Join-Path $esp32Root "ROUTINE_DURATION_GUIDE.md") -Destination $tempDir -Force
    }
    
    # Create README for the package
    $readme = @"
# ESP32 Daikin AC Controller - Release $Version

## Contents

- **firmware/** - ESP32 firmware binaries
  - firmware.bin - Main firmware (flash at 0x10000)
  - bootloader.bin - ESP32 bootloader (flash at 0x1000)
  - partitions.bin - Partition table (flash at 0x8000)
  
- **DaikinESP32Controller.apk** - Android controller app

- **ANDROID_ESP32_SETUP.md** - Setup and usage instructions

## Quick Start

### Flash ESP32 Firmware

Using esptool.py:
``````
esptool.py --chip esp32 --port COM3 --baud 460800 write_flash -z 0x1000 firmware/bootloader.bin 0x8000 firmware/partitions.bin 0x10000 firmware/firmware.bin
``````

Or use PlatformIO from the source repository.

### Install Android App

1. Transfer DaikinESP32Controller.apk to your Android device
2. Enable "Install from unknown sources" in device settings
3. Install the APK
4. Connect to ESP32-DAIKIN Wi-Fi network (password: 12345678)
5. Open the app (host should be 192.168.4.1)

## ESP32 Control AP

- SSID: ESP32-DAIKIN
- Password: 12345678
- IP: 192.168.4.1

## Documentation

See ANDROID_ESP32_SETUP.md for complete setup and API documentation.
"@
    
    Set-Content -Path (Join-Path $tempDir "README.md") -Value $readme -Encoding UTF8
    
    # Create ZIP package
    Compress-Archive -Path "$tempDir\*" -DestinationPath $outputZip -Force
    Copy-Item -Path $outputZip -Destination $latestZip -Force
    
    # Clean up temp directory
    Remove-Item -Path $tempDir -Recurse -Force
    
    # Update manifest JSON
    $sizeBytes = (Get-Item $outputZip).Length
    $createdUtc = (Get-Date).ToUniversalTime().ToString("o")
    $hash = (Get-FileHash -Path $outputZip -Algorithm SHA256).Hash.ToLowerInvariant()
    
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
    
    $fileName = [IO.Path]::GetFileName($outputZip)
    $entries = @($entries | Where-Object { $_.fileName -ne $fileName })
    $newEntry = [pscustomobject]@{
        fileName = $fileName
        version = $Version
        configuration = $Configuration
        createdUtc = $createdUtc
        sizeBytes = [int64]$sizeBytes
        sha256 = $hash
    }
    
    $allEntries = @($newEntry) + @($entries)
    $topEntries = @($allEntries | Select-Object -First 25)
    if ($topEntries.Count -eq 1) {
        "[$($topEntries | ConvertTo-Json -Depth 3)]" | Set-Content -Path $manifestPath -Encoding UTF8
    } else {
        $topEntries | ConvertTo-Json -Depth 3 | Set-Content -Path $manifestPath -Encoding UTF8
    }
    
    Write-Host "Published: $outputZip"
    Write-Host "Latest: $latestZip"
}
finally {
    Pop-Location
}
