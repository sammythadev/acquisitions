@echo off
REM Stop production environment script
REM This script stops the production Docker containers with safety confirmations

setlocal EnableDelayedExpansion

echo.
echo 🛑 Stopping Acquisition App Production Environment
echo ===================================================
echo.

REM Navigate to parent directory for Docker commands
cd ..

REM Check if .env.production exists
if not exist ".env.production" (
    echo ❌ Error: .env.production not found in root directory!
    echo    Make sure you're running this from the scripts directory
    pause
    exit /b 1
)

REM Check if Docker is running
docker info >nul 2>&1
if !errorlevel! neq 0 (
    echo ❌ Error: Docker is not running!
    echo    Cannot stop containers if Docker is not running.
    pause
    exit /b 1
)

REM Production warning
echo ⚠️  WARNING: You are about to stop the PRODUCTION environment!
echo    This will take down your live application.
echo.
set /p "confirm=Are you sure you want to continue? (y/N): "
if /i "!confirm!" neq "y" (
    echo Operation cancelled.
    pause
    exit /b 0
)

REM Show current status
echo 📊 Current production containers:
docker-compose -f docker-compose.prod.yml ps

REM Final confirmation
echo.
set /p "final_confirm=Last chance! Type 'STOP' to confirm shutdown: "
if /i "!final_confirm!" neq "STOP" (
    echo Operation cancelled.
    pause
    exit /b 0
)

REM Stop production containers
echo.
echo 📦 Stopping production containers...
docker-compose -f docker-compose.prod.yml --env-file .env.production down

if !errorlevel! equ 0 (
    echo ✅ Production environment stopped successfully
) else (
    echo ⚠️ Warning: Some errors occurred while stopping containers
    echo Check Docker logs for details
)

REM Show final status
echo.
echo 🔍 Remaining production containers:
docker ps -a --filter "name=acquisitions-app-prod"

REM Optional: Remove volumes (with extra warning)
echo.
echo ⚠️  DANGER ZONE ⚠️
set /p "remove_volumes=Remove production volumes? This deletes logs! (y/N): "
if /i "!remove_volumes!" equ "y" (
    echo 🗑️ Removing production volumes...
    docker-compose -f docker-compose.prod.yml --env-file .env.production down -v
    echo ✅ Production volumes removed
)

echo.
echo 🎉 Production environment shutdown completed!
echo.
echo Status: Application is now OFFLINE
echo.
echo To restart: scripts\prod.bat
echo To check system: docker system df
echo.
pause