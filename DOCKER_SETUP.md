# Docker Setup Guide

This guide explains how to run the Acquisitions API using Docker for both development and production environments.

## 🏗️ Architecture Overview

### Development Environment
- **Neon Local**: Proxy service that creates ephemeral database branches
- **Local Development**: Hot reload with mounted source code
- **Isolated Database**: Each container run gets a fresh database branch

### Production Environment
- **Neon Cloud**: Direct connection to production Neon database
- **Optimized Build**: Minimal Docker image with security hardening
- **Resource Limits**: Configured CPU and memory constraints

## 📋 Prerequisites

1. **Docker & Docker Compose**: Install [Docker Desktop](https://docs.docker.com/get-docker/)
2. **Neon Account**: Create account at [neon.tech](https://neon.tech)
3. **Environment Variables**: Configure as described below

## 🚀 Development Setup (with Neon Local)

### Step 1: Configure Neon Credentials

1. Go to [Neon Console](https://console.neon.tech)
2. Create or select your project
3. Get your credentials:
   - **API Key**: Go to Account Settings → API Keys
   - **Project ID**: Found in Project Settings → General

### Step 2: Create Development Environment File

Copy and configure the development environment:

```bash
cp .env.example .env.development
```

Edit `.env.development`:
```env
# Development Environment Configuration
NODE_ENV=development
PORT=3000
LOG_LEVEL=debug

# Neon Local Configuration
NEON_API_KEY=neon_api_1234567890abcdef  # Your actual API key
NEON_PROJECT_ID=cool-project-12345      # Your actual project ID
PARENT_BRANCH_ID=main                   # Creates ephemeral branches from main

# Authentication
JWT_SECRET=dev-jwt-secret-change-in-production
```

### Step 3: Run Development Environment

```bash
# Build and start development environment
docker-compose -f docker-compose.dev.yml --env-file .env.development up --build

# Or run in detached mode
docker-compose -f docker-compose.dev.yml --env-file .env.development up -d --build
```

### Step 4: Initialize Database (First Run Only)

```bash
# Run database migrations
docker-compose -f docker-compose.dev.yml exec app npm run db:migrate

# Or generate new migrations if needed
docker-compose -f docker-compose.dev.yml exec app npm run db:generate
```

### Development URLs

- **API**: http://localhost:3000
- **Health Check**: http://localhost:3000/health
- **API Status**: http://localhost:3000/api
- **Database**: localhost:5432 (Neon Local proxy)
- **Drizzle Studio**: Run `npm run db:studio` in container

### Development Features

✅ **Hot Reload**: Source code changes trigger automatic restarts  
✅ **Ephemeral Database**: Fresh database branch for each session  
✅ **Debug Logging**: Detailed logs for development  
✅ **Source Mounting**: Live code editing without rebuilding  

## 🌐 Production Setup (Neon Cloud)

### Step 1: Create Production Environment File

```bash
cp .env.example .env.production
```

Edit `.env.production`:
```env
# Production Environment Configuration
NODE_ENV=production
PORT=3000
LOG_LEVEL=info

# Neon Cloud Database (your actual production URL)
DATABASE_URL=postgresql://neondb_owner:your_password@your-endpoint.neon.tech/neondb?sslmode=require

# Authentication (use a strong secret!)
JWT_SECRET=your_super_secure_jwt_secret_256_bits_minimum

# External Services
ARCHET_KEY=your_production_arcjet_key
```

### Step 2: Run Production Environment

```bash
# Build and start production environment
docker-compose -f docker-compose.prod.yml --env-file .env.production up --build -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f app
```

### Production Features

✅ **Resource Limits**: CPU and memory constraints  
✅ **Security**: Non-root user, minimal attack surface  
✅ **Health Checks**: Automatic container health monitoring  
✅ **Log Management**: Structured logging to files  
✅ **Restart Policies**: Automatic recovery from failures  

## 🛠️ Common Operations

### Database Operations

```bash
# Development
docker-compose -f docker-compose.dev.yml exec app npm run db:migrate
docker-compose -f docker-compose.dev.yml exec app npm run db:studio

# Production
docker-compose -f docker-compose.prod.yml exec app npm run db:migrate
```

### Viewing Logs

```bash
# Development logs (with debug info)
docker-compose -f docker-compose.dev.yml logs -f app

# Production logs
docker-compose -f docker-compose.prod.yml logs -f app

# Neon Local logs (development only)
docker-compose -f docker-compose.dev.yml logs -f neon-local
```

### Container Management

```bash
# Stop services
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.prod.yml down

# Rebuild application
docker-compose -f docker-compose.dev.yml up --build app

# Shell into running container
docker-compose -f docker-compose.dev.yml exec app sh
```

## 🔧 Configuration Details

### Environment Variables

| Variable | Development | Production | Description |
|----------|-------------|------------|-------------|
| `NODE_ENV` | `development` | `production` | Environment mode |
| `DATABASE_URL` | Auto-set by compose | Neon Cloud URL | Database connection |
| `NEON_API_KEY` | Required | Not used | Neon Local authentication |
| `JWT_SECRET` | Simple | Strong secret | JWT signing key |
| `LOG_LEVEL` | `debug` | `info` | Logging verbosity |

### Network Architecture

```
Development:
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Browser   │ →  │     App      │ →  │ Neon Local  │
│ :3000       │    │ (Container)  │    │ (Proxy)     │
└─────────────┘    └──────────────┘    └─────────────┘
                          │                     │
                          └─────────────────────┘
                            Internal Network
                               :5432

Production:
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Browser   │ →  │     App      │ →  │ Neon Cloud  │
│ :3000       │    │ (Container)  │    │ (Database)  │
└─────────────┘    └──────────────┘    └─────────────┘
```

## 🐛 Troubleshooting

### Common Issues

1. **Neon Local won't start**
   ```bash
   # Check your API key and project ID
   docker-compose -f docker-compose.dev.yml logs neon-local
   ```

2. **App can't connect to database**
   ```bash
   # Verify network connectivity
   docker-compose -f docker-compose.dev.yml exec app ping neon-local
   ```

3. **Port conflicts**
   ```bash
   # Check what's using port 5432 or 3000
   netstat -tulpn | grep :5432
   ```

4. **Permission errors**
   ```bash
   # Fix log directory permissions
   chmod 755 logs/
   ```

### Health Checks

```bash
# Application health
curl http://localhost:3000/health

# Database connectivity (development)
docker-compose -f docker-compose.dev.yml exec neon-local pg_isready -h localhost -p 5432 -U neon
```

## 📚 Additional Resources

- [Neon Local Documentation](https://neon.com/docs/local/neon-local)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Node.js Docker Best Practices](https://nodejs.org/en/docs/guides/nodejs-docker-webapp)

## 🔐 Security Notes

- Never commit real credentials to version control
- Use strong JWT secrets in production (minimum 256 bits)
- Consider using Docker secrets for sensitive data
- Regularly update base images and dependencies
- Implement proper reverse proxy (nginx) for production

---

**Happy Dockering! 🐳**