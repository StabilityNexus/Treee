# Flutter Setup Script for Windows
# Run as Administrator

Write-Host "=== Flutter Setup Script ===" -ForegroundColor Green

# 1. Download Flutter
Write-Host "`n[1/4] Downloading Flutter SDK..." -ForegroundColor Cyan
$flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.16.0-stable.zip"
$downloadPath = "$env:TEMP\flutter.zip"
$extractPath = "C:\src"

# Create directory
if (!(Test-Path $extractPath)) {
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
}

# Download
try {
    Invoke-WebRequest -Uri $flutterUrl -OutFile $downloadPath -UseBasicParsing
    Write-Host "✓ Downloaded successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Download failed: $_" -ForegroundColor Red
    exit 1
}

# 2. Extract Flutter
Write-Host "`n[2/4] Extracting Flutter..." -ForegroundColor Cyan
try {
    Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force
    Write-Host "✓ Extracted successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Extraction failed: $_" -ForegroundColor Red
    exit 1
}

# 3. Add Flutter to PATH
Write-Host "`n[3/4] Adding Flutter to PATH..." -ForegroundColor Cyan
$flutterPath = "C:\src\flutter\bin"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($currentPath -notlike "*$flutterPath*") {
    [Environment]::SetEnvironmentVariable(
        "Path",
        "$currentPath;$flutterPath",
        "User"
    )
    Write-Host "✓ Flutter added to PATH" -ForegroundColor Green
} else {
    Write-Host "✓ Flutter already in PATH" -ForegroundColor Green
}

# 4. Run flutter doctor
Write-Host "`n[4/4] Verifying installation..." -ForegroundColor Cyan
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

& "C:\src\flutter\bin\flutter.bat" doctor

Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Close and reopen PowerShell"
Write-Host "2. Navigate to: cd C:\Users\achal\Desktop\Treee"
Write-Host "3. Run: flutter pub get"
Write-Host "4. Run: flutter run"
