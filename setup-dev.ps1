# Acquisitions API - Development Setup Script for Windows
# This script sets up and runs the development environment with Neon Local

param(
    [switch]$Build,
    [switch]$Down,
    [switch]$Logs,
    [switch]$Shell,
    [switch]$Help
)

# Color functions for better output
function Write-Success { param($Message) Write-Host $Message -ForegroundColor Green }
function Write-Error { param($Message) Write-Host $Message -ForegroundColor Red }
function Write-Info { param($Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host $Message -ForegroundColor Yellow }

function Show-Help {
    Write-Host @"
Acquisitions API - Development Setup Script

USAGE:
    .\setup-dev.ps1 [OPTIONS]

OPTIONS:
    -Build     Force rebuild of Docker images
    -Down      Stop and remove all containers
    -Logs      Show application logs
    -Shell     Open shell in app container
    -Help      Show this help message

EXAMPLES:
    .\setup-dev.ps1                    # Start development environment
    .\setup-dev.ps1 -Build             # Rebuild and start
    .\setup-dev.ps1 -Down              # Stop all services
    .\setup-dev.ps1 -Logs              # View logs
    .\setup-dev.ps1 -Shell             # Access container shell

REQUIREMENTS:
    - Docker Desktop for Windows
    - Configured .env.development file
    - Neon API credentials

"@ -ForegroundColor White
}

function Test-Prerequisites {
    Write-Info "🔍 Checking prerequisites..."
    
    # Check if Docker is installed and running
    try {
        $dockerVersion = docker --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Docker not found"
        }
        Write-Success "✅ Docker is installed: $dockerVersion"
    }
    catch {
        Write-Error "❌ Docker is not installed or not running"
        Write-Error "   Please install Docker Desktop from: https://docs.docker.com/desktop/install/windows-install/"
        exit 1
    }

    # Check if Docker Compose is available
    try {
        $composeVersion = docker-compose --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Docker Compose not found"
        }
        Write-Success "✅ Docker Compose is available: $composeVersion"
    }
    catch {
        Write-Error "❌ Docker Compose is not available"
        Write-Error "   Docker Compose should be included with Docker Desktop"
        exit 1
    }

    # Check if environment file exists
    if (-not (Test-Path ".env.development")) {
        Write-Warning "⚠️  .env.development not found"
        Write-Info "Creating .env.development from template..."
        
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" ".env.development"
            Write-Success "✅ Created .env.development from template"
            Write-Warning "⚠️  Please edit .env.development with your Neon credentials:"
            Write-Info "   - NEON_API_KEY (from https://console.neon.tech)"
            Write-Info "   - NEON_PROJECT_ID (from your project settings)"
            Write-Info "   - PARENT_BRANCH_ID (usually 'main')"
            Write-Host ""
            Read-Host "Press Enter after configuring .env.development to continue"
        }
        else {
            Write-Error "❌ .env.example not found. Cannot create development environment file."
            exit 1
        }
    }
    else {
        Write-Success "✅ .env.development found"
    }

    # Check for required environment variables
    $envContent = Get-Content ".env.development" -Raw
    $missingVars = @()
    
    if ($envContent -notmatch "NEON_API_KEY=(?!your_neon_api_key)") {
        $missingVars += "NEON_API_KEY"
    }
    if ($envContent -notmatch "NEON_PROJECT_ID=(?!your_neon_project_id)") {
        $missingVars += "NEON_PROJECT_ID"
    }
    
    if ($missingVars.Count -gt 0) {
        Write-Warning "⚠️  Please configure the following variables in .env.development:"
        foreach ($var in $missingVars) {
            Write-Warning "   - $var"
        }
        Write-Info "Get these from: https://console.neon.tech"
        Read-Host "Press Enter after updating .env.development to continue"
    }
    else {
        Write-Success "✅ Environment variables configured"
    }
}

function Start-Development {
    param([bool]$Rebuild = $false)
    
    Write-Info "🚀 Starting development environment..."
    
    $composeFile = "docker-compose.dev.yml"
    $envFile = ".env.development"
    
    if (-not (Test-Path $composeFile)) {
        Write-Error "❌ $composeFile not found in current directory"
        exit 1
    }
    
    try {
        if ($Rebuild) {
            Write-Info "🔨 Building Docker images..."
            docker-compose -f $composeFile --env-file $envFile up --build -d
        }
        else {
            Write-Info "▶️  Starting services..."
            docker-compose -f $composeFile --env-file $envFile up -d
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "Docker Compose failed"
        }
        
        Write-Success "✅ Development environment started successfully!"
        Write-Info ""
        Write-Info "🌐 Application URLs:"
        Write-Info "   • API: http://localhost:3000"
        Write-Info "   • Health Check: http://localhost:3000/health"
        Write-Info "   • API Status: http://localhost:3000/api"
        Write-Info ""
        Write-Info "📊 Useful commands:"
        Write-Info "   • View logs: .\setup-dev.ps1 -Logs"
        Write-Info "   • Access shell: .\setup-dev.ps1 -Shell"
        Write-Info "   • Stop services: .\setup-dev.ps1 -Down"
        Write-Info ""
        
        # Wait for services to be ready
        Write-Info "⏳ Waiting for services to be ready..."
        Start-Sleep -Seconds 10
        
        # Check if app is responding
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -TimeoutSec 30 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Success "✅ Application is healthy and ready!"
            }
        }
        catch {
            Write-Warning "⚠️  Application might still be starting up. Check logs if needed."
        }
    }
    catch {
        Write-Error "❌ Failed to start development environment: $_"
        Write-Info "💡 Try running: .\setup-dev.ps1 -Logs to see what went wrong"
        exit 1
    }
}

function Stop-Development {
    Write-Info "🛑 Stopping development environment..."
    
    try {
        docker-compose -f "docker-compose.dev.yml" --env-file ".env.development" down
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to stop services"
        }
        
        Write-Success "✅ Development environment stopped"
    }
    catch {
        Write-Error "❌ Error stopping development environment: $_"
        exit 1
    }
}

function Show-Logs {
    Write-Info "📋 Showing application logs..."
    Write-Info "Press Ctrl+C to exit logs view"
    Write-Info ""
    
    docker-compose -f "docker-compose.dev.yml" --env-file ".env.development" logs -f app
}

function Open-Shell {
    Write-Info "🐚 Opening shell in app container..."
    Write-Info "Type 'exit' to return to PowerShell"
    Write-Info ""
    
    docker-compose -f "docker-compose.dev.yml" --env-file ".env.development" exec app sh
}

# Main script logic
try {
    Write-Host "🚀 Acquisitions API - Development Setup" -ForegroundColor Magenta
    Write-Host "=========================================" -ForegroundColor Magenta
    Write-Host ""
    
    if ($Help) {
        Show-Help
        exit 0
    }
    
    if ($Down) {
        Stop-Development
        exit 0
    }
    
    if ($Logs) {
        Show-Logs
        exit 0
    }
    
    if ($Shell) {
        Open-Shell
        exit 0
    }
    
    # Default action: start development environment
    Test-Prerequisites
    Start-Development -Rebuild $Build
}
catch {
    Write-Error "❌ Script failed: $_"
    exit 1
}