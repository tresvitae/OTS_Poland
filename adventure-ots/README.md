# 🛡️ Adventure OTS — Docker Development Environment

Kompletne środowisko deweloperskie do uruchomienia serwera Tibia OTS z użyciem Docker Compose.

## 🏗️ Stack

| Serwis | Kontener | Port | Opis |
|--------|----------|------|------|
| **MariaDB 10.11** | `ots_db` | `3306` | Baza danych |
| **TFS 1.4.2** | `ots_engine` | `7171`, `7172` | Silnik gry |
| **Apache + PHP 8.2** | `myaac_site` | `80` | Strona WWW (MyAAC) |

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
├── www/
│   ├── Dockerfile              # PHP 8.2 + Apache + Composer
│   ├── config.local.php        # Konfiguracja MyAAC (DB, ścieżki)
│   ├── .htaccess               # Reguły Apache
│   └── ...                     # Źródła MyAAC
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
| **Strona WWW** | http://localhost |
| **Serwer gry** | `127.0.0.1:7171` (w kliencie) |
| **Baza danych** | `localhost:3306` |

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

### Strona WWW
Edytuj `www/config.local.php`:
- `database_*` — połączenie z bazą
- `server_path` — ścieżka do TFS w kontenerze

### Klient
W `client/init.lua`:
```lua
EnterGame.setUniqueServer("127.0.0.1", 7171, 1098)
```

## 🛠️ Debugowanie

```bash
# Logi wszystkich serwisów
docker compose logs -f

# Logi konkretnego serwisu
docker compose logs -f gameserver
docker compose logs -f website
docker compose logs -f db

# Restart serwisu
docker compose restart gameserver

# Połączenie z bazą
docker compose exec db mysql -uroot -ptwoje_haslo ots_baza

# Reset bazy (usunięcie danych)
docker compose down -v
docker compose up -d --build
```

## ⚠️ Częste problemy

| Problem | Rozwiązanie |
|---------|-------------|
| TFS: "Connection refused" | DB się inicjalizuje — poczekaj 30s, potem `docker compose restart gameserver` |
| TFS: "Map not found" | Sprawdź `mapName` w `config.lua` vs pliki w `tfs/data/world/` |
| WWW: Biała strona | `docker compose logs website` — sprawdź błędy PHP |
| Klient: "Things not loaded" | Umieść assety `.spr`/`.dat` w `client/data/things/1098/` |
| DB: Brak tabel | `docker compose down -v && docker compose up -d --build` |
