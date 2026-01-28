# Windows Setup Guide

This guide provides Windows-specific instructions and scripts for running the Acquisitions API with Docker.

## 🖥️ Windows Setup Scripts

### Available Scripts

| Script | Purpose | Environment |
|--------|---------|-------------|
| `setup-dev.ps1` | Development environment with Neon Local | Development |
| `setup-prod.ps1` | Production environment with Neon Cloud | Production |
| `db-manager.ps1` | Database management operations | Both |
| `setup-dev.bat` | Batch wrapper for PowerShell execution issues | Development |

## 🚀 Quick Start (Development)

### Option 1: PowerShell (Recommended)
```powershell
# Start development environment
.\setup-dev.ps1

# With rebuild
.\setup-dev.ps1 -Build

# View logs
.\setup-dev.ps1 -Logs

# Stop services
.\setup-dev.ps1 -Down
```

### Option 2: Batch File (For Execution Policy Issues)
```cmd
# Double-click setup-dev.bat or run from Command Prompt
setup-dev.bat

# With parameters
setup-dev.bat -Build
setup-dev.bat -Logs
```

## 📋 Prerequisites

### 1. Install Docker Desktop
- Download from: https://docs.docker.com/desktop/install/windows-install/
- Ensure WSL 2 backend is enabled
- Start Docker Desktop and ensure it's running

### 2. Configure Neon Credentials
1. Go to [Neon Console](https://console.neon.tech)
2. Get your API Key: Account Settings → API Keys
3. Get your Project ID: Project Settings → General
4. Note your main branch ID (usually 'main')

### 3. PowerShell Execution Policy (If Needed)
If you get execution policy errors:
```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy for current user (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or use the batch wrapper which bypasses the policy
```

## 🛠️ Detailed Script Usage

### Development Script (`setup-dev.ps1`)

**Basic Usage:**
```powershell
.\setup-dev.ps1 [OPTIONS]
```

**Options:**
- `-Build` - Force rebuild Docker images
- `-Down` - Stop and remove containers
- `-Logs` - Show application logs (follow mode)
- `-Shell` - Open shell in app container
- `-Help` - Show detailed help

**Examples:**
```powershell
# First time setup (will create .env.development if missing)
.\setup-dev.ps1

# Rebuild after code changes
.\setup-dev.ps1 -Build

# Debug issues
.\setup-dev.ps1 -Logs

# Access container
.\setup-dev.ps1 -Shell

# Clean shutdown
.\setup-dev.ps1 -Down
```

**What it does:**
1. ✅ Checks Docker installation and status
2. ✅ Creates `.env.development` from template if missing
3. ✅ Validates Neon credentials configuration
4. ✅ Starts Neon Local proxy + your application
5. ✅ Waits for services to be healthy
6. ✅ Provides service URLs and next steps

### Production Script (`setup-prod.ps1`)

**Basic Usage:**
```powershell
.\setup-prod.ps1 [OPTIONS]
```

**Options:**
- `-Build` - Force rebuild Docker images
- `-Down` - Stop and remove containers (with confirmation)
- `-Logs` - Show application logs
- `-Shell` - Open shell in app container (with confirmation)
- `-Status` - Show container status and resource usage
- `-Help` - Show detailed help

**Examples:**
```powershell
# Deploy production
.\setup-prod.ps1

# Check status
.\setup-prod.ps1 -Status

# View logs
.\setup-prod.ps1 -Logs

# Safe shutdown (with confirmation)
.\setup-prod.ps1 -Down
```

**Security Features:**
- 🔒 Validates production configuration
- 🔒 Checks for weak/default secrets
- 🔒 Requires confirmation for dangerous operations
- 🔒 Warns about production environment access

### Database Manager (`db-manager.ps1`)

**Basic Usage:**
```powershell
.\db-manager.ps1 [-Environment <env>] [COMMAND]
```

**Commands:**
- `-Generate` - Generate new migrations
- `-Migrate` - Apply pending migrations
- `-Studio` - Open Drizzle Studio (dev only)
- `-Reset` - Reset database (dev only, requires confirmation)
- `-Seed` - Seed database with initial data
- `-Backup` - Create database backup (placeholder)

**Examples:**
```powershell
# Development database operations
.\db-manager.ps1 -Generate
.\db-manager.ps1 -Migrate
.\db-manager.ps1 -Studio

# Production database operations
.\db-manager.ps1 -Environment prod -Migrate
.\db-manager.ps1 -Environment prod -Backup

# Reset development database (destructive!)
.\db-manager.ps1 -Reset
```

## 🔧 Configuration

### Environment Files

**Development (`.env.development`):**
```env
NODE_ENV=development
PORT=3000
LOG_LEVEL=debug

# Get these from Neon Console
NEON_API_KEY=neon_api_1234567890abcdef
NEON_PROJECT_ID=your-project-12345
PARENT_BRANCH_ID=main

JWT_SECRET=dev-jwt-secret-change-in-production
```

**Production (`.env.production`):**
```env
NODE_ENV=production
PORT=3000
LOG_LEVEL=info

# Your actual Neon Cloud URL
DATABASE_URL=postgresql://user:pass@endpoint.neon.tech/db?sslmode=require

# Strong production secret (32+ chars)
JWT_SECRET=your-super-secure-production-secret-here
```

### Script Configuration

Scripts automatically:
- Create environment files from templates
- Validate required variables
- Check Docker availability
- Verify container health

## 🐛 Windows-Specific Troubleshooting

### PowerShell Execution Policy
```powershell
# Error: "execution of scripts is disabled on this system"
# Solution 1: Use batch wrapper
setup-dev.bat

# Solution 2: Bypass policy temporarily
powershell -ExecutionPolicy Bypass -File setup-dev.ps1

# Solution 3: Change policy permanently (as Administrator)
Set-ExecutionPolicy RemoteSigned
```

### Docker Desktop Issues
```powershell
# Error: "Docker daemon is not running"
# Solution: Start Docker Desktop
# Check: Docker Desktop system tray icon should be running

# Error: "WSL 2 installation is incomplete"
# Solution: Enable WSL 2 in Windows Features
# Or switch to Hyper-V backend in Docker settings
```

### Port Conflicts
```cmd
# Check what's using port 3000 or 5432
netstat -an | findstr :3000
netstat -an | findstr :5432

# Kill process using port (replace PID)
taskkill /PID 1234 /F
```

### File Path Issues
```powershell
# Long path names in Windows
# Enable long path support (as Administrator)
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
```

## 📊 Monitoring & Logs

### View Logs
```powershell
# Application logs
.\setup-dev.ps1 -Logs

# Specific service logs
docker-compose -f docker-compose.dev.yml logs -f neon-local
docker-compose -f docker-compose.dev.yml logs -f app

# Windows Event Viewer
# Look for Docker-related events
```

### Container Status
```powershell
# Using production script
.\setup-prod.ps1 -Status

# Manual checks
docker ps
docker stats
docker-compose -f docker-compose.dev.yml ps
```

## 🎯 Development Workflow

### Typical Development Session
```powershell
# 1. Start development environment
.\setup-dev.ps1

# 2. Make database changes
.\db-manager.ps1 -Generate
.\db-manager.ps1 -Migrate

# 3. View database
.\db-manager.ps1 -Studio

# 4. Check logs during development
.\setup-dev.ps1 -Logs

# 5. Clean up when done
.\setup-dev.ps1 -Down
```

### Code Changes
- Source code is mounted for hot reload
- Container automatically restarts on file changes
- No need to rebuild unless dependencies change

### Database Changes
- Use `db-manager.ps1 -Generate` after model changes
- Review generated SQL in `./drizzle/` directory  
- Apply with `db-manager.ps1 -Migrate`

## 🔐 Security Notes

- Scripts validate configuration before running
- Production operations require confirmation
- Environment files are gitignored
- JWT secrets are validated for strength
- Container runs as non-root user

## 💡 Tips & Best Practices

1. **Use the batch wrapper** if you have PowerShell execution policy issues
2. **Always check logs** if containers don't start properly
3. **Keep Docker Desktop updated** for best Windows compatibility
4. **Use WSL 2 backend** for better performance
5. **Close unnecessary applications** to free up ports
6. **Run as Administrator** only when necessary

---

**Need help?** Check the main [DOCKER_SETUP.md](./DOCKER_SETUP.md) for additional details or create an issue in the repository.

🚀 **Happy coding on Windows!**