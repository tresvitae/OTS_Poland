# Frontend (Adventure OTS)

Web frontend for Adventure OTS, built with Next.js 14 App Router and Tailwind CSS.

The app provides account registration/login, character management, highscores, online player list, and client download page.

## Tech Stack

- Next.js 14.2 (App Router)
- React 18
- TypeScript
- Tailwind CSS 3

## Features

- Dark Fantasy RPG themed UI
- JWT-based client auth state (token in localStorage)
- Account flows: register, login, password change
- Character creation and character list for authenticated account
- Public highscores with pagination
- Public online players list with auto-refresh
- Download page that validates if Windows client ZIP is present

## Project Structure

```text
frontend/
├── src/
│   ├── app/
│   │   ├── layout.tsx            # Root layout + metadata
│   │   ├── page.tsx              # Homepage
│   │   ├── login/page.tsx        # Login form
│   │   ├── register/page.tsx     # Registration form
│   │   ├── account/page.tsx      # Account panel (JWT protected in client)
│   │   ├── highscores/page.tsx   # Ranking view
│   │   ├── online/page.tsx       # Who is online view
│   │   ├── download/page.tsx     # Client download page
│   │   └── globals.css           # Global styles + theme components
│   ├── components/
│   │   └── Navbar.tsx            # Main navigation
│   └── lib/
│       └── api.ts                # API wrapper + typed calls + token helpers
├── public/
│   └── downloads/
│       └── windows/
│           └── adventure-ots-client-windows.zip (optional runtime asset)
├── next.config.js
├── tailwind.config.ts
└── Dockerfile
```

## Requirements

- Node.js 18+ (Node.js 20 recommended)
- Running backend API (directly or via reverse proxy)

## Environment Variables

Create `.env.local` in this directory.

```env
NEXT_PUBLIC_API_URL=/api
```

Notes:

- In Docker + Nginx setup, `/api` is the recommended value.
- For local standalone frontend against local backend, you can use:

```env
NEXT_PUBLIC_API_URL=http://localhost:3001/api
```

## Local Development

```bash
npm install
npm run dev
```

Default dev URL:

- http://localhost:3000

## Build and Run

```bash
npm run build
npm start
```

`npm start` runs Next.js on port `3000`.

## Pages and Routes

- `/` - homepage with hero, server info, experience stages, quick links
- `/login` - login form (calls backend login endpoint)
- `/register` - account registration form
- `/account` - account panel (characters, character creation, password change)
- `/highscores` - global ranking with pagination (25 per page)
- `/online` - online players list, auto-refresh every 30 seconds
- `/download` - Windows client ZIP download page

## API Integration

Frontend API client is implemented in `src/lib/api.ts`.

Base URL:

- `process.env.NEXT_PUBLIC_API_URL || '/api'`

Token handling:

- Stored in `localStorage` under key `aac_token`
- Automatically sent as `Authorization: Bearer <token>` in `apiFetch`

Typed API methods currently used by pages:

- `api.register(name, password, email)`
- `api.login(name, password)`
- `api.changePassword(currentPassword, newPassword)`
- `api.getCharacters()`
- `api.createCharacter(name, vocation, sex)`
- `api.getHighscores(page, limit)`
- `api.getOnline()`

## Styling and Theme

Tailwind theme extensions are defined in `tailwind.config.ts`:

- Custom color palette: `abyss`, `blood`, `gold`, `stone`, `parchment`
- Fonts: `Cinzel`, `Inter`
- Custom utility classes and component classes in `src/app/globals.css`

Reusable style classes include:

- `.fantasy-card`
- `.btn-fantasy`
- `.btn-fantasy-gold`
- `.input-fantasy`
- `.table-fantasy`
- `.section-title`
- `.divider-fantasy`

## Download Asset Setup

The download page expects this file path:

- `frontend/public/downloads/windows/adventure-ots-client-windows.zip`

Behavior:

- If ZIP exists, page renders active download button to `/downloads/windows/adventure-ots-client-windows.zip`
- If missing, page shows warning message and no download button

## Docker Notes

This frontend is containerized with a multi-stage Docker build:

- Uses Next.js standalone output (`next.config.js` has `output: 'standalone'`)
- Runtime container exposes port `3000`
- In project compose, frontend gets:

```env
NEXT_PUBLIC_API_URL=/api
```

and mounts downloads directory:

- `./frontend/public/downloads:/app/public/downloads:ro`

## Typical Workflow

1. Start backend API and MariaDB database.
2. Start frontend with `npm run dev` (or via Docker Compose).
3. Register account on `/register`.
4. Login on `/login`.
5. Manage characters and password on `/account`.
6. Monitor `/highscores`, `/online`, and `/download` pages.

