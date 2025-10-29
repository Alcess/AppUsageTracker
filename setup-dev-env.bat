@echo off
echo Setting up AppUsageTracker development environment...
echo.

REM Copy environment file if it doesn't exist
if not exist ".env" (
    echo Copying .env.example to .env...
    copy ".env.example" ".env"
    echo Please edit .env file with your actual Firebase API key
    echo.
) else (
    echo .env file already exists
    echo.
)

REM Copy google-services.json template if it doesn't exist
if not exist "android\app\google-services.json" (
    echo Copying google-services.json template...
    copy "android\app\google-services.json.template" "android\app\google-services.json"
    echo Please edit android\app\google-services.json with your actual Firebase configuration
    echo.
) else (
    echo google-services.json already exists
    echo.
)

echo Setup complete! Please:
echo 1. Edit .env with your Firebase API key
echo 2. Edit android\app\google-services.json with your Firebase configuration
echo 3. Run 'flutter pub get' to install dependencies
echo.
echo See ENVIRONMENT_SETUP.md for detailed instructions.
pause