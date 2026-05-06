# Acquisitions API

A secure, production-ready REST API built with Node.js and Express, featuring JWT authentication, role-based rate limiting, and PostgreSQL via Neon Serverless.

## 🚀 Features

- **JWT Authentication** — Secure sign-up, sign-in, and sign-out with HTTP-only cookie tokens
- **Role-Based Rate Limiting** — Per-role sliding-window limits enforced by [Arcjet](https://arcjet.com) (admin: 20 req/min, user: 10 req/min, guest: 5 req/min)
- **Bot & Shield Protection** — Automated threat detection via Arcjet middleware
- **Input Validation** — Request bodies validated with [Zod](https://zod.dev) schemas
- **PostgreSQL + Drizzle ORM** — Type-safe database access powered by [Neon](https://neon.tech) serverless Postgres
- **Docker Support** — Dev and production compose setups with Neon Local ephemeral branches
- **Structured Logging** — Winston logger with file and console transports (HTTP access via Morgan)
- **Security Headers** — Helmet applied globally

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Runtime | Node.js (ES Modules) |
| Framework | Express 5 |
| Database | PostgreSQL (Neon Serverless) |
| ORM | Drizzle ORM |
| Auth | JSON Web Tokens + bcrypt |
| Validation | Zod |
| Security | Arcjet, Helmet, CORS |
| Logging | Winston, Morgan |
| Containerisation | Docker, Docker Compose |

## 📋 Prerequisites

- Node.js 20+
- A [Neon](https://neon.tech) account (free tier works)
- An [Arcjet](https://arcjet.com) account for the security key
- Docker & Docker Compose (optional, for containerised setup)

## ⚡ Quick Start

### 1. Clone and install

```bash
git clone https://github.com/sammythadev/acquisitions.git
cd acquisitions
npm install
```

### 2. Configure environment

```bash
cp .env.example .env
```

Edit `.env` and fill in the required values:

```env
PORT=3000
NODE_ENV=development
LOG_LEVEL=info

DATABASE_URL=your_neon_connection_string

JWT_SECRET=your_jwt_secret_here
ARCHET_KEY=your_arcjet_key_here
```

### 3. Run database migrations

```bash
npm run db:migrate
```

### 4. Start the development server

```bash
npm run dev
```

The API will be available at `http://localhost:3000`.

## 🐳 Docker Setup

See [DOCKER_SETUP.md](./DOCKER_SETUP.md) for full instructions. Quick start:

```bash
# Development (with Neon Local ephemeral database)
docker-compose -f docker-compose.dev.yml --env-file .env.development up --build

# Production (pointing at Neon Cloud)
docker-compose -f docker-compose.prod.yml --env-file .env.production up --build -d
```

Windows users: see [WINDOWS_SETUP.md](./WINDOWS_SETUP.md) for PowerShell scripts.

## 🗺️ API Reference

### General

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/` | Hello endpoint |
| `GET` | `/health` | Health check — returns uptime and timestamp |
| `GET` | `/api` | API status |

### Authentication — `/api/auth`

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/auth/sign-up` | Register a new user |
| `POST` | `/api/auth/sign-in` | Authenticate and receive a JWT cookie |
| `POST` | `/api/auth/sign-out` | Clear the JWT cookie |

#### `POST /api/auth/sign-up`

```json
{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "password": "supersecret",
  "role": "user"
}
```

**Response `201`**

```json
{
  "message": "User registered",
  "user": { "id": 1, "name": "Jane Doe", "email": "jane@example.com", "role": "user" }
}
```

#### `POST /api/auth/sign-in`

```json
{
  "email": "jane@example.com",
  "password": "supersecret"
}
```

**Response `200`**

```json
{
  "message": "User signed in successfully",
  "user": { "id": 1, "name": "Jane Doe", "email": "jane@example.com", "role": "user" }
}
```

#### `POST /api/auth/sign-out`

**Response `200`**

```json
{ "message": "User signed out successfully" }
```

## 🔧 Available Scripts

| Script | Description |
|--------|-------------|
| `npm run dev` | Start with hot reload (`--watch`) |
| `npm start` | Start in production mode |
| `npm run lint` | Lint with ESLint |
| `npm run lint:fix` | Auto-fix lint issues |
| `npm run format` | Format with Prettier |
| `npm run format:check` | Validate formatting |
| `npm run db:generate` | Generate Drizzle migration files |
| `npm run db:migrate` | Apply pending migrations |
| `npm run db:studio` | Open Drizzle Studio |

## 🏗️ Project Structure

```
src/
├── config/         # Logger, database, Arcjet client
├── controllers/    # Request handlers (auth)
├── middleware/     # Security / rate-limit middleware
├── models/         # Drizzle table definitions
├── routes/         # Express routers
├── services/       # Business logic & data access
├── utils/          # JWT helpers, cookie helpers, formatters
└── validations/    # Zod request schemas
```

## 🔐 Security

- Passwords are hashed with **bcrypt** before storage
- JWT tokens are stored in **HTTP-only cookies** to prevent XSS access
- **Arcjet** enforces role-based sliding-window rate limits and blocks known bots and attack patterns
- **Helmet** sets secure HTTP response headers
- Never commit real credentials — all secrets belong in environment files (which are git-ignored)

## 🌍 Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `PORT` | No | Server port (default: `3000`) |
| `NODE_ENV` | No | `development` \| `production` |
| `LOG_LEVEL` | No | Winston log level (default: `info`) |
| `DATABASE_URL` | **Yes** | Neon PostgreSQL connection string |
| `JWT_SECRET` | **Yes** | Secret for signing JWT tokens |
| `ARCHET_KEY` | **Yes** | Arcjet API key |
| `NEON_API_KEY` | Dev only | Neon API key for Neon Local Docker proxy |
| `NEON_PROJECT_ID` | Dev only | Neon project ID for Neon Local |
| `PARENT_BRANCH_ID` | Dev only | Parent branch for ephemeral dev branches |

## 📚 Additional Docs

- [Docker Setup Guide](./DOCKER_SETUP.md)
- [Windows Setup Guide](./WINDOWS_SETUP.md)

## 📄 License

ISC
