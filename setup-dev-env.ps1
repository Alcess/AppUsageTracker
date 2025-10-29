#!/usr/bin/env pwsh

Write-Host "Setting up AppUsageTracker development environment..." -ForegroundColor Green
Write-Host ""

# Copy environment file if it doesn't exist
if (-not (Test-Path ".env")) {
    Write-Host "Copying .env.example to .env..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "Please edit .env file with your actual Firebase API key" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host ".env file already exists" -ForegroundColor Gray
    Write-Host ""
}

# Copy google-services.json template if it doesn't exist
if (-not (Test-Path "android/app/google-services.json")) {
    Write-Host "Copying google-services.json template..." -ForegroundColor Yellow
    Copy-Item "android/app/google-services.json.template" "android/app/google-services.json"
    Write-Host "Please edit android/app/google-services.json with your actual Firebase configuration" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "google-services.json already exists" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Setup complete! Please:" -ForegroundColor Green
Write-Host "1. Edit .env with your Firebase API key" -ForegroundColor White
Write-Host "2. Edit android/app/google-services.json with your Firebase configuration" -ForegroundColor White
Write-Host "3. Run 'flutter pub get' to install dependencies" -ForegroundColor White
Write-Host ""
Write-Host "See ENVIRONMENT_SETUP.md for detailed instructions." -ForegroundColor Cyan

Read-Host "Press Enter to continue"