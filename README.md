# Adventure OTS
# OTS_Poland


# 🛡️ Tibia OTS Project - MVP (Protocol 10.98)

System zarządzania i wdrażania serwera Tibia Open Source (OTS) oparty na architekturze kontenerowej **Docker**.

## 🏗️ Architektura Systemu (Stack)

* **Game Engine:** The Forgotten Server (TFS) 1.4.2
* **Database:** MariaDB 10.11 (LTS)
* **Backend API:** Node.js + TypeScript + Express (Headless AAC)
* **Frontend SPA:** Next.js 14 + Tailwind CSS (Dark Fantasy RPG)
* **Reverse Proxy:** Nginx
* **Orchestration:** Docker Compose

---

## 📂 Struktura Projektu

```text
.
├── adventure-ots/
│   ├── docker-compose.yml     # Główny plik orkiestracji
│   ├── sql/                   # Seed data (konto admina)
│   ├── tfs/                   # Silnik (src, data, config.lua, schema.sql)
│   ├── aac-backend/           # REST API (Node.js + TypeScript)
│   ├── aac-frontend/          # Strona SPA (Next.js + Tailwind CSS)
│   ├── nginx/                 # Reverse Proxy
│   └── client/                # Skonfigurowany OTClient Mehah
├── src/                       # Skrypty projektu
├── docs/                      # Dokumentacja
└── deploy/                    # Konfiguracja wdrożeniowa

```

---

## 🚀 Szybki Start (First Run)

### 1. Przygotowanie środowiska

Upewnij się, że masz zainstalowane:

* Docker Desktop (Windows/Mac) lub Docker Engine (Linux).
* Minimum 4GB RAM przydzielone dla Dockera.

### 2. Uruchomienie

Otwórz terminal w folderze `adventure-ots` i wykonaj:

```bash
docker compose up -d --build

```

*Uwaga: Pierwsze uruchomienie potrwa od 5 do 15 minut (kompilacja silnika C++).*

### 3. Dostęp

| Usługa | URL / Adres |
| --- | --- |
| **Strona WWW (AAC)** | http://localhost |
| **API Health Check** | http://localhost/api/health |
| **Serwer gry** | `127.0.0.1:7171` (w kliencie) |

---

## 🤖 Instrukcje dla Agentów LangChain

Jeśli używasz agentów AI do rozwoju projektu, przekaż im te wytyczne:

1. **Context:** Ten projekt to system mikroserwisów w kontenerach Docker. Zmiany w skryptach Lua → `/tfs/data`. Zmiany API → `/aac-backend/src`. Zmiany UI → `/aac-frontend/src`.
2. **Database:** Zmiany w strukturze bazy muszą być odzwierciedlone w `tfs/schema.sql`. Backend korzysta bezpośrednio z tabel TFS.
3. **Connectivity:** Wszystkie serwisy komunikują się przez wewnętrzną sieć Dockera (hostname: `db`).
4. **Auth:** Backend używa JWT, hasła w SHA1 (kompatybilne z TFS 1.4.2).

---

## 🛠️ Debugowanie i Logi

Jeśli coś nie działa, sprawdź logi konkretnego serwisu:

| Problem | Komenda sprawdzająca |
| --- | --- |
| **Silnik nie startuje** | `docker logs ots_engine` |
| **Błędy API** | `docker logs aac_api` |
| **Błędy strony WWW** | `docker logs aac_web` |
| **Problemy z proxy** | `docker logs aac_proxy` |
| **Problemy z bazą** | `docker logs ots_db` |

### Częste błędy:

* **"Connection refused" (TFS):** Baza danych jeszcze się inicjalizuje. Poczekaj 30 sekund i zrestartuj silnik: `docker compose restart gameserver`.
* **"Map not found":** Sprawdź czy nazwa pliku w `tfs/data/world/` jest identyczna z `mapName` w `config.lua`.
* **Brak tabel w bazie:** Upewnij się, że `schema.sql` jest zamontowany podczas pierwszego startu.

---

## ✅ Aktualny Status Uruchomienia

* **Strona WWW (AAC)** działa poprawnie pod adresem `http://localhost`.
* **Rejestracja:** Tworzenie nowych użytkowników oraz zapis do bazy danych funkcjonuje prawidłowo.
* **Uwaga:** Funkcjonalności są w pełni dostępne po ponownym uruchomieniu / restarcie kontenerów.

---

## 📝 Lista zadań do wykonania (Roadmap)

* [x] Wdrożenie systemu AAC (Backend + Frontend + Nginx)
* [ ] Import gotowej mapy do `tfs/data/world/`.
* [ ] Zmiana JWT_SECRET na bezpieczny losowy ciąg w produkcji.
* [ ] Wyłączenie modułu Marketu w OTClient.
* [ ] Testowe logowanie postacią `1/1` lub stworzoną przez WWW.
### Recent changes

- 2026-03-23 - Improve hooks; Add logs for debugging.; Corrected login field semantics.; add debug networking ots prompt; Improve agent; Add loging level of info.; +10 more



### Client changes

- [Client] 2026-03-23 - Add logs for debugging.; Corrected login field semantics.; changed default option and configuration setup to server.; Improve debugging logs level for client.; Improve Agent and client to run (resolved).; Fix problem with scirps no logs; +3 more

