# Scripts Directory

This directory contains both shell scripts (.sh) for Unix/Linux/macOS and Windows batch scripts (.bat) for managing the Acquisitions API Docker environment.

## Available Scripts

### Shell Scripts (.sh) - Unix/Linux/macOS
| Script | Purpose |
|--------|---------|
| `dev.sh` | Start development environment with Neon Local |
| `prod.sh` | Start production environment with Neon Cloud |

### Windows Batch Scripts (.bat) - Windows Command Prompt
| Script | Purpose |
|--------|---------|
| `dev.bat` | Start development environment with Neon Local |
| `prod.bat` | Start production environment with Neon Cloud |
| `dev-stop.bat` | Stop development environment |
| `prod-stop.bat` | Stop production environment |
| `db.bat` | Database management operations |

## Usage

### Windows Users
Run batch scripts from the scripts directory:
```cmd
# Development
scripts\dev.bat

# Production
scripts\prod.bat

# Database operations
scripts\db.bat migrate
scripts\db.bat generate
scripts\db.bat studio

# Stop environments
scripts\dev-stop.bat
scripts\prod-stop.bat
```

### Unix/Linux/macOS Users
Make scripts executable and run:
```bash
# Make executable
chmod +x scripts/*.sh

# Development
./scripts/dev.sh

# Production  
./scripts/prod.sh
```

## Requirements

- **Environment Files**: Scripts expect `.env.development` and/or `.env.production` in the root directory
- **Docker**: Docker Desktop must be installed and running
- **Working Directory**: Run scripts from the project root or scripts directory

## Environment Files Location

All scripts expect environment files in the project root:
```
acquisitions/
├── .env.development    # Development environment variables
├── .env.production     # Production environment variables
├── scripts/
│   ├── dev.bat        # Windows development script
│   ├── dev.sh         # Unix development script
│   └── ...
```

## Notes

- Windows batch scripts automatically navigate to the root directory to find environment files
- Shell scripts should be run from the project root directory
- All scripts include error checking and user feedback
- Production scripts include safety confirmations