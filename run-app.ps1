# Flutter Run Script
# This script will build and run your Flutter app

Write-Host "=== Flutter App Builder ===" -ForegroundColor Green

$projectPath = "C:\Users\achal\Desktop\Treee"
Set-Location $projectPath

Write-Host "`n[1/3] Getting dependencies..." -ForegroundColor Cyan
& flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to get dependencies" -ForegroundColor Red
    exit 1
}

Write-Host "`n[2/3] Building for web..." -ForegroundColor Cyan
& flutter build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to build" -ForegroundColor Red
    exit 1
}

Write-Host "`n[3/3] Web build ready!" -ForegroundColor Green
Write-Host "Build output: $projectPath\build\web" -ForegroundColor Yellow
Write-Host "`nTo deploy:" -ForegroundColor Cyan
Write-Host "1. Sign up at firebase.google.com"
Write-Host "2. Create new project"
Write-Host "3. Run: npm install -g firebase-tools"
Write-Host "4. Run: firebase login"
Write-Host "5. Run: firebase init hosting"
Write-Host "6. Run: firebase deploy"
