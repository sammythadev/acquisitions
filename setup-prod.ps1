# Acquisitions API - Production Setup Script for Windows
# This script sets up and runs the production environment with Neon Cloud

param(
    [switch]$Build,
    [switch]$Down,
    [switch]$Logs,
    [switch]$Shell,
    [switch]$Status,
    [switch]$Help
)

# Color functions for better output
function Write-Success { param($Message) Write-Host $Message -ForegroundColor Green }
function Write-Error { param($Message) Write-Host $Message -ForegroundColor Red }
function Write-Info { param($Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host $Message -ForegroundColor Yellow }

function Show-Help {
    Write-Host @"
Acquisitions API - Production Setup Script

USAGE:
    .\setup-prod.ps1 [OPTIONS]

OPTIONS:
    -Build     Force rebuild of Docker images
    -Down      Stop and remove all containers
    -Logs      Show application logs
    -Shell     Open shell in app container
    -Status    Show container status and health
    -Help      Show this help message

EXAMPLES:
    .\setup-prod.ps1                    # Start production environment
    .\setup-prod.ps1 -Build             # Rebuild and start
    .\setup-prod.ps1 -Down              # Stop all services
    .\setup-prod.ps1 -Logs              # View logs
    .\setup-prod.ps1 -Status            # Check container status

REQUIREMENTS:
    - Docker Desktop for Windows
    - Configured .env.production file
    - Valid Neon Cloud DATABASE_URL
    - Strong JWT_SECRET

WARNING:
    This script is for production deployment. Ensure all
    security configurations are properly set before use.

"@ -ForegroundColor White
}

function Test-Prerequisites {
    Write-Info "🔍 Checking production prerequisites..."
    
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

    # Check if production environment file exists
    if (-not (Test-Path ".env.production")) {
        Write-Warning "⚠️  .env.production not found"
        Write-Info "Creating .env.production from template..."
        
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" ".env.production"
            Write-Success "✅ Created .env.production from template"
            Write-Warning "⚠️  IMPORTANT: Configure .env.production with production values:"
            Write-Info "   - DATABASE_URL (your Neon Cloud connection string)"
            Write-Info "   - JWT_SECRET (strong secret key, minimum 256 bits)"
            Write-Info "   - LOG_LEVEL (recommended: 'info' or 'warn')"
            Write-Host ""
            Write-Host "🚨 SECURITY WARNING: Never use default or weak secrets in production!" -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter after configuring .env.production to continue"
        }
        else {
            Write-Error "❌ .env.example not found. Cannot create production environment file."
            exit 1
        }
    }
    else {
        Write-Success "✅ .env.production found"
    }

    # Validate critical production environment variables
    $envContent = Get-Content ".env.production" -Raw
    $criticalIssues = @()
    $warnings = @()
    
    # Check DATABASE_URL
    if ($envContent -match "DATABASE_URL=(?!.*neon\.tech)") {
        $criticalIssues += "DATABASE_URL does not appear to be a valid Neon Cloud URL"
    }
    elseif ($envContent -notmatch "DATABASE_URL=postgresql://") {
        $criticalIssues += "DATABASE_URL is not configured or invalid"
    }
    
    # Check JWT_SECRET
    if ($envContent -match "JWT_SECRET=(?:your_|dev-|change|secret|password|123)") {
        $criticalIssues += "JWT_SECRET appears to be a default or weak value"
    }
    elseif ($envContent -notmatch "JWT_SECRET=.{32,}") {
        $warnings += "JWT_SECRET might be too short (recommended: 32+ characters)"
    }
    
    # Check NODE_ENV
    if ($envContent -notmatch "NODE_ENV=production") {
        $warnings += "NODE_ENV should be set to 'production'"
    }
    
    if ($criticalIssues.Count -gt 0) {
        Write-Error "❌ Critical production configuration issues found:"
        foreach ($issue in $criticalIssues) {
            Write-Error "   • $issue"
        }
        Write-Host ""
        Write-Error "Please fix these issues in .env.production before continuing."
        exit 1
    }
    
    if ($warnings.Count -gt 0) {
        Write-Warning "⚠️  Production configuration warnings:"
        foreach ($warning in $warnings) {
            Write-Warning "   • $warning"
        }
        Write-Host ""
        $response = Read-Host "Continue anyway? (y/N)"
        if ($response -notmatch "^[Yy]") {
            Write-Info "Aborting. Please review and update .env.production"
            exit 0
        }
    }
    else {
        Write-Success "✅ Production configuration validated"
    }
}

function Start-Production {
    param([bool]$Rebuild = $false)
    
    Write-Info "🚀 Starting production environment..."
    Write-Warning "⚠️  Running in PRODUCTION mode"
    
    $composeFile = "docker-compose.prod.yml"
    $envFile = ".env.production"
    
    if (-not (Test-Path $composeFile)) {
        Write-Error "❌ $composeFile not found in current directory"
        exit 1
    }
    
    try {
        if ($Rebuild) {
            Write-Info "🔨 Building production Docker images..."
            docker-compose -f $composeFile --env-file $envFile up --build -d
        }
        else {
            Write-Info "▶️  Starting production services..."
            docker-compose -f $composeFile --env-file $envFile up -d
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "Docker Compose failed"
        }
        
        Write-Success "✅ Production environment started successfully!"
        Write-Info ""
        Write-Info "🌐 Application URLs:"
        Write-Info "   • API: http://localhost:3000"
        Write-Info "   • Health Check: http://localhost:3000/health"
        Write-Info "   • API Status: http://localhost:3000/api"
        Write-Info ""
        Write-Info "📊 Useful commands:"
        Write-Info "   • View logs: .\setup-prod.ps1 -Logs"
        Write-Info "   • Check status: .\setup-prod.ps1 -Status"
        Write-Info "   • Access shell: .\setup-prod.ps1 -Shell"
        Write-Info "   • Stop services: .\setup-prod.ps1 -Down"
        Write-Info ""
        
        # Wait for services to be ready
        Write-Info "⏳ Waiting for services to be ready..."
        Start-Sleep -Seconds 15
        
        # Check if app is responding
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -TimeoutSec 60 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Success "✅ Application is healthy and ready!"
                
                # Parse health response for additional info
                $healthData = $response.Content | ConvertFrom-Json
                Write-Info "   Status: $($healthData.status)"
                Write-Info "   Uptime: $([math]::Round($healthData.uptime, 2)) seconds"
            }
        }
        catch {
            Write-Warning "⚠️  Application health check failed. This might indicate:"
            Write-Warning "   • Database connection issues"
            Write-Warning "   • Application startup problems"
            Write-Warning "   • Configuration errors"
            Write-Info ""
            Write-Info "💡 Run .\setup-prod.ps1 -Logs to diagnose the issue"
        }
        
        # Show container status
        Show-ContainerStatus
    }
    catch {
        Write-Error "❌ Failed to start production environment: $_"
        Write-Info "💡 Run .\setup-prod.ps1 -Logs to see detailed error information"
        exit 1
    }
}

function Stop-Production {
    Write-Info "🛑 Stopping production environment..."
    
    $response = Read-Host "Are you sure you want to stop the production environment? (y/N)"
    if ($response -notmatch "^[Yy]") {
        Write-Info "Cancelled"
        exit 0
    }
    
    try {
        docker-compose -f "docker-compose.prod.yml" --env-file ".env.production" down
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to stop services"
        }
        
        Write-Success "✅ Production environment stopped"
    }
    catch {
        Write-Error "❌ Error stopping production environment: $_"
        exit 1
    }
}

function Show-Logs {
    Write-Info "📋 Showing production application logs..."
    Write-Info "Press Ctrl+C to exit logs view"
    Write-Info ""
    
    docker-compose -f "docker-compose.prod.yml" --env-file ".env.production" logs -f app
}

function Open-Shell {
    Write-Info "🐚 Opening shell in production app container..."
    Write-Warning "⚠️  You are accessing the PRODUCTION container"
    Write-Info "Type 'exit' to return to PowerShell"
    Write-Info ""
    
    $response = Read-Host "Continue? (y/N)"
    if ($response -notmatch "^[Yy]") {
        Write-Info "Cancelled"
        exit 0
    }
    
    docker-compose -f "docker-compose.prod.yml" --env-file ".env.production" exec app sh
}

function Show-ContainerStatus {
    Write-Info "📊 Container Status:"
    Write-Info ""
    
    try {
        # Get container status
        $containers = docker-compose -f "docker-compose.prod.yml" --env-file ".env.production" ps
        Write-Host $containers
        
        Write-Info ""
        Write-Info "💾 Resource Usage:"
        
        # Get resource usage stats
        $stats = docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
        Write-Host $stats
        
        Write-Info ""
        Write-Info "🔍 Health Status:"
        
        # Check application health
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -TimeoutSec 10 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Success "✅ Application: Healthy"
                $healthData = $response.Content | ConvertFrom-Json
                Write-Info "   Uptime: $([math]::Round($healthData.uptime, 2)) seconds"
            }
        }
        catch {
            Write-Error "❌ Application: Unhealthy or not responding"
        }
    }
    catch {
        Write-Error "❌ Error getting container status: $_"
    }
}

# Main script logic
try {
    Write-Host "🏭 Acquisitions API - Production Setup" -ForegroundColor Magenta
    Write-Host "=======================================" -ForegroundColor Magenta
    Write-Host ""
    
    if ($Help) {
        Show-Help
        exit 0
    }
    
    if ($Down) {
        Stop-Production
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
    
    if ($Status) {
        Show-ContainerStatus
        exit 0
    }
    
    # Default action: start production environment
    Test-Prerequisites
    Start-Production -Rebuild $Build
}
catch {
    Write-Error "❌ Script failed: $_"
    exit 1
}