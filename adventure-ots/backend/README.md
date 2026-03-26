# Backend API (Adventure OTS)

REST API for Adventure OTS Account Management, built with Express + TypeScript.

This service handles account registration/login, JWT-protected account operations, character creation, highscores, and online player listing against a TFS-compatible MariaDB schema.

## Tech Stack

- Node.js + TypeScript
- Express 4
- MariaDB 10.11 (via `mysql2/promise` driver)
- JWT (`jsonwebtoken`)
- Security middleware: `helmet`, `cors`

## Project Structure

```text
backend/
├── src/
│   ├── index.ts              # Express app bootstrap, middleware, route mounting
│   ├── db.ts                 # DB pool configuration
│   ├── auth.ts               # JWT sign/verify middleware
│   └── routes/
│       ├── account.ts        # Register/login/password/owned characters
│       ├── character.ts      # Character creation
│       ├── highscores.ts     # Ranking with pagination
│       └── online.ts         # Current online players
├── package.json
└── tsconfig.json
```

## Requirements

- Node.js 18+
- MariaDB database with TFS-compatible tables (`accounts`, `players`, `players_online`, `towns`)

## Environment Variables

Create `.env` in this directory.

```env
# Server
PORT=3001
LOG_LEVEL=info

# Database
DB_HOST=db
DB_PORT=3306
DB_USER=forgottenserver
DB_PASSWORD=tibia_pass
DB_NAME=ots_baza

# Auth
JWT_SECRET=change-this-secret-in-production
```

Notes:

- `DB_HOST` defaults to `db` (Docker Compose network name).
- Password hashing for accounts is SHA1 to match TFS behavior.
- JWT token expiry is 24h.

## Local Development

```bash
npm install
npm run dev
```

Server starts at:

- `http://localhost:3001`

## Build and Run

```bash
npm run build
npm start
```

## API Base URL

- Local direct backend: `http://localhost:3001/api`
- Health endpoint: `GET /api/health`

## Authentication

Protected endpoints require:

```http
Authorization: Bearer <jwt_token>
```

JWT payload contains account identity:

```json
{
	"id": 123,
	"name": "accountName"
}
```

## Endpoints

### Health

- `GET /api/health`

Response:

```json
{
	"status": "ok",
	"service": "backend",
	"timestamp": "2026-03-24T10:00:00.000Z"
}
```

### Account

- `POST /api/account/register`
- `POST /api/account/login`
- `PUT /api/account/password` (JWT required)
- `GET /api/account/characters` (JWT required)

#### Register

`POST /api/account/register`

Body:

```json
{
	"name": "myaccount",
	"password": "secret123",
	"email": "mail@example.com"
}
```

Rules:

- `name`: 3-32 chars, alphanumeric only
- `password`: min 4 chars
- unique account name and email

#### Login

`POST /api/account/login`

Body:

```json
{
	"name": "myaccount",
	"password": "secret123"
}
```

Response includes token:

```json
{
	"message": "Zalogowano pomyślnie",
	"token": "<jwt>",
	"account": {
		"id": 1,
		"name": "myaccount"
	}
}
```

#### Change Password

`PUT /api/account/password` (JWT required)

Body:

```json
{
	"currentPassword": "oldPassword",
	"newPassword": "newPassword"
}
```

#### List Account Characters

`GET /api/account/characters` (JWT required)

Response:

```json
{
	"characters": [
		{
			"id": 10,
			"name": "Knight Example",
			"level": 30,
			"vocation": 4,
			"vocation_name": "Knight"
		}
	]
}
```

### Character

- `POST /api/character/create` (JWT required)

#### Create Character

`POST /api/character/create`

Body:

```json
{
	"name": "New Knight",
	"vocation": 4,
	"sex": 1
}
```

Rules:

- `name`: 2-29 chars, letters and single spaces only
- `vocation`: 1 (Sorcerer), 2 (Druid), 3 (Paladin), 4 (Knight)
- `sex`: 0 (female) or 1 (male)
- max 10 non-deleted characters per account
- character name must be unique

Creation defaults:

- level 8
- experience 4200
- spawn from `towns` table (`DEFAULT_TOWN = 1`)

### Highscores

- `GET /api/highscores?page=1&limit=25`

Query params:

- `page`: minimum 1, default 1
- `limit`: 1-100, default 25

Response:

```json
{
	"highscores": [
		{
			"name": "Top Player",
			"level": 120,
			"experience": 123456789,
			"vocation": 8,
			"vocation_name": "Elite Knight"
		}
	],
	"pagination": {
		"page": 1,
		"limit": 25,
		"total": 500,
		"totalPages": 20
	}
}
```

### Online Players

- `GET /api/online`

Response:

```json
{
	"online": [
		{
			"name": "Player One",
			"level": 42,
			"vocation": 7,
			"vocation_name": "Royal Paladin"
		}
	],
	"count": 1
}
```

## Error Handling

- Validation/auth errors return `400`, `401`, or `409` with JSON `{ "error": "..." }`
- Unexpected failures return `500` with JSON `{ "error": "..." }`
- Unknown routes return `404` with JSON error message

## Logging

- Request logs are enabled when `LOG_LEVEL` is `info`, `debug`, or `trace`
- Log format:

```text
[INFO] GET /api/health 200 2ms ip=::1
```

