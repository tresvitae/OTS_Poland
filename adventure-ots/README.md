# 🛡️ Adventure OTS — Docker Development Environment

Kompletne środowisko deweloperskie do uruchomienia serwera Tibia OTS z użyciem Docker Compose.

## 🏗️ Stack

| Serwis | Kontener | Port | Opis |
|--------|----------|------|------|
| **MariaDB 10.11** | `ots_db` | `3306` | Baza danych |
| **TFS 1.4.2** | `ots_engine` | `7171`, `7172` | Silnik gry |
| **AAC Backend** | `aac_api` | `3001` (wewnętrzny) | API (Node.js + TypeScript) |
| **AAC Frontend** | `aac_web` | `3000` (wewnętrzny) | Strona SPA (Next.js + Tailwind) |
| **Nginx** | `aac_proxy` | `80` | Reverse Proxy |

## 📂 Struktura

```
adventure-ots/
├── docker-compose.yml          # Orkiestracja kontenerów
├── sql/
│   └── 02_seed_data.sql        # Konto admina (1/1)
├── tfs/
│   ├── Dockerfile              # Budowa silnika z źródeł (Alpine)
│   ├── config.lua              # Konfiguracja Docker
│   ├── config.lua.dist         # Oryginalna konfiguracja
│   ├── schema.sql              # Schemat bazy TFS
│   └── data/                   # Dane gry (mapy, NPC, spelle...)
├── aac-backend/
│   ├── Dockerfile              # Node.js 20 Alpine (multi-stage)
│   ├── package.json            # Express, mysql2, JWT, Helmet
│   └── src/                    # TypeScript API (routes, auth, db)
├── aac-frontend/
│   ├── Dockerfile              # Next.js 14 standalone (multi-stage)
│   ├── package.json            # React 18, Tailwind CSS
│   └── src/                    # App Router (pages, components)
├── nginx/
│   ├── Dockerfile              # Nginx Alpine
│   └── nginx.conf              # Reverse proxy (/api → backend)
└── client/
    ├── Dockerfile              # OTClient Mehah
    ├── init.lua                # Punkt startowy (setUniqueServer)
    └── data/things/            # ⚠️ Wymagane assety Tibia
```

## 🚀 Szybki Start

### Wymagania
- Docker Desktop / Docker Engine + Docker Compose
- Minimum **4 GB RAM** dla Dockera
- Assety Tibia (`.spr`, `.dat`) dla protokołu **1098** w `client/data/things/1098/`

### Uruchomienie

```bash
cd adventure-ots
docker compose up -d --build
```

> ⏱️ Pierwsze uruchomienie: **5-15 minut** (kompilacja TFS z C++)

### Dostęp

| Usługa | URL / Adres |
|--------|-------------|
| **Strona WWW (AAC)** | http://localhost |
| **API Backend** | http://localhost/api/health |
| **Serwer gry** | `127.0.0.1:7171` (w kliencie) |
| **Baza danych** | `localhost:3306` |

> ✅ **Status WWW:** Strona (AAC) działa poprawnie pod adresem `http://localhost`. Tworzenie nowych użytkowników i zapis do bazy danych funkcjonuje prawidłowo. Funkcjonalności te są w pełni dostępne po ponownym uruchomieniu (restarcie) kontenerów.

### Domyślne konto
- **Login:** `1`
- **Hasło:** `1`
- **Postać:** `Admin` (GOD, level 100)

## 🔧 Konfiguracja

### Baza danych
Dane logowania (w `docker-compose.yml`):
```
MYSQL_ROOT_PASSWORD: twoje_haslo
MYSQL_DATABASE: ots_baza
```

### Silnik gry
Edytuj `tfs/config.lua`:
- `serverName` — nazwa serwera
- `experienceStages` — etapy doświadczenia
- `mapName` — nazwa mapy (bez `.otbm`)

RSA key (`key.pem`) jest teraz tworzony automatycznie przy starcie kontenera `gameserver`, jeśli plik nie istnieje lub jest uszkodzony.

### AAC Backend
Zmienne środowiskowe (w `docker-compose.yml`):
- `JWT_SECRET` — zmień na losowy ciąg znaków w produkcji
- `DB_*` — dane połączenia z bazą

### Klient
W `client/init.lua`:
```lua
EnterGame.setUniqueServer("127.0.0.1", 7171, 1098)
```

## 🛠️ Debugowanie

```bash
# Logi wszystkich serwisów
docker compose logs -f

# Uruchomienie z profilem debug (dodatkowe narzędzia)
docker compose --profile debug up -d

# Logi konkretnego serwisu
docker compose logs -f aac-backend
docker compose logs -f aac-frontend
docker compose logs -f nginx
docker compose logs -f gameserver
docker compose logs -f db

# Restart serwisu
docker compose restart aac-backend

# Połączenie z bazą
docker compose exec db mysql -uroot -ptwoje_haslo ots_baza

# Reset bazy (usunięcie danych)
docker compose down -v
docker compose up -d --build
```

### Profil debug (Docker Compose)

W `docker-compose.yml` dodano dedykowany profil `debug`.

- Serwis debug: `adminer` (`ots_adminer`)
- Dostęp: http://localhost:8081
- Serwer DB w Adminer: `db`

Przykładowy start pełnego środowiska z narzędziami debug:

```bash
docker compose up -d --build
docker compose --profile debug up -d
```

Wyłączenie narzędzi debug bez zatrzymywania głównych usług:

```bash
docker compose --profile debug down
```

### Agent Debug (ulepszony)

Plik agenta: `.github/agents/debug.agent.md`

Agent został rozszerzony o:

- workflow Docker-first (reprodukcja, logi, hipotezy, weryfikacja)
- checklistę dla typowych problemów OTS (login, API, proxy, startup)
- wymagane artefakty końcowe (dowód naprawy + brak regresji)
- ustandaryzowany format raportu końcowego

Ten tryb jest zalecany przy zgłoszeniach typu: `ERROR 2`, `500 API`, `Connection refused`, `Map not found`.

## ⚠️ Częste problemy

| Problem | Rozwiązanie |
|---------|-------------|
| TFS: "Connection refused" | DB się inicjalizuje — poczekaj 30s, potem `docker compose restart gameserver` |
| TFS: "Map not found" | Sprawdź `mapName` w `config.lua` vs pliki w `tfs/data/world/` |
| TFS: "Missing RSA private key PEM header" | Usuń stare kontenery (`docker compose down`) i uruchom ponownie build (`docker compose up -d --build`) — kontener wygeneruje poprawny `key.pem` automatycznie |
| AAC: Biała strona | `docker compose logs aac-frontend` — sprawdź błędy Next.js |
| API: 500 error | `docker compose logs aac-backend` — sprawdź połączenie z DB |
| Klient: "Things not loaded" | Umieść assety `.spr`/`.dat` w `client/data/things/1098/` |
| DB: Brak tabel | `docker compose down -v && docker compose up -d --build` |
