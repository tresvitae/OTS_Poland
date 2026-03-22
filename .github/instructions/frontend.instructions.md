---
name: Frontend Development
description: "Next.js 14 + Tailwind CSS web frontend (Dark Fantasy RPG theme). Use when: building React components, creating pages, styling with Tailwind, connecting to backend API, debugging UI/UX, or configuring Next.js. Covers: App Router, component structure, Tailwind conventions, API client patterns, environment setup."
applyTo: "adventure-ots/aac-frontend/**"
---

# Frontend Development Guidelines (Next.js 14 + Tailwind CSS)

**Location**: `adventure-ots/aac-frontend/`

This is a modern React frontend using Next.js 14 App Router with Tailwind CSS. It connects to the Node.js backend API and implements a Dark Fantasy RPG theme.

---

## 🚀 Quick Start

```bash
cd adventure-ots/aac-frontend

# Development server with hot-reload
npm run dev    # Listens on http://localhost:3000

# Production build
npm run build

# Run production build locally
npm start
```

---

## 📂 Directory Structure

```
aac-frontend/
├── src/
│   ├── app/                    # Next.js 14 App Router (pages & layouts)
│   │   ├── layout.tsx          # Root layout (shared HTML structure)
│   │   ├── page.tsx            # Homepage (http://localhost/)
│   │   ├── (auth)/             # Route group for auth pages
│   │   │   ├── login/
│   │   │   │   └── page.tsx
│   │   │   └── register/
│   │   │       └── page.tsx
│   │   ├── dashboard/
│   │   │   ├── layout.tsx      # Dashboard layout
│   │   │   └── page.tsx
│   │   └── api/                # API routes (backend proxies)
│   ├── components/             # Reusable React components
│   │   ├── Header.tsx
│   │   ├── Navigation.tsx
│   │   ├── Card.tsx
│   │   └── ...
│   ├── lib/                    # Utilities & API client
│   │   ├── api.ts              # Axios/fetch wrapper for backend
│   │   ├── auth.ts             # JWT token management
│   │   ├── constants.ts        # App constants, URLs
│   │   └── utils.ts
│   └── styles/                 # Global styles (if needed)
├── public/                     # Static assets (images, fonts)
├── next.config.js              # Next.js configuration
├── tailwind.config.ts          # Tailwind CSS theme configuration
├── postcss.config.js           # PostCSS for Tailwind
├── tsconfig.json               # TypeScript configuration
└── package.json                # Dependencies, scripts
```

---

## 🎨 Tailwind CSS & Dark Fantasy Theme

### Philosophy
- **No inline styles** — Use Tailwind utility classes exclusively
- **Dark theme** — Default dark background, light text
- **Fantasy aesthetic** — Gold/amber accents, dark purples, shadows for depth

### Primary Color Palette
```typescript
// tailwind.config.ts reference
colors: {
  dark: '#0f0e0e',        // Background
  slate: '#1a1a1a',       // Cards, panels
  gold: '#d4af37',        // Primary accent, borders
  amber: '#f59e0b',       // Secondary accent, hover states
  purple: '#6d28d9',      // Interactive elements
  red: '#dc2626',         // Errors, warnings
  emerald: '#10b981',     // Success states
  gray: '#6b7280',        // Text secondary
}
```

### Common Utility Patterns
```tsx
// Dark card with gold border
<div className="bg-slate-900 border border-gold-400 rounded-lg p-4 shadow-lg">
  Content
</div>

// Primary button (purple with gold text)
<button className="bg-purple-700 hover:bg-purple-600 text-gold-400 font-bold px-4 py-2 rounded transition-colors">
  Action
</button>

// Hero title with gold glow
<h1 className="text-4xl font-bold text-gold-400 drop-shadow-lg">
  Adventure OTS
</h1>

// Responsive grid
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  {/* Items */}
</div>
```

### Never Use Inline Styles
```tsx
// ❌ WRONG
<div style={{ backgroundColor: '#0f0e0e', padding: '1rem' }}>
  Content
</div>

// ✅ CORRECT
<div className="bg-dark p-4">
  Content
</div>
```

---

## 📄 Next.js 14 App Router Patterns

### File-Based Routing
- **Directories become routes**: `app/dashboard/` → `/dashboard`
- **`page.tsx` is the route component**: `app/dashboard/page.tsx` renders at `/dashboard`
- **`layout.tsx` wraps children**: Shared UI for a route segment and its children
- **Route groups `(name)/` don't affect URL**: `app/(auth)/login` → `/login` (not `/auth/login`)

### Creating a New Page
```tsx
// app/features/page.tsx
export default function FeaturesPage() {
  return (
    <main className="p-8">
      <h1 className="text-4xl font-bold text-gold-400">Features</h1>
      <p className="mt-4 text-gray-300">Coming soon...</p>
    </main>
  );
}
```

### Creating a Nested Layout
```tsx
// app/dashboard/layout.tsx
export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex min-h-screen bg-dark">
      <aside className="w-64 bg-slate-900 border-r border-gold-400 p-4">
        {/* Sidebar navigation */}
      </aside>
      <main className="flex-1 p-8">
        {children}
      </main>
    </div>
  );
}
```

### Dynamic Routes
```tsx
// app/player/[id]/page.tsx
export default function PlayerPage({ params }: { params: { id: string } }) {
  return <h1>Player {params.id}</h1>;
}

// Usage: /player/123 → params.id = "123"
```

### Server vs Client Components
- **Default: Server Components** (faster, can access backend directly)
- **Use `'use client'` for interactivity**: Event handlers, hooks (useState, useEffect)

```tsx
// ✅ Server Component (default)
export default function PlayerList() {
  // Can call backend directly here
  return <div>Player list</div>;
}

// ❌ Needs interactivity? Add 'use client'
'use client';

import { useState } from 'react';

export default function LoginForm() {
  const [email, setEmail] = useState('');
  // ...
}
```

---

## 🔌 Backend API Integration

### Setup: API Client (`lib/api.ts`)
```typescript
// lib/api.ts
const API_BASE = process.env.NEXT_PUBLIC_API_URL || '/api';

export async function apiCall<T>(
  endpoint: string,
  options?: RequestInit
): Promise<T> {
  const response = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  });

  if (!response.ok) {
    throw new Error(`API error: ${response.status}`);
  }

  return response.json();
}
```

### Environment Variable
```env
# .env.local (or docker-compose sets this)
NEXT_PUBLIC_API_URL=/api  # Proxied by Nginx in production, or Next.js in dev
```

### Using API in Components
```tsx
'use client';

import { useEffect, useState } from 'react';
import { apiCall } from '@/lib/api';

interface Player {
  id: number;
  name: string;
  level: number;
}

export default function PlayerCard({ playerId }: { playerId: number }) {
  const [player, setPlayer] = useState<Player | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    apiCall<Player>(`/players/${playerId}`)
      .then(setPlayer)
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [playerId]);

  if (loading) return <div className="text-gray-400">Loading...</div>;
  if (!player) return <div className="text-red-500">Player not found</div>;

  return (
    <div className="bg-slate-900 border border-gold-400 p-4 rounded-lg">
      <h2 className="text-2xl font-bold text-gold-400">{player.name}</h2>
      <p className="text-gray-300">Level {player.level}</p>
    </div>
  );
}
```

### JWT Token Management (`lib/auth.ts`)
```typescript
// lib/auth.ts
export function getToken(): string | null {
  return localStorage.getItem('auth_token');
}

export function setToken(token: string): void {
  localStorage.setItem('auth_token', token);
}

export function clearToken(): void {
  localStorage.removeItem('auth_token');
}

export async function apiCallWithAuth<T>(
  endpoint: string,
  options?: RequestInit
): Promise<T> {
  const token = getToken();
  
  return fetch(`/api${endpoint}`, {
    ...options,
    headers: {
      ...options?.headers,
      'Authorization': `Bearer ${token}`,
    },
  }).then(r => r.json());
}
```

---

## 🧩 Component Best Practices

### Component File Structure
```tsx
'use client'; // Only if needed

import React, { useState } from 'react';

interface CardProps {
  title: string;
  children: React.ReactNode;
}

/**
 * Reusable card component for displaying content
 */
export function Card({ title, children }: CardProps) {
  return (
    <div className="bg-slate-900 border border-gold-400 rounded-lg p-4">
      <h3 className="text-lg font-bold text-gold-400">{title}</h3>
      <div className="mt-4 text-gray-200">{children}</div>
    </div>
  );
}
```

### Props Typing
Always define props interfaces:
```tsx
// ✅ CORRECT
interface ButtonProps {
  variant: 'primary' | 'secondary';
  disabled?: boolean;
  onClick: () => void;
  children: React.ReactNode;
}

export function Button({ variant, disabled, onClick, children }: ButtonProps) {
  return (
    <button
      className={`px-4 py-2 rounded transition ${
        variant === 'primary' ? 'bg-purple-700 text-gold-400' : 'bg-slate-700'
      }`}
      disabled={disabled}
      onClick={onClick}
    >
      {children}
    </button>
  );
}

// ❌ WRONG: No typing
export function Button(props) {
  return <button {...props}>{props.children}</button>;
}
```

### Avoid Prop Drilling
Use context for shared state (auth, theme, user):
```tsx
// context/AuthContext.tsx
'use client';

import { createContext, useContext, useState } from 'react';

interface AuthContextType {
  token: string | null;
  setToken: (token: string | null) => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [token, setToken] = useState<string | null>(null);
  return (
    <AuthContext.Provider value={{ token, setToken }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
```

---

## 📱 Responsive Design

### Tailwind Breakpoints
- `sm`: 640px
- `md`: 768px
- `lg`: 1024px
- `xl`: 1280px
- `2xl`: 1536px

### Mobile-First Approach
```tsx
<div className="text-sm md:text-base lg:text-lg">
  Responsive text
</div>

<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
  {/* 1 column on mobile, 2 on tablet, 4 on desktop */}
</div>
```

---

## 🐛 Common Pitfalls

### ❌ Hardcoding API URLs
```typescript
// WRONG
const data = await fetch('http://localhost:3001/api/players');
```

### ✅ Use Environment Variables
```typescript
// CORRECT
const baseUrl = process.env.NEXT_PUBLIC_API_URL || '/api';
const data = await fetch(`${baseUrl}/players`);
```

### ❌ Forgetting `'use client'` for Interactivity
```tsx
// WRONG: This will crash (hooks don't work in server components)
export default function Form() {
  const [input, setInput] = useState('');
  return <input onChange={(e) => setInput(e.target.value)} />;
}

// CORRECT
'use client';
export default function Form() {
  const [input, setInput] = useState('');
  return <input onChange={(e) => setInput(e.target.value)} />;
}
```

### ❌ Using Inline Styles
```tsx
// WRONG
<div style={{ marginTop: '16px', color: '#d4af37' }}>
  Title
</div>

// CORRECT
<div className="mt-4 text-gold-400">
  Title
</div>
```

### ❌ Forgetting to Import Tailwind
```css
/* globals.css (should be imported in app/layout.tsx) */
@tailwind base;
@tailwind components;
@tailwind utilities;
```

---

## 🔄 Build & Deployment

### Local Production Build
```bash
npm run build      # Optimized production build
npm start          # Serve from .next/ directory
```

### Docker Build
```bash
cd adventure-ots
docker compose up -d --build aac_web
docker logs -f aac_web
```

### Verifying Frontend
```bash
curl http://localhost     # Should return HTML
curl http://localhost/api/health  # Should return backend API response
```

---

## ⚠️ Environment Variables

Create `.env.local` in `aac-frontend/`:
```env
# Backend API
NEXT_PUBLIC_API_URL=/api    # Relative to frontend (proxied by Nginx/dev server)

# Optional: For local dev without Docker
# NEXT_PUBLIC_API_URL=http://localhost:3001

# App settings
NEXT_PUBLIC_APP_NAME=Adventure OTS
NEXT_PUBLIC_APP_VERSION=1.0.0
```

**Note**: Only variables prefixed with `NEXT_PUBLIC_` are exposed to the browser.

---

## 📖 Reference

- [Next.js 14 App Router Docs](https://nextjs.org/docs/app)
- [Tailwind CSS Docs](https://tailwindcss.com/docs)
- [React Hooks Reference](https://react.dev/reference/react)
- [TypeScript in React](https://react.dev/learn/typescript)
- [Vercel Deployment Guide](https://vercel.com/docs)
