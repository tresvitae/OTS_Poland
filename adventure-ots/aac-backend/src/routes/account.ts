// ============================================================
// AAC Backend — Account Routes
// Register, Login, Change Password, List Characters
// Password hashing: SHA1 (TFS 1.4.2 compatible)
// ============================================================

import { Router, Response } from 'express';
import crypto from 'crypto';
import pool from '../db';
import { authMiddleware, signToken, AuthRequest } from '../auth';
import { RowDataPacket, ResultSetHeader } from 'mysql2';

const router = Router();

/**
 * Hash password with SHA1 — identical to TFS 1.4.2 default
 * TFS stores: SHA1(password) as lowercase hex
 */
function sha1Hash(password: string): string {
    return crypto.createHash('sha1').update(password).digest('hex');
}

// ────────────────────────────────────────
// POST /api/account/register
// ────────────────────────────────────────
router.post('/register', async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { name, password, email } = req.body;

        // Validation
        if (!name || !password || !email) {
            res.status(400).json({ error: 'Nazwa konta, hasło i email są wymagane' });
            return;
        }

        if (name.length < 3 || name.length > 32) {
            res.status(400).json({ error: 'Nazwa konta musi mieć od 3 do 32 znaków' });
            return;
        }

        if (password.length < 4) {
            res.status(400).json({ error: 'Hasło musi mieć minimum 4 znaki' });
            return;
        }

        // Only allow alphanumeric account names
        if (!/^[a-zA-Z0-9]+$/.test(name)) {
            res.status(400).json({ error: 'Nazwa konta może zawierać tylko litery i cyfry' });
            return;
        }

        // Check if account name already exists
        const [existing] = await pool.query<RowDataPacket[]>(
            'SELECT id FROM accounts WHERE name = ?',
            [name]
        );

        if (existing.length > 0) {
            res.status(409).json({ error: 'Konto o tej nazwie już istnieje' });
            return;
        }

        // Check if email already used
        const [emailCheck] = await pool.query<RowDataPacket[]>(
            'SELECT id FROM accounts WHERE email = ?',
            [email]
        );

        if (emailCheck.length > 0) {
            res.status(409).json({ error: 'Ten adres email jest już używany' });
            return;
        }

        // Create account with SHA1 hashed password
        const hashedPassword = sha1Hash(password);
        const creation = Math.floor(Date.now() / 1000);

        const [result] = await pool.query<ResultSetHeader>(
            'INSERT INTO accounts (name, password, email, creation) VALUES (?, ?, ?, ?)',
            [name, hashedPassword, email, creation]
        );

        res.status(201).json({
            message: 'Konto zostało utworzone pomyślnie',
            accountId: result.insertId,
        });
    } catch (error) {
        console.error('Register error:', error);
        res.status(500).json({ error: 'Błąd serwera podczas rejestracji' });
    }
});

// ────────────────────────────────────────
// POST /api/account/login
// ────────────────────────────────────────
router.post('/login', async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { name, password } = req.body;

        if (!name || !password) {
            res.status(400).json({ error: 'Nazwa konta i hasło są wymagane' });
            return;
        }

        const hashedPassword = sha1Hash(password);

        const [rows] = await pool.query<RowDataPacket[]>(
            'SELECT id, name FROM accounts WHERE name = ? AND password = ?',
            [name, hashedPassword]
        );

        if (rows.length === 0) {
            res.status(401).json({ error: 'Nieprawidłowa nazwa konta lub hasło' });
            return;
        }

        const account = rows[0];
        const token = signToken({ id: account.id, name: account.name });

        res.json({
            message: 'Zalogowano pomyślnie',
            token,
            account: { id: account.id, name: account.name },
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Błąd serwera podczas logowania' });
    }
});

// ────────────────────────────────────────
// PUT /api/account/password (JWT required)
// ────────────────────────────────────────
router.put('/password', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { currentPassword, newPassword } = req.body;
        const accountId = req.account!.id;

        if (!currentPassword || !newPassword) {
            res.status(400).json({ error: 'Aktualne i nowe hasło są wymagane' });
            return;
        }

        if (newPassword.length < 4) {
            res.status(400).json({ error: 'Nowe hasło musi mieć minimum 4 znaki' });
            return;
        }

        // Verify current password
        const currentHashed = sha1Hash(currentPassword);
        const [rows] = await pool.query<RowDataPacket[]>(
            'SELECT id FROM accounts WHERE id = ? AND password = ?',
            [accountId, currentHashed]
        );

        if (rows.length === 0) {
            res.status(401).json({ error: 'Aktualne hasło jest nieprawidłowe' });
            return;
        }

        // Update password
        const newHashed = sha1Hash(newPassword);
        await pool.query(
            'UPDATE accounts SET password = ? WHERE id = ?',
            [newHashed, accountId]
        );

        res.json({ message: 'Hasło zostało zmienione pomyślnie' });
    } catch (error) {
        console.error('Password change error:', error);
        res.status(500).json({ error: 'Błąd serwera podczas zmiany hasła' });
    }
});

// ────────────────────────────────────────
// GET /api/account/characters (JWT required)
// ────────────────────────────────────────
router.get('/characters', authMiddleware, async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const accountId = req.account!.id;

        const [rows] = await pool.query<RowDataPacket[]>(
            `SELECT id, name, level, vocation, 
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
       WHERE account_id = ? AND deletion = 0
       ORDER BY level DESC`,
            [accountId]
        );

        res.json({ characters: rows });
    } catch (error) {
        console.error('Characters list error:', error);
        res.status(500).json({ error: 'Błąd serwera podczas pobierania postaci' });
    }
});

export default router;
