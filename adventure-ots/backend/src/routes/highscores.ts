// ============================================================
// Backend API — Highscores Route
// Top players ranked by experience with pagination
// ============================================================

import { Router, Request, Response } from 'express';
import pool from '../db';
import { RowDataPacket } from 'mysql2';

const router = Router();

// ────────────────────────────────────────
// GET /api/highscores?page=1&limit=25
// ────────────────────────────────────────
router.get('/', async (req: Request, res: Response): Promise<void> => {
    try {
        const page = Math.max(1, parseInt(req.query.page as string, 10) || 1);
        const limit = Math.min(100, Math.max(1, parseInt(req.query.limit as string, 10) || 25));
        const offset = (page - 1) * limit;

        // Get total count (exclude GMs group_id > 3, deleted chars, and group_id 0)
        const [countResult] = await pool.query<RowDataPacket[]>(
            'SELECT COUNT(*) AS total FROM players WHERE group_id <= 3 AND group_id >= 1 AND deletion = 0'
        );
        const total = countResult[0].total;

        // Get ranked players
        const [rows] = await pool.query<RowDataPacket[]>(
            `SELECT name, level, experience, vocation,
              CASE vocation
                WHEN 0 THEN 'None'
                WHEN 1 THEN 'Sorcerer'
                WHEN 2 THEN 'Druid'
                WHEN 3 THEN 'Paladin'
                WHEN 4 THEN 'Knight'
                WHEN 5 THEN 'Master Sorcerer'
                WHEN 6 THEN 'Elder Druid'
                WHEN 7 THEN 'Royal Paladin'
                WHEN 8 THEN 'Elite Knight'
                ELSE 'Unknown'
              END AS vocation_name
       FROM players
       WHERE group_id <= 3 AND group_id >= 1 AND deletion = 0
       ORDER BY experience DESC, level DESC
       LIMIT ? OFFSET ?`,
            [limit, offset]
        );

        res.json({
            highscores: rows,
            pagination: {
                page,
                limit,
                total,
                totalPages: Math.ceil(total / limit),
            },
        });
    } catch (error) {
        console.error('Highscores error:', error);
        res.status(500).json({ error: 'Błąd serwera podczas pobierania rankingu' });
    }
});

export default router;
