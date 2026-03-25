---
name: Backend Development
description: "Node.js + TypeScript + Express REST API for Adventure OTS. Use when: implementing API routes, adding database queries, configuring JWT authentication, debugging backend services, or connecting to MariaDB. Covers: Express routes, TypeScript conventions, TFS 1.4.2 schema compatibility, JWT patterns, error handling."
applyTo: "adventure-ots/backend/**"
---

# Backend Development Guidelines (Node.js + TypeScript + Express)

**Location**: `adventure-ots/backend/`

This is a headless REST API built with Express + TypeScript that directly interfaces with the TFS 1.4.2 MariaDB schema. All routes must use JWT authentication and return consistent JSON responses.

---

## 🚀 Quick Start

```bash
cd adventure-ots/backend

# Development server with hot-reload (ts-node)
npm run dev    # Listens on http://localhost:3001 (or configured PORT)

# Build TypeScript to /dist
npm run build

# Run production build
npm start
```

---

## 📂 Directory Structure

```
backend/
├── src/
│   ├── index.ts          # Express app setup, middleware, port config
│   ├── db.ts             # MariaDB connection pool (connects to 'db' hostname)
│   ├── auth.ts           # JWT token generation/verification
│   ├── routes/           # API endpoint definitions
│   │   ├── auth.ts       # Login/logout endpoints
│   │   ├── players.ts    # Player data endpoints
│   │   └── ...           # Additional resource routes
│   └── middleware/       # Custom Express middleware
├── dist/                 # Compiled JavaScript (generated)
├── package.json          # Dependencies, scripts
└── tsconfig.json         # TypeScript configuration
```

---

## 🔑 Key Files & Their Responsibilities

### `src/index.ts` — Express App Setup
- Initializes Express server
- Registers middleware (JSON parsing, CORS, auth)
- Defines server port (usually 3001, from `PORT` env var or default)
- Mounts route handlers
- Error handling middleware

**Keep minimal**: All business logic belongs in routes or services, not in index.ts.

### `src/db.ts` — Database Connection
- Creates MariaDB connection pool
- Connects to `db` hostname (internal Docker network)
- Pool configuration (min/max connections, timeout)
- Exports connection object for use in routes

**Critical**: Hostname is hardcoded as `db` (Docker internal DNS). Connection string must use TFS 1.4.2 default database name.

### `src/auth.ts` — JWT Authentication
- `generateToken(playerId: number): string` — Creates JWT for a player
- `verifyToken(token: string): PlayerId | null` — Validates and extracts payload
- Token expiration (usually 24h or configurable)
- Secret key from `JWT_SECRET` environment variable

**Security**: Always verify tokens in protected routes using middleware.

### `src/routes/*` — API Endpoints
- Each file exports an Express Router
- Mounted at specific paths (e.g., `/auth`, `/players`)
- Mounted in `index.ts` with `app.use(prefix, router)`

---

## 🗄️ TFS 1.4.2 Database Schema Compatibility

**Critical Requirement**: All queries must use exact TFS 1.4.2 table and column names.

### Common Tables
| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `accounts` | Player accounts | `id`, `name`, `password` (SHA1 hash) |
| `players` | Player characters | `id`, `name`, `account_id`, `level`, `vocation`, `health`, `mana`, `pos_x`, `pos_y`, `pos_z` |
| `player_inventory` | Item storage | `player_id`, `slot`, `itemtype`, `count` |
| `player_skills` | Player abilities | `player_id`, `skillid`, `value` |
| `tiles` | Map tiles (world) | Depends on map file format |

### Query Rules
1. **Always match exact column names** — TFS is strict about naming (e.g., `player_id` not `playerId`)
2. **Use parameterized queries** to prevent SQL injection: `?` placeholders with execute parameters
3. **Handle NULL values** explicitly in SELECT results
4. **Validate foreign keys** before INSERT/UPDATE (e.g., check `account_id` exists before creating player)

### Example Query (Safe)
```typescript
// ✅ CORRECT: Parameterized query
const result = await db.execute(
  'SELECT id, name, level FROM players WHERE account_id = ? AND name = ?',
  [accountId, playerName]
);

// ❌ WRONG: String concatenation (SQL injection risk)
const badResult = await db.execute(
  `SELECT id, name, level FROM players WHERE account_id = ${accountId}`
);
```

---

## 🔐 JWT Authentication Pattern

### Token Structure
- **Payload**: `{ playerId: number, iat: number, exp: number }`
- **Algorithm**: HS256 (HMAC SHA256)
- **Secret**: `JWT_SECRET` environment variable

### Protecting Routes
```typescript
import { Router } from 'express';
import { verifyToken } from '../auth';

const router = Router();

// Middleware to check JWT in Authorization header
router.get('/me', (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  
  const token = authHeader.slice(7);
  const playerId = verifyToken(token);
  if (!playerId) {
    return res.status(401).json({ error: 'Invalid token' });
  }
  
  req.playerId = playerId; // Attach to request for downstream handlers
  next();
});

router.get('/me', (req, res) => {
  // Now req.playerId is available
  res.json({ playerId: req.playerId });
});

export default router;
```

---

## 📝 TypeScript Conventions

### Type Definitions
- Define interfaces for database rows at the top of route files
- Reuse types across endpoints

```typescript
interface Player {
  id: number;
  name: string;
  account_id: number;
  level: number;
  vocation: number;
}

interface InventoryItem {
  player_id: number;
  slot: number;
  itemtype: number;
  count: number;
}
```

### Response Format
Always return consistent JSON structure:
```typescript
// Success
res.status(200).json({ success: true, data: { /* data */ } });

// Error
res.status(400).json({ success: false, error: 'Human-readable error message' });
```

### Async/Await
- All database operations are async; use `await` in route handlers
- Wrap in try/catch for error handling

```typescript
router.get('/players/:id', async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT * FROM players WHERE id = ?', [req.params.id]);
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Player not found' });
    }
    res.json(rows[0]);
  } catch (err) {
    console.error('Query failed:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

---

## 🐛 Common Pitfalls

### ❌ Hardcoding Database Host
```typescript
// WRONG — Won't work in Docker
const pool = mysql.createPool({
  host: 'localhost',
  database: 'tibia'
});
```

### ✅ Use Docker Hostname
```typescript
// CORRECT — Works in Docker Compose network
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'db',
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'tibia'
});
```

### ❌ Plaintext Passwords in Logs
```typescript
// WRONG
console.log('Connecting to:', connectionString);
```

### ✅ Sanitize Logs
```typescript
// CORRECT
console.log(`Connecting to database at ${process.env.DB_HOST}`);
```

### ❌ Forgetting to Hash Passwords
```typescript
// WRONG — Storing SHA1 locally, but comparison fails
const player = getPlayer(id);
if (player.password === hashSHA1(inputPassword)) { ... }
```

### ✅ Use TFS Compatible Hash
```typescript
// CORRECT — SHA1 to match TFS schema
import crypto from 'crypto';
const sha1Hash = crypto.createHash('sha1').update(password).digest('hex');
```

---

## 🚀 Development Workflow

### 1. Add a New Route
Create `src/routes/newfeature.ts`:
```typescript
import { Router } from 'express';

const router = Router();

router.get('/', (req, res) => {
  res.json({ message: 'New feature endpoint' });
});

export default router;
```

### 2. Mount in `src/index.ts`
```typescript
import newfeatureRoutes from './routes/newfeature';
app.use('/api/newfeature', newfeatureRoutes);
```

### 3. Test Locally
```bash
npm run dev
# In another terminal:
curl http://localhost:3001/api/newfeature
```

### 4. Hot-Reload in Docker
```bash
docker compose restart backend
# or use docker-compose logs to verify changes
docker logs -f backend
```

---

## 🔄 Building & Deployment

### Local Production Build
```bash
npm run build      # TypeScript → /dist
npm start          # Run from /dist
```

### Docker Build
```bash
cd adventure-ots
docker compose up -d --build backend
docker logs -f backend
```

### Health Check
```bash
curl http://localhost/api/health
# Expected: { "status": "ok" } or similar
```

---

## 🧪 Testing Backend Locally (Without Docker)

Requires local MariaDB or Docker database:
```bash
# Start only database
docker compose up -d db

# In backend, configure .env
DB_HOST=127.0.0.1
DB_USER=tibia_user
DB_PASSWORD=your_password
DB_NAME=tibia
JWT_SECRET=dev_secret

# Run backend
npm run dev
```

---

## ⚠️ Environment Variables

Create `.env` file (or `.env.local`) in `backend/`:
```env
# Database
DB_HOST=db                    # Docker: db, Local: localhost
DB_USER=tibia_user
DB_PASSWORD=your_secure_pass
DB_NAME=tibia

# Server
PORT=3001
NODE_ENV=development

# Authentication
JWT_SECRET=your_jwt_secret_here

# Logging
LOG_LEVEL=debug              # debug, info, warn, error
```

**Note**: In Docker Compose, `db` hostname is resolved internally. For local dev, use `localhost` or `127.0.0.1`.

---

## 📖 Reference

- [Express.js Docs](https://expressjs.com)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [mysql2 (MySQL driver) Docs](https://github.com/sidorares/node-mysql2)
- [JWT Best Practices](https://tools.ietf.org/html/rfc7519)
- [TFS 1.4.2 Schema](../../../adventure-ots/sql/schema.sql)
