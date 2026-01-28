@echo off
REM Acquisitions API - Development Setup Batch Wrapper
REM This batch file helps run PowerShell scripts even with restricted execution policies

echo.
echo 🚀 Acquisitions API - Development Setup
echo =========================================
echo.

REM Check if PowerShell is available
where powershell >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ❌ PowerShell is not available on this system
    echo    Please install PowerShell or use PowerShell Core
    pause
    exit /b 1
)

REM Check if Docker is running
docker version >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ❌ Docker is not running or not installed
    echo    Please start Docker Desktop and try again
    pause
    exit /b 1
)

echo ✅ Prerequisites check passed
echo.

REM Parse command line arguments
set "PS_ARGS="
:parse_args
if "%1"=="" goto :run_script
if /I "%1"=="-Build" set "PS_ARGS=%PS_ARGS% -Build"
if /I "%1"=="-Down" set "PS_ARGS=%PS_ARGS% -Down"
if /I "%1"=="-Logs" set "PS_ARGS=%PS_ARGS% -Logs"
if /I "%1"=="-Shell" set "PS_ARGS=%PS_ARGS% -Shell"
if /I "%1"=="-Help" set "PS_ARGS=%PS_ARGS% -Help"
shift
goto :parse_args

:run_script
REM Run PowerShell script with bypass execution policy
echo Running: powershell -ExecutionPolicy Bypass -File "setup-dev.ps1" %PS_ARGS%
echo.
powershell -ExecutionPolicy Bypass -File "setup-dev.ps1" %PS_ARGS%

if %ERRORLEVEL% neq 0 (
    echo.
    echo ❌ Script execution failed
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ✅ Setup completed successfully
pause