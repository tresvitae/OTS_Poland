# Adventure OTS
# OTS_Poland


# 🛡️ Tibia OTS Project - MVP (Protocol 10.98)

System zarządzania i wdrażania serwera Tibia Open Source (OTS) oparty na architekturze kontenerowej **Docker**.

## 🏗️ Architektura Systemu (Stack)

* **Game Engine:** The Forgotten Server (TFS) 1.4.2
* **Database:** MariaDB 10.11 (LTS)
* **Web Interface:** MyAAC (PHP 8.2 + Apache)
* **Orchestration:** Docker Compose

---

## 📂 Struktura Projektu

```text
.
├── docker-compose.yml     # Główny plik orkiestracji
├── schema.sql             # Schemat bazy danych (inicjalizacja)
├── /tfs                   # Silnik (src, data, config.lua)
├── /www                   # Strona WWW (MyAAC)
└── /client                # Skonfigurowany OTClient Mehah

```

---

## 🚀 Szybki Start (First Run)

### 1. Przygotowanie środowiska

Upewnij się, że masz zainstalowane:

* Docker Desktop (Windows/Mac) lub Docker Engine (Linux).
* Minimum 4GB RAM przydzielone dla Dockera.

### 2. Konfiguracja połączeń

Przed uruchomieniem sprawdź, czy pliki konfiguracyjne wskazują na serwis bazy danych o nazwie **`db`**:

* **tfs/config.lua:** `mysqlHost = "db"`
* **www/config.local.php:** `$config['database_host'] = 'db';`

### 3. Uruchomienie

Otwórz terminal w głównym folderze i wykonaj:

```bash
docker-compose up -d --build

```

*Uwaga: Pierwsze uruchomienie potrwa od 5 do 15 minut (kompilacja silnika C++).*

---

## 🤖 Instrukcje dla Agentów LangChain

Jeśli używasz agentów AI do rozwoju projektu, przekaż im te wytyczne:

1. **Context:** Ten projekt to monolit rozproszony na kontenery. Wszystkie zmiany w skryptach Lua wprowadzaj w katalogu `/tfs/data`.
2. **Database:** Zmiany w strukturze bazy muszą być odzwierciedlone w `schema.sql`.
3. **Connectivity:** Silnik gry i strona WWW komunikują się z bazą przez wewnętrzną sieć Dockera (hostname: `db`).

---

## 🛠️ Debugowanie i Logi

Jeśli coś nie działa, sprawdź logi konkretnego serwisu:

| Problem | Komenda sprawdzająca |
| --- | --- |
| **Silnik nie startuje** | `docker logs ots_engine` |
| **Błędy strony WWW** | `docker logs myaac_site` |
| **Problemy z bazą** | `docker logs ots_db` |

### Częste błędy:

* **"Connection refused" (TFS):** Baza danych jeszcze się inicjalizuje. Poczekaj 30 sekund i zrestartuj silnik: `docker-compose restart tfs`.
* **"Map not found":** Sprawdź czy nazwa pliku w `tfs/data/world/` jest identyczna z `mapName` w `config.lua`.
* **Brak tabel w bazie:** Upewnij się, że `schema.sql` znajduje się w głównym folderze podczas pierwszego startu.

---

## 📝 Lista zadań do wykonania (Roadmap)

* [ ] Import gotowej mapy do `tfs/data/world/`.
* [ ] Konfiguracja Town ID w `config.local.php`.
* [ ] Wyłączenie modułu Marketu w OTClient.
* [ ] Testowe logowanie postacią `1/1` lub stworzoną przez WWW.