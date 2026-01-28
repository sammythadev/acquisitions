@echo off
REM Stop development environment script
REM This script stops and cleans up the development Docker containers

setlocal EnableDelayedExpansion

echo.
echo 🛑 Stopping Acquisition App Development Environment
echo ====================================================
echo.

REM Navigate to parent directory for Docker commands
cd ..

REM Check if .env.development exists
if not exist ".env.development" (
    echo ❌ Error: .env.development not found in root directory!
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

REM Stop and remove containers
echo 📦 Stopping development containers...
docker-compose -f docker-compose.dev.yml --env-file .env.development down

if !errorlevel! equ 0 (
    echo ✅ Development environment stopped successfully
) else (
    echo ⚠️ Warning: Some errors occurred while stopping containers
)

REM Show remaining containers (if any)
echo.
echo 🔍 Remaining containers:
docker ps -a --filter "name=acquisitions" --filter "name=neon-local"

REM Optional: Remove volumes
echo.
set /p "remove_volumes=Do you want to remove associated volumes? (y/N): "
if /i "!remove_volumes!" equ "y" (
    echo 🗑️ Removing volumes...
    docker-compose -f docker-compose.dev.yml --env-file .env.development down -v
    echo ✅ Volumes removed
)

REM Optional: Remove images
echo.
set /p "remove_images=Do you want to remove built images? (y/N): "
if /i "!remove_images!" equ "y" (
    echo 🗑️ Removing images...
    docker-compose -f docker-compose.dev.yml --env-file .env.development down --rmi all
    echo ✅ Images removed
)

echo.
echo 🎉 Development environment cleanup completed!
echo.
echo To start again, run: scripts\dev.bat
echo To clean up Docker system: docker system prune
pause