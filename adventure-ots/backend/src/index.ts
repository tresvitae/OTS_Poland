// ============================================================
// Backend API — Express Server Entry Point
// Mounts all routes, configures middleware, starts HTTP server
// ============================================================

import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

import accountRoutes from './routes/account';
import characterRoutes from './routes/character';
import highscoresRoutes from './routes/highscores';
import onlineRoutes from './routes/online';

const app = express();
const PORT = parseInt(process.env.PORT || '3001', 10);
const LOG_LEVEL = (process.env.LOG_LEVEL || 'info').toLowerCase();

function isInfoLoggingEnabled(level: string): boolean {
    return level === 'info' || level === 'debug' || level === 'trace';
}

// ── Middleware ──────────────────────────
app.use(helmet());
app.use(cors());
app.use(express.json());

if (isInfoLoggingEnabled(LOG_LEVEL)) {
    app.use((req, res, next) => {
        const startedAt = Date.now();
        res.on('finish', () => {
            const durationMs = Date.now() - startedAt;
            console.log(
                `[INFO] ${req.method} ${req.originalUrl} ${res.statusCode} ${durationMs}ms ip=${req.ip}`
            );
        });
        next();
    });
}

// ── Routes ─────────────────────────────
app.use('/api/account', accountRoutes);
app.use('/api/character', characterRoutes);
app.use('/api/highscores', highscoresRoutes);
app.use('/api/online', onlineRoutes);

// Health check
app.get('/api/health', (_req, res) => {
    res.json({ status: 'ok', service: 'backend', timestamp: new Date().toISOString() });
});

// 404 fallback
app.use((_req, res) => {
    res.status(404).json({ error: 'Endpoint nie został znaleziony' });
});

// ── Start Server ───────────────────────
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🛡️  Backend API running on port ${PORT} (LOG_LEVEL=${LOG_LEVEL})`);
});

export default app;
