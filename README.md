# Acquisitions API

A secure, production-ready RESTful API built with **Node.js** and **Express**, featuring JWT authentication, role-based rate limiting, and PostgreSQL via Neon.

## ✨ Features

- **Authentication** — JWT-based sign-up, sign-in, and sign-out with HTTP-only cookies
- **Security** — Helmet headers, CORS, bot detection, and shield protection via [Arcjet](https://arcjet.com)
- **Rate Limiting** — Role-aware sliding-window rate limits (admin / user / guest)
- **Database** — PostgreSQL (Neon) with Drizzle ORM and auto-generated migrations
- **Validation** — Request validation with Zod schemas
- **Logging** — Structured logging via Winston with Morgan HTTP request logs
- **Docker** — Dev and production Docker Compose setups with Neon Local proxy

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Runtime | Node.js (ES Modules) |
| Framework | Express 5 |
| Database | PostgreSQL · Neon · Drizzle ORM |
| Auth | JWT · bcrypt |
| Security | Helmet · Arcjet · CORS |
| Validation | Zod |
| Logging | Winston · Morgan |
| Containerisation | Docker · Docker Compose |

## 📋 Prerequisites

- Node.js 18+
- A [Neon](https://neon.tech) PostgreSQL database
- An [Arcjet](https://arcjet.com) account and API key

## 🚀 Quick Start

### 1. Install dependencies

```bash
npm install
```

### 2. Configure environment variables

```bash
cp .env.example .env
```

Edit `.env` with your values:

```env
PORT=3000
NODE_ENV=development
LOG_LEVEL=info

DATABASE_URL=postgresql://username:password@endpoint.neon.tech/database?sslmode=require

JWT_SECRET=your_jwt_secret_here
ARCHET_KEY=your_arcjet_key_here
```

### 3. Run database migrations

```bash
npm run db:migrate
```

### 4. Start the server

```bash
# Development (hot reload)
npm run dev

# Production
npm start
```

The API will be available at `http://localhost:3000`.

## 🐳 Docker Setup

Docker Compose configurations are provided for both development (with Neon Local proxy) and production (direct Neon Cloud connection).

See **[DOCKER_SETUP.md](./DOCKER_SETUP.md)** for full instructions, or **[WINDOWS_SETUP.md](./WINDOWS_SETUP.md)** for Windows-specific guidance.

```bash
# Development
npm run dev:docker

# Production
npm run prod:docker
```

## 📡 API Reference

### Base Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/` | Hello endpoint |
| `GET` | `/health` | Health check (status, uptime) |
| `GET` | `/api` | API status |

### Authentication — `/api/auth`

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/auth/sign-up` | Register a new user |
| `POST` | `/api/auth/sign-in` | Sign in an existing user |
| `POST` | `/api/auth/sign-out` | Sign out (clears token cookie) |

#### Sign Up

```http
POST /api/auth/sign-up
Content-Type: application/json

{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "password": "securepassword",
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

#### Sign In

```http
POST /api/auth/sign-in
Content-Type: application/json

{
  "email": "jane@example.com",
  "password": "securepassword"
}
```

**Response `200`**

```json
{
  "message": "User signed in successfully",
  "user": { "id": 1, "name": "Jane Doe", "email": "jane@example.com", "role": "user" }
}
```

#### Sign Out

```http
POST /api/auth/sign-out
```

**Response `200`**

```json
{ "message": "User signed out successfully" }
```

## 🔒 Rate Limiting

Requests are rate-limited per role using a 1-minute sliding window:

| Role | Requests / minute |
|------|-------------------|
| `admin` | 20 |
| `user` | 10 |
| `guest` (unauthenticated) | 5 |

## 🗄️ Database

```bash
# Generate a new migration after model changes
npm run db:generate

# Apply pending migrations
npm run db:migrate

# Open Drizzle Studio (browser-based DB viewer)
npm run db:studio
```

## 🧹 Code Quality

```bash
# Lint
npm run lint
npm run lint:fix

# Format
npm run format
npm run format:check
```

## 📁 Project Structure

```
src/
├── config/          # Logger, database, Arcjet client
├── controllers/     # Route handlers (auth)
├── middleware/      # Security middleware (Arcjet)
├── models/          # Drizzle schema definitions
├── routes/          # Express routers
├── services/        # Business logic / data access
├── utils/           # JWT, cookie helpers, formatters
└── validations/     # Zod schemas
```

## 📄 License

ISC
