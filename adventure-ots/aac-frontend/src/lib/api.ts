// ============================================================
// API Client — Fetch wrapper for AAC Backend
// Handles JWT token storage and API base URL
// ============================================================

const API_BASE = process.env.NEXT_PUBLIC_API_URL || '/api';

/**
 * Get JWT token from localStorage
 */
export function getToken(): string | null {
    if (typeof window === 'undefined') return null;
    return localStorage.getItem('aac_token');
}

/**
 * Store JWT token
 */
export function setToken(token: string): void {
    if (typeof window === 'undefined') return;
    localStorage.setItem('aac_token', token);
}

/**
 * Remove JWT token (logout)
 */
export function removeToken(): void {
    if (typeof window === 'undefined') return;
    localStorage.removeItem('aac_token');
}

/**
 * Check if user is authenticated
 */
export function isAuthenticated(): boolean {
    return !!getToken();
}

/**
 * API fetch wrapper with automatic auth header
 */
export async function apiFetch<T = unknown>(
    endpoint: string,
    options: RequestInit = {}
): Promise<T> {
    const token = getToken();

    const headers: Record<string, string> = {
        'Content-Type': 'application/json',
        ...(options.headers as Record<string, string> || {}),
    };

    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }

    const response = await fetch(`${API_BASE}${endpoint}`, {
        ...options,
        headers,
    });

    const data = await response.json();

    if (!response.ok) {
        throw new Error(data.error || 'Wystąpił nieznany błąd');
    }

    return data as T;
}

// ── Typed API calls ──────────────────────

export interface LoginResponse {
    token: string;
    account: { id: number; name: string };
    message: string;
}

export interface Character {
    id: number;
    name: string;
    level: number;
    vocation: number;
    vocation_name: string;
}

export interface HighscoreEntry {
    name: string;
    level: number;
    experience: number;
    vocation: number;
    vocation_name: string;
}

export interface OnlinePlayer {
    name: string;
    level: number;
    vocation: number;
    vocation_name: string;
}

export const api = {
    // Account
    register: (name: string, password: string, email: string) =>
        apiFetch('/account/register', {
            method: 'POST',
            body: JSON.stringify({ name, password, email }),
        }),

    login: (name: string, password: string) =>
        apiFetch<LoginResponse>('/account/login', {
            method: 'POST',
            body: JSON.stringify({ name, password }),
        }),

    changePassword: (currentPassword: string, newPassword: string) =>
        apiFetch('/account/password', {
            method: 'PUT',
            body: JSON.stringify({ currentPassword, newPassword }),
        }),

    getCharacters: () =>
        apiFetch<{ characters: Character[] }>('/account/characters'),

    // Character
    createCharacter: (name: string, vocation: number, sex: number) =>
        apiFetch('/character/create', {
            method: 'POST',
            body: JSON.stringify({ name, vocation, sex }),
        }),

    // Public
    getHighscores: (page = 1, limit = 25) =>
        apiFetch<{
            highscores: HighscoreEntry[];
            pagination: { page: number; limit: number; total: number; totalPages: number };
        }>(`/highscores?page=${page}&limit=${limit}`),

    getOnline: () =>
        apiFetch<{ online: OnlinePlayer[]; count: number }>('/online'),
};
