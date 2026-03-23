// ============================================================
// AAC Backend — Character Routes
// Create character with vocation selection
// ============================================================

import { Router, Response } from 'express';
import pool from '../db';
import { authMiddleware, AuthRequest } from '../auth';
import { RowDataPacket, ResultSetHeader } from 'mysql2';

const router = Router();

// Vocation configuration — TFS 1.4.2 IDs and starting stats (level 8)
const VOCATIONS: Record<number, {
    name: string;
    health: number;
    healthmax: number;
    mana: number;
    manamax: number;
    cap: number;
    soul: number;
    looktype: number;
}> = {
    1: { name: 'Sorcerer', health: 185, healthmax: 185, mana: 90, manamax: 90, cap: 470, soul: 100, looktype: 130 },
    2: { name: 'Druid', health: 185, healthmax: 185, mana: 90, manamax: 90, cap: 470, soul: 100, looktype: 130 },
    3: { name: 'Paladin', health: 185, healthmax: 185, mana: 90, manamax: 90, cap: 470, soul: 100, looktype: 129 },
    4: { name: 'Knight', health: 185, healthmax: 185, mana: 90, manamax: 90, cap: 470, soul: 100, looktype: 129 },
};

// Experience for level 8 (TFS formula: 50/3 * (n^3 - 6n^2 + 17n - 12))
const LEVEL_8_EXP = 4200;

// Default town ID
const DEFAULT_TOWN = 1;

// Max characters per account
const MAX_CHARACTERS = 10;

// ────────────────────────────────────────
// POST /api/character/create (JWT required)
// ────────────────────────────────────────
router.post('/create', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { name, vocation, sex } = req.body;
        const accountId = req.account!.id;

        // Validate name
        if (!name || typeof name !== 'string') {
            res.status(400).json({ error: 'Nazwa postaci jest wymagana' });
            return;
        }

        const trimmedName = name.trim();

        if (trimmedName.length < 2 || trimmedName.length > 29) {
            res.status(400).json({ error: 'Nazwa postaci musi mieć od 2 do 29 znaków' });
            return;
        }

        // Only allow letters and spaces, no consecutive spaces, no leading/trailing spaces
        if (!/^[a-zA-Z]+( [a-zA-Z]+)*$/.test(trimmedName)) {
            res.status(400).json({ error: 'Nazwa postaci może zawierać tylko litery i pojedyncze spacje' });
            return;
        }

        // Validate vocation
        const vocId = parseInt(vocation, 10);
        if (!VOCATIONS[vocId]) {
            res.status(400).json({ error: 'Nieprawidłowa profesja. Dozwolone: 1 (Sorcerer), 2 (Druid), 3 (Paladin), 4 (Knight)' });
            return;
        }

        // Validate sex (0 = female, 1 = male)
        const playerSex = sex === 1 ? 1 : 0;

        // Check character limit
        const [charCount] = await pool.query<RowDataPacket[]>(
            'SELECT COUNT(*) AS cnt FROM players WHERE account_id = ? AND deletion = 0',
            [accountId]
        );

        if (charCount[0].cnt >= MAX_CHARACTERS) {
            res.status(400).json({ error: `Osiągnięto limit postaci (${MAX_CHARACTERS})` });
            return;
        }

        // Check if name is taken
        const [existing] = await pool.query<RowDataPacket[]>(
            'SELECT id FROM players WHERE name = ?',
            [trimmedName]
        );

        if (existing.length > 0) {
            res.status(409).json({ error: 'Postać o tej nazwie już istnieje' });
            return;
        }

        // Resolve town spawn to avoid invalid default position (0,0,0).
        const [townRows] = await pool.query<RowDataPacket[]>(
            'SELECT id, posx, posy, posz FROM towns WHERE id = ? LIMIT 1',
            [DEFAULT_TOWN]
        );

        if (townRows.length === 0) {
            res.status(500).json({ error: 'Brak skonfigurowanego miasta startowego' });
            return;
        }

        const spawn = townRows[0];
        const voc = VOCATIONS[vocId];

        // Insert new character
        const [result] = await pool.query<ResultSetHeader>(
            `INSERT INTO players 
        (name, group_id, account_id, level, vocation, health, healthmax, 
         experience, looktype, maglevel, mana, manamax, soul, town_id, posx, posy, posz, cap, sex,
         skill_fist, skill_club, skill_sword, skill_axe, skill_dist, skill_shielding, skill_fishing)
       VALUES (?, 1, ?, 8, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 10, 10, 10, 10, 10, 10, 10)`,
            [
                trimmedName, accountId, vocId,
                voc.health, voc.healthmax, LEVEL_8_EXP,
                voc.looktype, voc.mana, voc.manamax,
                voc.soul, DEFAULT_TOWN, spawn.posx, spawn.posy, spawn.posz, voc.cap, playerSex,
            ]
        );

        res.status(201).json({
            message: `Postać "${trimmedName}" (${voc.name}) została utworzona`,
            characterId: result.insertId,
        });
    } catch (error) {
        console.error('Character creation error:', error);
        res.status(500).json({ error: 'Błąd serwera podczas tworzenia postaci' });
    }
});

export default router;
