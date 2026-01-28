@echo off
REM Production startup script for Acquisition App (Windows)

setlocal EnableDelayedExpansion

echo.
echo 🚀 Starting Acquisition App in PRODUCTION Mode
echo ===============================================
echo.

REM Ensure script runs from project root
cd /d "%~dp0\.."

REM Check if .env.production exists
if not exist ".env.production" (
    echo ❌ Error: .env.production file not found!
    echo    Production cannot start without environment variables.
    pause
    exit /b 1
)

REM Check Docker
docker info >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: Docker is not running!
    echo    Please start Docker Desktop and try again.
    pause
    exit /b 1
)

REM Ensure required directories exist
if not exist "logs" (
    mkdir "logs"
    echo ✅ Created logs directory
)

echo.
echo 🐳 Building and starting PRODUCTION containers...
echo ------------------------------------------------

REM Use production compose file
docker-compose -f docker-compose.prod.yml --env-file .env.production up --build -d

if errorlevel 1 (
    echo ❌ Docker failed to start production containers
    pause
    exit /b 1
)

echo.
echo ✅ Production environment started successfully
echo ------------------------------------------------
echo App is now running in detached mode
echo.
echo Useful commands:
echo   View logs:   docker-compose -f docker-compose.prod.yml logs -f
echo   Stop app:   docker-compose -f docker-compose.prod.yml down
echo.
pause
