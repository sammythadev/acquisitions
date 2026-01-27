# AGENTS.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Development Commands

### Running the Application
- **Development**: `npm run dev` - Runs with Node.js --watch flag for hot reloading
- **Health Check**: Visit `http://localhost:3000/health` after starting the server

### Code Quality
- **Linting**: `npm run lint` (check) or `npm run lint:fix` (auto-fix)
- **Formatting**: `npm run format` (apply) or `npm run format:check` (validate)

### Database Operations
- **Generate migrations**: `npm run db:generate` - Creates new migration files
- **Apply migrations**: `npm run db:migrate` - Runs pending migrations against database
- **Database Studio**: `npm run db:studio` - Opens Drizzle Studio for database inspection

## Architecture Overview

### Core Structure
This is a Node.js Express API using modern ES modules with import path aliases defined in package.json. The application follows a layered architecture:

- **Entry Point**: `src/index.js` → `src/server.js` → `src/app.js`
- **Database**: PostgreSQL with Drizzle ORM, hosted on Neon
- **Authentication**: JWT-based with bcrypt password hashing
- **Validation**: Zod schemas for request validation
- **Logging**: Winston logger with file and console transports

### Import Aliases
The project uses Node.js import maps for clean imports:
- `#config/*` → `./src/config/*`
- `#controllers/*` → `./src/controllers/*`
- `#models/*` → `./src/models/*`
- `#routes/*` → `./src/routes/*`
- `#utils/*` → `./src/utils/*`
- `#services/*` → `./src/services/*`
- `#middleware/*` → `./src/middleware/*`
- `#validations/*` → `./src/validations/*`

### Database Layer
- **ORM**: Drizzle ORM with Neon PostgreSQL driver
- **Configuration**: `src/config/database.js` exports `db` and `sql` instances
- **Models**: Located in `src/models/` (currently only `user.model.js`)
- **Migrations**: Generated in `drizzle/` directory

### API Layer
- **Routes**: Express routers in `src/routes/` (currently `/api/auth`)
- **Controllers**: Business logic handlers in `src/controllers/`
- **Services**: Data access and business logic in `src/services/`
- **Validations**: Zod schemas in `src/validations/`

### Current Endpoints
- `GET /` - Basic hello endpoint
- `GET /health` - Health check with uptime
- `GET /api` - API status endpoint  
- `POST /api/auth/sign-up` - User registration (fully implemented)
- `POST /api/auth/sign-in` - User login (placeholder)
- `POST /api/auth/sign-out` - User logout (placeholder)

### Environment Configuration
- Database connection requires `DATABASE_URL` environment variable
- Logger level controlled by `LOG_LEVEL` (defaults to 'info')
- Server port via `PORT` (defaults to 3000)
- Check `.env.example` for required variables (currently empty)

### Logging
Winston logger configured in `src/config/logger.js`:
- Logs to `logs/error.log` and `logs/combined.log`
- Console output in non-production environments
- HTTP requests logged via Morgan middleware

## Development Notes

### Testing
No test framework is currently configured (`npm test` returns error message).

### Code Style
- ESLint configured with 2-space indentation, single quotes, semicolons required
- Prettier for consistent formatting
- ES2022 modules with Node.js globals configured