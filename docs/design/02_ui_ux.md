# UI/UX Design

> **SDLC Stage 2: Design — Document 02**
> Wireframes for the website (AAC) and game client (OTClient) interface

---

## 1. Website (MyAAC) — Pages & Wireframes

### 1.1 Sitemap

```mermaid
graph TD
    HOME[🏠 Homepage] --> LOGIN[Login Page]
    HOME --> REGISTER[Register Page]
    HOME --> NEWS[News / Updates]
    HOME --> INFO[Server Info]
    HOME --> DOWNLOAD[Client Download]
    HOME --> HIGHSCORES[Highscores]

    LOGIN --> DASHBOARD[Account Dashboard]
    DASHBOARD --> CHARACTERS[My Characters]
    DASHBOARD --> CREATECHAR[Create Character]
    DASHBOARD --> SETTINGS[Account Settings]

    CHARACTERS --> CHARPROFILE[Character Profile]

    HOME --> ADMIN[Admin Panel]
    ADMIN --> ADMIN_DASH[Admin Dashboard]
    ADMIN --> MANAGE_ACC[Manage Accounts]
    ADMIN --> MANAGE_BAN[Manage Bans]
    ADMIN --> MANAGE_NEWS[Manage News]
```

### 1.2 Homepage

```
┌──────────────────────────────────────────────────────────┐
│  ⚔️ ADVENTURE OTS                    [Login] [Register]  │
├──────────────────────────────────────────────────────────┤
│  Home | News | Highscores | Server Info | Download       │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────────────────┐  ┌────────────────────────┐ │
│  │     HERO BANNER        │  │  SERVER STATUS          │ │
│  │                        │  │                         │ │
│  │  "Adventure Awaits"    │  │  Status: 🟢 Online     │ │
│  │                        │  │  Players: 5 / 20       │ │
│  │  [PLAY NOW →]          │  │  Uptime: 3d 12h        │ │
│  │                        │  │  Server Save: 06:00    │ │
│  └────────────────────────┘  │                         │ │
│                              │  [Download Client]      │ │
│  📰 LATEST NEWS              └────────────────────────┘ │
│  ┌────────────────────────────────────────────────────┐  │
│  │ 🔵 Server Launch v1.0!              2026-04-15    │  │
│  │    Welcome adventurers! Server is live...         │  │
│  ├────────────────────────────────────────────────────┤  │
│  │ 🔵 New Quest: Dragon's Lair         2026-04-10    │  │
│  │    Level 50+ quest with rare loot...              │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  🏆 TOP 5 PLAYERS                                        │
│  ┌──────┬──────────────┬───────┬────────┐               │
│  │ Rank │ Name         │ Level │ Voc    │               │
│  ├──────┼──────────────┼───────┼────────┤               │
│  │ 1    │ DragonSlayer │ 87    │ Knight │               │
│  │ 2    │ Frostmage    │ 72    │ Sorc   │               │
│  │ 3    │ HealBot      │ 65    │ Druid  │               │
│  └──────┴──────────────┴───────┴────────┘               │
│                                                          │
├──────────────────────────────────────────────────────────┤
│  Adventure OTS © 2026 | Powered by MyAAC + TFS 1.4.2    │
└──────────────────────────────────────────────────────────┘
```

### 1.3 Register Page

```
┌──────────────────────────────────────────────────────────┐
│  ⚔️ ADVENTURE OTS                    [Login] [Register]  │
├──────────────────────────────────────────────────────────┤
│                                                          │
│           ┌──────────────────────────────┐               │
│           │     CREATE ACCOUNT           │               │
│           │                              │               │
│           │  Account Name:               │               │
│           │  ┌────────────────────────┐  │               │
│           │  │                        │  │               │
│           │  └────────────────────────┘  │               │
│           │                              │               │
│           │  Email:                      │               │
│           │  ┌────────────────────────┐  │               │
│           │  │                        │  │               │
│           │  └────────────────────────┘  │               │
│           │                              │               │
│           │  Password:                   │               │
│           │  ┌────────────────────────┐  │               │
│           │  │ ●●●●●●●●              │  │               │
│           │  └────────────────────────┘  │               │
│           │                              │               │
│           │  Confirm Password:           │               │
│           │  ┌────────────────────────┐  │               │
│           │  │ ●●●●●●●●              │  │               │
│           │  └────────────────────────┘  │               │
│           │                              │               │
│           │  [  CREATE ACCOUNT  ]        │               │
│           │                              │               │
│           │  Already have an account?    │               │
│           │  [Login here]                │               │
│           └──────────────────────────────┘               │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### 1.4 Account Dashboard

```
┌──────────────────────────────────────────────────────────┐
│  ⚔️ ADVENTURE OTS              Welcome, user! [Logout]   │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ACCOUNT DASHBOARD                                       │
│  ┌──────────────────────────────────────────────────┐    │
│  │ Account: warrior123                              │    │
│  │ Email: w***@gmail.com                            │    │
│  │ Premium: No | Created: 2026-04-01                │    │
│  │ [Change Password] [Change Email]                 │    │
│  └──────────────────────────────────────────────────┘    │
│                                                          │
│  MY CHARACTERS                    [+ Create Character]   │
│  ┌──────────────────────────────────────────────────┐    │
│  │ ⚔️ DragonSlayer  │ Lv 87 │ Elite Knight │ Town A │    │
│  │    Status: Offline | Last seen: 2h ago           │    │
│  ├──────────────────────────────────────────────────┤    │
│  │ 🧙 Frostmage    │ Lv 72 │ Sorcerer    │ Town B │    │
│  │    Status: Online 🟢                             │    │
│  ├──────────────────────────────────────────────────┤    │
│  │ 🏹 QuickArrow   │ Lv 30 │ Paladin     │ Town A │    │
│  │    Status: Offline | Last seen: 1d ago           │    │
│  └──────────────────────────────────────────────────┘    │
│                                                          │
│  RECENT DEATHS                                           │
│  ┌──────────────────────────────────────────────────┐    │
│  │ DragonSlayer died at level 86 by Dragon Lord     │    │
│  │ 2026-04-14 21:30                                 │    │
│  └──────────────────────────────────────────────────┘    │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### 1.5 Create Character

```
┌──────────────────────────────────────────────────────────┐
│           ┌──────────────────────────────┐               │
│           │     CREATE CHARACTER         │               │
│           │                              │               │
│           │  Character Name:             │               │
│           │  ┌────────────────────────┐  │               │
│           │  │                        │  │               │
│           │  └────────────────────────┘  │               │
│           │                              │               │
│           │  Sex:   ○ Male  ○ Female     │               │
│           │                              │               │
│           │  Starting Town:              │               │
│           │  ┌────────────────────────┐  │               │
│           │  │ Town A            ▼    │  │               │
│           │  └────────────────────────┘  │               │
│           │                              │               │
│           │  (Vocation chosen at Lv 8)   │               │
│           │                              │               │
│           │  [  CREATE CHARACTER  ]       │               │
│           └──────────────────────────────┘               │
└──────────────────────────────────────────────────────────┘
```

### 1.6 Server Info Page

```
┌──────────────────────────────────────────────────────────┐
│  SERVER INFORMATION                                      │
│                                                          │
│  ┌──────────────────────┬───────────────────────────┐    │
│  │ Server Name          │ Adventure OTS             │    │
│  │ Protocol             │ 10.98                     │    │
│  │ World Type           │ Open PvP                  │    │
│  │ Experience Rate       │ 5x                       │    │
│  │ Skill Rate           │ 3x                        │    │
│  │ Loot Rate            │ 2x                        │    │
│  │ Magic Rate           │ 3x                        │    │
│  │ Server Save          │ Daily at 06:00 CET        │    │
│  │ Protection Level     │ 50                        │    │
│  ├──────────────────────┴───────────────────────────┤    │
│  │                                                   │    │
│  │  📋 SERVER RULES                                  │    │
│  │  1. No botting or multiclient                     │    │
│  │  2. Be respectful to other players                │    │
│  │  3. No real-money trading                         │    │
│  │  4. Admin decisions are final                     │    │
│  │                                                   │    │
│  └───────────────────────────────────────────────────┘    │
│                                                          │
│  [Download OTClient (Windows)]                           │
│  [Setup Instructions]                                    │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## 2. Game Client (OTClient) — HUD Layout

### 2.1 Main Game Screen

```
┌──────────────────────────────────────────────────────────────────┐
│ ┌──────────────────────────────────────────┐ ┌────────────────┐ │
│ │                                          │ │ MINIMAP        │ │
│ │                                          │ │ ┌────────────┐ │ │
│ │                                          │ │ │     N      │ │ │
│ │                                          │ │ │   . · .    │ │ │
│ │           GAME VIEWPORT                  │ │ │  · ▲ ·     │ │ │
│ │           (15 × 11 tiles)                │ │ │   . · .    │ │ │
│ │                                          │ │ └────────────┘ │ │
│ │        ┌───┐                             │ │ Floor: 7 (GF)  │ │
│ │        │ 🧙│ ← player                    │ │ X:100 Y:100    │ │
│ │        └───┘                             │ ├────────────────┤ │
│ │                     ┌───┐                │ │ HP ████████░░  │ │
│ │                     │ 🐉│ ← creature     │ │ MP ██████░░░░  │ │
│ │                     └───┘                │ ├────────────────┤ │
│ │                                          │ │ INVENTORY      │ │
│ │                                          │ │ ┌──┬──┬──┐     │ │
│ │                                          │ │ │⛑ │🛡 │📿│     │ │
│ │                                          │ │ ├──┼──┼──┤     │ │
│ │                                          │ │ │🗡 │👕│🎒│     │ │
│ │                                          │ │ ├──┼──┼──┤     │ │
│ │                                          │ │ │👢│👖│🏹│     │ │
│ │                                          │ │ └──┴──┴──┘     │ │
│ └──────────────────────────────────────────┘ └────────────────┘ │
│ ┌──────────────────────────────────────────────────────────────┐ │
│ │ 💬 CHAT                                                      │ │
│ │ [Default] [Trade] [Help] [Guild]                             │ │
│ │ ──────────────────────────────────────────────────            │ │
│ │ 21:30 DragonSlayer: Anyone for Dragon's Lair quest?          │ │
│ │ 21:30 Frostmage: I'm in!                                    │ │
│ │ 21:31 HealBot [heals]: Exura Gran                           │ │
│ │ ┌──────────────────────────────────────────────────────────┐ │ │
│ │ │ Type here...                                     [Send] │ │ │
│ │ └──────────────────────────────────────────────────────────┘ │ │
│ └──────────────────────────────────────────────────────────────┘ │
│ ┌──────────────────────────────────────────────────────────────┐ │
│ │ HOTBAR:  [F1 Heal] [F2 Haste] [F3 Attack] [F4 UE] ... [F12]│ │
│ └──────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Panel Breakdown

| Panel | Position | Content |
|-------|----------|---------|
| **Game Viewport** | Center-left (main area) | 15×11 tile grid, player centered |
| **Minimap** | Top-right | Explored area, compass, coordinates |
| **HP/MP Bars** | Right (below minimap) | Health + mana + possibly stamina |
| **Inventory** | Right (below bars) | 10 equip slots (3×3 grid + backpack) |
| **Chat** | Bottom | Tabbed channels, message history, input |
| **Hotbar** | Bottom bar | F1–F12 spell/item shortcuts |

### 2.3 Additional Windows (Toggleable)

```
┌─── SKILLS WINDOW ────┐    ┌─── BATTLE WINDOW ───┐
│ Fist:        10      │    │ 🐉 Dragon Lord  ████│
│ Club:        10      │    │ 🐺 Wolf         ██░░│
│ Sword:       45 ↗    │    │ 🧙 Frostmage   ████│
│ Axe:         10      │    │                     │
│ Distance:    10      │    └─────────────────────┘
│ Shielding:   38 ↗    │
│ Fishing:     12      │    ┌─── VIP LIST ────────┐
│ Magic Level: 22 ↗    │    │ 🟢 DragonSlayer     │
│ Level:       87      │    │ 🟢 Frostmage        │
│ Experience:  ████ 45%│    │ 🔴 QuickArrow       │
│ Stamina:  38h 20m    │    │ 🔴 HealBot          │
└──────────────────────┘    └─────────────────────┘

┌─── TRADE WINDOW ─────────────────────────┐
│ NPC Sam (Weapons)                        │
│ ┌──────────────┬────────┬───────┐        │
│ │ Item         │ Buy    │ Sell  │        │
│ │ Sword        │ 85 gp  │ 25 gp│        │
│ │ Battle Axe   │ 235 gp │ 80 gp│        │
│ │ Crossbow     │ 160 gp │ 50 gp│        │
│ └──────────────┴────────┴───────┘        │
│ [Buy] [Sell]                             │
└──────────────────────────────────────────┘
```

---

## 3. Visual Design Direction

### 3.1 Color Palette

| Element | Color | Hex | Usage |
|---------|-------|-----|-------|
| **Primary BG** | Dark charcoal | `#1a1a2e` | Website background, panels |
| **Secondary BG** | Deep navy | `#16213e` | Cards, containers |
| **Accent** | Gold | `#e2b714` | Headers, buttons, highlights |
| **Text Primary** | Light cream | `#eaeaea` | Body text |
| **Text Secondary** | Muted silver | `#8892b0` | Subtitles, labels |
| **Success** | Emerald | `#2ecc71` | Online status, health bar |
| **Danger** | Crimson | `#e74c3c` | Errors, death, mana |
| **Mana Blue** | Royal blue | `#3498db` | Mana bar |
| **Link** | Soft blue | `#5dade2` | Clickable links |

### 3.2 Typography

| Use | Font | Fallback |
|-----|------|----------|
| **Headings** | MedievalSharp (Google Fonts) | Georgia, serif |
| **Body** | Inter | Roboto, sans-serif |
| **Monospace** | JetBrains Mono | monospace |
| **In-game chat** | Martel Sans | sans-serif |

### 3.3 Design Principles

| Principle | Application |
|-----------|-------------|
| **Dark fantasy theme** | Matches Tibia's medieval aesthetic |
| **Minimal, clean layout** | Few elements on screen; no clutter |
| **Parchment/stone textures** | Subtle background textures for immersion |
| **Gold accents** | Call-to-action buttons, important stats |
| **Responsive** | Website works on mobile for checking status |

---

## 4. Key User Flows

### 4.1 New Player Journey

```mermaid
flowchart TD
    A[Visit Website] --> B[Register Account]
    B --> C[Create Character]
    C --> D[Download OTClient]
    D --> E[Configure IP + Start Client]
    E --> F[Login with Account]
    F --> G[Select Character]
    G --> H[Enter Game World]
    H --> I[Rookie Tutorial Area]
    I --> J[Choose Vocation at Lv 8]
    J --> K[Explore Main Continent]
```

### 4.2 Game Session Flow

```mermaid
flowchart LR
    LOGIN[Login] --> MAP[Appear on Map]
    MAP --> HUNT[Hunt Creatures]
    HUNT --> LOOT[Collect Loot]
    LOOT --> SELL[Sell at NPC]
    SELL --> UPGRADE[Buy Better Gear]
    UPGRADE --> QUEST[Do Quests]
    QUEST --> LEVEL[Level Up!]
    LEVEL --> HUNT
    LEVEL --> LOGOUT[Logout → Auto-save]
```
