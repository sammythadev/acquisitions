@echo off
REM Development startup script for Acquisition App with Neon Local (Windows)
REM Safe against npm warnings / non-zero exit codes

setlocal EnableDelayedExpansion

echo.
echo 🚀 Starting Acquisition App in Development Mode
echo ================================================
echo.

REM Ensure script runs from project root
cd /d "%~dp0\.."

REM Check if .env.development exists
if not exist ".env.development" (
    echo ❌ Error: .env.development file not found!
    echo    Please create it before running this script.
    pause
    exit /b 1
)

REM Check Docker
docker info >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: Docker is not running!
    echo    Start Docker Desktop and try again.
    pause
    exit /b 1
)

REM Ensure .neon_local exists
if not exist ".neon_local" (
    mkdir ".neon_local"
    echo ✅ Created .neon_local directory
)

REM Ensure .gitignore contains .neon_local
if exist ".gitignore" (
    findstr /C:".neon_local/" .gitignore >nul
    if errorlevel 1 (
        echo .neon_local/>> .gitignore
        echo ✅ Added .neon_local/ to .gitignore
    )
) else (
    echo .neon_local/> .gitignore
    echo ✅ Created .gitignore
)

echo.
echo 📜 Running database migrations (non-fatal)...
echo ------------------------------------------------

REM Check npm
where npm >nul 2>&1
if errorlevel 1 (
    echo ⚠️ npm not found — skipping migrations
) else (
    REM IMPORTANT: call + ignore exit code
    call npm run db:migrate
    echo ℹ️ Migration step completed (warnings ignored)
)

echo.
echo ⏳ Waiting for services to stabilize...
timeout /t 5 /nobreak >nul

echo.
echo 🐳 Starting Docker development environment...
echo ------------------------------------------------

REM Docker must ALWAYS start
docker-compose -f docker-compose.dev.yml --env-file .env.development up --build

echo.
echo 🛑 Development environment stopped
echo ------------------------------------------------
echo To restart: run this script again
echo To clean up: docker-compose -f docker-compose.dev.yml down
pause
