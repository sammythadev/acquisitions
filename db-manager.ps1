# Acquisitions API - Database Management Script for Windows
# This script helps manage database operations in Docker containers

param(
    [string]$Environment = "dev",
    [switch]$Generate,
    [switch]$Migrate,
    [switch]$Studio,
    [switch]$Reset,
    [switch]$Seed,
    [switch]$Backup,
    [switch]$Help
)

# Color functions for better output
function Write-Success { param($Message) Write-Host $Message -ForegroundColor Green }
function Write-Error { param($Message) Write-Host $Message -ForegroundColor Red }
function Write-Info { param($Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host $Message -ForegroundColor Yellow }

function Show-Help {
    Write-Host @"
Acquisitions API - Database Management Script

USAGE:
    .\db-manager.ps1 [-Environment <env>] [COMMAND]

ENVIRONMENTS:
    dev        Development environment (default)
    prod       Production environment

COMMANDS:
    -Generate  Generate new database migrations
    -Migrate   Apply pending migrations to database
    -Studio    Open Drizzle Studio (development only)
    -Reset     Reset database (WARNING: destructive)
    -Seed      Seed database with initial data
    -Backup    Create database backup (production)
    -Help      Show this help message

EXAMPLES:
    .\db-manager.ps1 -Generate                  # Generate migrations (dev)
    .\db-manager.ps1 -Migrate                   # Apply migrations (dev)
    .\db-manager.ps1 -Studio                    # Open Drizzle Studio (dev)
    .\db-manager.ps1 -Environment prod -Migrate # Apply migrations (prod)
    .\db-manager.ps1 -Environment prod -Backup  # Backup production DB

REQUIREMENTS:
    - Running Docker environment
    - Configured database connection

"@ -ForegroundColor White
}

function Test-Environment {
    param([string]$Env)
    
    Write-Info "🔍 Checking $Env environment..."
    
    # Determine compose file and env file based on environment
    if ($Env -eq "dev") {
        $script:composeFile = "docker-compose.dev.yml"
        $script:envFile = ".env.development"
        $script:serviceName = "app"
    }
    elseif ($Env -eq "prod") {
        $script:composeFile = "docker-compose.prod.yml"
        $script:envFile = ".env.production"
        $script:serviceName = "app"
    }
    else {
        Write-Error "❌ Invalid environment: $Env. Use 'dev' or 'prod'"
        exit 1
    }
    
    # Check if compose file exists
    if (-not (Test-Path $script:composeFile)) {
        Write-Error "❌ $script:composeFile not found"
        exit 1
    }
    
    # Check if env file exists
    if (-not (Test-Path $script:envFile)) {
        Write-Error "❌ $script:envFile not found"
        exit 1
    }
    
    # Check if containers are running
    try {
        $containerStatus = docker-compose -f $script:composeFile --env-file $script:envFile ps -q $script:serviceName 2>$null
        if (-not $containerStatus) {
            Write-Error "❌ $Env environment containers are not running"
            Write-Info "💡 Start the environment first:"
            if ($Env -eq "dev") {
                Write-Info "   .\setup-dev.ps1"
            } else {
                Write-Info "   .\setup-prod.ps1"
            }
            exit 1
        }
        Write-Success "✅ $Env environment is running"
    }
    catch {
        Write-Error "❌ Error checking container status: $_"
        exit 1
    }
}

function Invoke-DatabaseCommand {
    param([string]$Command, [string]$Description)
    
    Write-Info "🔄 $Description..."
    
    try {
        $result = docker-compose -f $script:composeFile --env-file $script:envFile exec $script:serviceName npm run $Command
        
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed with exit code $LASTEXITCODE"
        }
        
        Write-Success "✅ $Description completed successfully"
        return $result
    }
    catch {
        Write-Error "❌ $Description failed: $_"
        exit 1
    }
}

function Generate-Migration {
    Write-Info "📝 Generating database migration..."
    
    # Check if there are model changes
    Write-Info "Checking for schema changes..."
    
    Invoke-DatabaseCommand "db:generate" "Generating migration files"
    
    Write-Info ""
    Write-Info "📁 Generated migration files are in the ./drizzle directory"
    Write-Info "Review the generated SQL before applying with -Migrate"
}

function Apply-Migration {
    Write-Info "⚡ Applying database migrations..."
    
    if ($Environment -eq "prod") {
        Write-Warning "⚠️  You are about to apply migrations to PRODUCTION database"
        $response = Read-Host "Continue? (y/N)"
        if ($response -notmatch "^[Yy]") {
            Write-Info "Cancelled"
            exit 0
        }
    }
    
    Invoke-DatabaseCommand "db:migrate" "Applying database migrations"
    
    Write-Success "✅ Database schema updated successfully"
}

function Open-DrizzleStudio {
    if ($Environment -eq "prod") {
        Write-Error "❌ Drizzle Studio is not recommended for production environments"
        Write-Info "Use a proper database client for production database access"
        exit 1
    }
    
    Write-Info "🎨 Opening Drizzle Studio..."
    Write-Info "This will open in your web browser"
    Write-Info "Press Ctrl+C in this window to stop Drizzle Studio"
    Write-Info ""
    
    try {
        docker-compose -f $script:composeFile --env-file $script:envFile exec $script:serviceName npm run db:studio
    }
    catch {
        Write-Info "Drizzle Studio session ended"
    }
}

function Reset-Database {
    Write-Warning "🚨 DATABASE RESET WARNING"
    Write-Warning "This will permanently delete ALL data in the database!"
    Write-Host ""
    
    if ($Environment -eq "prod") {
        Write-Error "❌ Database reset is not allowed in production environment"
        Write-Error "This operation is too dangerous for production use"
        exit 1
    }
    
    Write-Host "Type 'RESET' to confirm database reset:" -ForegroundColor Red
    $confirmation = Read-Host
    
    if ($confirmation -ne "RESET") {
        Write-Info "Cancelled - confirmation text did not match"
        exit 0
    }
    
    Write-Info "🗑️  Resetting database..."
    
    try {
        # For development, we can recreate the container to get a fresh ephemeral branch
        Write-Info "Recreating development containers for fresh database..."
        docker-compose -f $script:composeFile --env-file $script:envFile down
        docker-compose -f $script:composeFile --env-file $script:envFile up -d
        
        # Wait for services to be ready
        Write-Info "⏳ Waiting for services to restart..."
        Start-Sleep -Seconds 15
        
        # Apply migrations to fresh database
        Write-Info "Applying migrations to fresh database..."
        Invoke-DatabaseCommand "db:migrate" "Applying migrations"
        
        Write-Success "✅ Database reset completed"
        Write-Info "You now have a fresh database with current schema"
    }
    catch {
        Write-Error "❌ Database reset failed: $_"
        exit 1
    }
}

function Seed-Database {
    Write-Info "🌱 Seeding database with initial data..."
    
    # Note: You would need to create a seed script in your package.json
    # For now, this is a placeholder that shows how it would work
    
    if ($Environment -eq "prod") {
        Write-Warning "⚠️  You are about to seed PRODUCTION database"
        $response = Read-Host "Continue? (y/N)"
        if ($response -notmatch "^[Yy]") {
            Write-Info "Cancelled"
            exit 0
        }
    }
    
    # Check if seed script exists
    $packageJson = Get-Content "package.json" -Raw | ConvertFrom-Json
    if (-not $packageJson.scripts."db:seed") {
        Write-Warning "⚠️  No 'db:seed' script found in package.json"
        Write-Info "To enable database seeding, add a seed script to your package.json:"
        Write-Info '   "db:seed": "node scripts/seed.js"'
        Write-Info ""
        Write-Info "Create a seed script that uses your Drizzle setup to insert initial data"
        exit 0
    }
    
    Invoke-DatabaseCommand "db:seed" "Seeding database with initial data"
    
    Write-Success "✅ Database seeded successfully"
}

function Backup-Database {
    if ($Environment -ne "prod") {
        Write-Warning "⚠️  Backup is primarily intended for production environments"
        $response = Read-Host "Continue with development backup? (y/N)"
        if ($response -notmatch "^[Yy]") {
            Write-Info "Cancelled"
            exit 0
        }
    }
    
    Write-Info "💾 Creating database backup..."
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "backup_${Environment}_${timestamp}.sql"
    
    Write-Info "Backup will be saved as: $backupFile"
    
    try {
        # Note: This is a simplified backup approach
        # In production, you'd want more sophisticated backup strategies
        
        Write-Warning "⚠️  Database backup feature needs to be implemented"
        Write-Info "For Neon databases, consider:"
        Write-Info "• Using Neon's built-in backup features"
        Write-Info "• Creating database branches for backup purposes"
        Write-Info "• Using pg_dump through a PostgreSQL client container"
        Write-Info ""
        Write-Info "Example backup command for future implementation:"
        Write-Info "docker run --rm postgres:15 pg_dump \$DATABASE_URL > $backupFile"
        
    }
    catch {
        Write-Error "❌ Backup failed: $_"
        exit 1
    }
}

# Main script logic
try {
    Write-Host "🗄️  Acquisitions API - Database Manager" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host ""
    
    if ($Help) {
        Show-Help
        exit 0
    }
    
    # Validate environment parameter
    if ($Environment -notin @("dev", "prod")) {
        Write-Error "❌ Invalid environment: $Environment"
        Write-Info "Valid environments: dev, prod"
        exit 1
    }
    
    # Test environment before proceeding
    Test-Environment -Env $Environment
    
    # Execute the requested command
    if ($Generate) {
        Generate-Migration
    }
    elseif ($Migrate) {
        Apply-Migration
    }
    elseif ($Studio) {
        Open-DrizzleStudio
    }
    elseif ($Reset) {
        Reset-Database
    }
    elseif ($Seed) {
        Seed-Database
    }
    elseif ($Backup) {
        Backup-Database
    }
    else {
        Write-Warning "⚠️  No command specified"
        Show-Help
    }
}
catch {
    Write-Error "❌ Script failed: $_"
    exit 1
}