// ============================================================
// Backend API — JWT Authentication Middleware
// Verifies Bearer token and attaches account info to request
// ============================================================

import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'change-this-secret-in-production';

// Extend Express Request to include account info
export interface AuthRequest extends Request {
    account?: {
        id: number;
        name: string;
    };
}

/**
 * Middleware: Verify JWT from Authorization header
 * Attaches decoded account data to req.account
 */
export function authMiddleware(req: AuthRequest, res: Response, next: NextFunction): void {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).json({ error: 'Brak tokenu autoryzacji' });
        return;
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, JWT_SECRET) as { id: number; name: string };
        req.account = { id: decoded.id, name: decoded.name };
        next();
    } catch {
        res.status(401).json({ error: 'Token nieprawidłowy lub wygasł' });
    }
}

/**
 * Sign a JWT token for a given account
 */
export function signToken(account: { id: number; name: string }): string {
    return jwt.sign(
        { id: account.id, name: account.name },
        JWT_SECRET,
        { expiresIn: '24h' }
    );
}
