@echo off
REM Database management script for Acquisitions API
REM This script provides database operations for both dev and prod environments

setlocal EnableDelayedExpansion

if "%1"=="" goto :show_help
if "%1"=="help" goto :show_help
if "%1"=="-h" goto :show_help
if "%1"=="--help" goto :show_help

set "ENV=dev"
set "OPERATION=%1"

REM Parse environment parameter
if "%2"=="prod" set "ENV=prod"
if "%2"=="production" set "ENV=prod"

echo.
echo 🗄️ Database Manager - %ENV% Environment
echo ========================================
echo.

REM Navigate to parent directory
cd ..

REM Set compose file and env file based on environment
if "%ENV%"=="prod" (
    set "COMPOSE_FILE=docker-compose.prod.yml"
    set "ENV_FILE=.env.production"
    set "CONTAINER_NAME=acquisitions-app-prod"
) else (
    set "COMPOSE_FILE=docker-compose.dev.yml"
    set "ENV_FILE=.env.development"
    set "CONTAINER_NAME=acquisitions-app-dev"
)

REM Check if environment file exists
if not exist "%ENV_FILE%" (
    echo ❌ Error: %ENV_FILE% not found!
    echo    Please create the environment file first.
    pause
    exit /b 1
)

REM Check if containers are running
docker-compose -f %COMPOSE_FILE% ps | findstr "Up" >nul
if !errorlevel! neq 0 (
    echo ❌ Error: %ENV% containers are not running!
    echo    Start the environment first with scripts\%ENV%.bat
    pause
    exit /b 1
)

REM Execute the requested operation
if "%OPERATION%"=="migrate" goto :migrate
if "%OPERATION%"=="generate" goto :generate
if "%OPERATION%"=="studio" goto :studio
if "%OPERATION%"=="reset" goto :reset
if "%OPERATION%"=="seed" goto :seed

echo ❌ Unknown operation: %OPERATION%
goto :show_help

:migrate
echo 📜 Applying database migrations...
if "%ENV%"=="prod" (
    echo ⚠️  WARNING: Applying migrations to PRODUCTION database!
    set /p "confirm=Continue? (y/N): "
    if /i "!confirm!" neq "y" (
        echo Operation cancelled.
        pause
        exit /b 0
    )
)
docker-compose -f %COMPOSE_FILE% exec app npm run db:migrate
if !errorlevel! equ 0 (
    echo ✅ Migrations applied successfully
) else (
    echo ❌ Migration failed
)
goto :end

:generate
if "%ENV%"=="prod" (
    echo ❌ Migration generation not recommended in production environment
    echo    Generate migrations in development environment instead
    pause
    exit /b 1
)
echo 📝 Generating database migrations...
docker-compose -f %COMPOSE_FILE% exec app npm run db:generate
if !errorlevel! equ 0 (
    echo ✅ Migrations generated successfully
    echo 📁 Check ./drizzle/ directory for new migration files
) else (
    echo ❌ Migration generation failed
)
goto :end

:studio
if "%ENV%"=="prod" (
    echo ❌ Drizzle Studio not recommended for production environment
    echo    Use a proper database client for production access
    pause
    exit /b 1
)
echo 🎨 Opening Drizzle Studio...
echo    This will open in your web browser
echo    Press Ctrl+C to stop Drizzle Studio
echo.
docker-compose -f %COMPOSE_FILE% exec app npm run db:studio
goto :end

:reset
if "%ENV%"=="prod" (
    echo ❌ Database reset not allowed in production environment
    echo    This operation is too dangerous for production use
    pause
    exit /b 1
)
echo 🚨 DATABASE RESET WARNING
echo This will permanently delete ALL data in the database!
echo.
set /p "confirm=Type 'RESET' to confirm database reset: "
if /i "!confirm!" neq "RESET" (
    echo Cancelled - confirmation text did not match
    pause
    exit /b 0
)
echo 🗑️ Resetting database...
echo Recreating development containers for fresh database...
docker-compose -f %COMPOSE_FILE% --env-file %ENV_FILE% down
docker-compose -f %COMPOSE_FILE% --env-file %ENV_FILE% up -d
echo ⏳ Waiting for services to restart...
timeout /t 15 /nobreak >nul
echo Applying migrations to fresh database...
docker-compose -f %COMPOSE_FILE% exec app npm run db:migrate
echo ✅ Database reset completed
goto :end

:seed
echo 🌱 Seeding database with initial data...
if "%ENV%"=="prod" (
    echo ⚠️  WARNING: Seeding PRODUCTION database!
    set /p "confirm=Continue? (y/N): "
    if /i "!confirm!" neq "y" (
        echo Operation cancelled.
        pause
        exit /b 0
    )
)
REM Check if seed script exists
docker-compose -f %COMPOSE_FILE% exec app npm run db:seed 2>nul
if !errorlevel! equ 0 (
    echo ✅ Database seeded successfully
) else (
    echo ⚠️ No 'db:seed' script found in package.json
    echo To enable database seeding, add a seed script to your package.json:
    echo    "db:seed": "node scripts/seed.js"
)
goto :end

:show_help
echo Database Management Script
echo.
echo USAGE:
echo    scripts\db.bat ^<operation^> [environment]
echo.
echo OPERATIONS:
echo    migrate    Apply pending migrations to database
echo    generate   Generate new database migrations (dev only)
echo    studio     Open Drizzle Studio (dev only)
echo    reset      Reset database (WARNING: destructive, dev only)
echo    seed       Seed database with initial data
echo.
echo ENVIRONMENTS:
echo    dev        Development environment (default)
echo    prod       Production environment
echo.
echo EXAMPLES:
echo    scripts\db.bat migrate          # Apply migrations (dev)
echo    scripts\db.bat migrate prod     # Apply migrations (prod)
echo    scripts\db.bat generate         # Generate migrations (dev)
echo    scripts\db.bat studio           # Open Drizzle Studio (dev)
echo    scripts\db.bat reset            # Reset database (dev only)
echo.
pause
exit /b 0

:end
echo.
pause