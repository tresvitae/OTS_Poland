// ============================================================
// AAC Backend — Express Server Entry Point
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

// ── Middleware ──────────────────────────
app.use(helmet());
app.use(cors());
app.use(express.json());

// ── Routes ─────────────────────────────
app.use('/api/account', accountRoutes);
app.use('/api/character', characterRoutes);
app.use('/api/highscores', highscoresRoutes);
app.use('/api/online', onlineRoutes);

// Health check
app.get('/api/health', (_req, res) => {
    res.json({ status: 'ok', service: 'aac-backend', timestamp: new Date().toISOString() });
});

// 404 fallback
app.use((_req, res) => {
    res.status(404).json({ error: 'Endpoint nie został znaleziony' });
});

// ── Start Server ───────────────────────
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🛡️  AAC Backend running on port ${PORT}`);
});

export default app;
