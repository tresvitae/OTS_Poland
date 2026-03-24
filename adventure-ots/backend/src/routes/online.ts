// ============================================================
// Backend API — Who Is Online Route
// Lists currently online players from players_online table
// ============================================================

import { Router, Request, Response } from 'express';
import pool from '../db';
import { RowDataPacket } from 'mysql2';

const router = Router();

// ────────────────────────────────────────
// GET /api/online
// ────────────────────────────────────────
router.get('/', async (_req: Request, res: Response): Promise<void> => {
    try {
        const [rows] = await pool.query<RowDataPacket[]>(
            `SELECT p.name, p.level, p.vocation,
              CASE p.vocation
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
       FROM players_online po
       JOIN players p ON po.player_id = p.id
       ORDER BY p.level DESC`
        );

        res.json({
            online: rows,
            count: rows.length,
        });
    } catch (error) {
        console.error('Online players error:', error);
        res.status(500).json({ error: 'Błąd serwera podczas pobierania listy online' });
    }
});

export default router;
