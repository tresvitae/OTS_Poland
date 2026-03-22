#!/bin/bash
# 
# Copilot hook: po każdym toolUse (np. git commit / push)
# automatycznie aktualizuje:
# - README.md (ostatnie zmiany)
# - CHANGELOG.md (nowa sekcja z ostatnim komitem)

set -euo pipefail

# Odczytaj JSON wejścia (opcjonalne, jeśli potrzebujesz debugu)
# INPUT=$(cat)
# TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName // ""')

# 1. Zakończ szybko jeśli nie jesteśmy w repo z git
if ! git rev-parse --git-dir &>/dev/null; then
  exit 0
fi

# 2. Znajdź ostatni komit (format: "2025‑03‑22 - commit message" GMT)
last_commit=$(git log --format="%cd - %s" --date=short -n 1 | head -n 1) || exit 0
last_commit_short=$(echo "$last_commit" | cut -d ' ' -f 4- | head -c 80)

# 3. Aktualizuj README.md (ostatnie zmiany)
# Szukaj sekcji: "### Ostatnie zmiany" i dodaj na górę listy
UPDATE_README=false

if grep -q "^### Ostatnie zmiany" README.md; then
  # Sprawdź, czy ten sam komit jest już wpisany
  if grep -qF "$last_commit_short" README.md; then
    echo "ⓘ README.md: ta zmiana jest już wypisana, pomijam"
  else
    echo "🔄 README.md: dodaję nową zmianę do sekcji 'Ostatnie zmiany'"
    UPDATE_README=true
  fi
else
  echo "🔍 README.md: brak sekcji 'Ostatnie zmiany', dodaję sekcję"
  printf '\n### Ostatnie zmiany\n\n- %s\n' "$last_commit_short" >> README.md
  UPDATE_README=true
fi

if [ "$UPDATE_README" = true ]; then
  # Zastąp/Nadal sekcję (zabezpieczenie przed duplikatami w przyszłości)
  tmp=$(mktemp)
  sed '/^### Ostatnie zmiany$/q' README.md > "$tmp"
  echo "### Ostatnie zmiany" >> "$tmp"
  echo "" >> "$tmp"
  echo "- $last_commit_short" >> "$tmp"
  tail -n +$(($(grep -n "^### Ostatnie zmiany" README.md | cut -d ':' -f 1) + 1)) README.md | \
    grep -v "$last_commit_short" | head -n 100 >> "$tmp"
  cp "$tmp" README.md
  rm "$tmp"
fi

# 4. Aktualizuj CHANGELOG.md (sekcja z datą)
# Format: -
#   - 2025‑03‑22 - msg
#   - 2025‑03‑22 - msg
UPDATE_CHANGELOG=false

if grep -q "^### 20" CHANGELOG.md; then
  # Znajdź najnowszą sekcję zaczynającą się od "### 20"
  last_changelog_date_line=$(grep -n "^### 20" CHANGELOG.md | tail -n 1 | cut -d ':' -f 1)
  last_changelog_line=$(wc -l < CHANGELOG.md)
  if [ "$last_changelog_date_line" -eq "$last_changelog_line" ]; then
    # Najnowsza sekcja ma na końcu "### 2025‑03‑22"
    echo "ⓘ CHANGELOG.md: sekcja z dzisiejszą datą jest pusta, dopisuję"
    echo "- $last_commit_short" >> CHANGELOG.md
    UPDATE_CHANGELOG=true
  else
    # Dodaj wpis tylko jeśli nie ma go już w tej sekcji
    if grep -A 50 "^###.*$(date +%Y-%m-%d)" CHANGELOG.md | grep -qF "$last_commit_short"; then
      echo "ⓘ CHANGELOG.md: ta zmiana jest już w CHANGELOG"
    else
      echo "🔄 CHANGELOG.md: dodaję wpis do najnowszej sekcji z dzisiejszą datą"
      sed -i.bak "s|^###.*$(date +%Y-%m-%d)|### $(date +%Y-%m-%d)\n- $last_commit_short|" CHANGELOG.md
      UPDATE_CHANGELOG=true
    fi
  fi
else
  echo "🔧 CHANGELOG.md: dodaję sekcję z dzisiejszą datą"
  echo "### $(date +%Y-%m-%d)" >> CHANGELOG.md
  echo "- $last_commit_short" >> CHANGELOG.md
  UPDATE_CHANGELOG=true
fi

# 5. Jeśli coś zmieniło się w README.md / CHANGELOG.md, zacommituj osobno
# (bez kolejnego wywołania hooka przez --no-verify)
if [ "$UPDATE_README" = true ] || [ "$UPDATE_CHANGELOG" = true ]; then
  echo "🌀 Dodaję zmiany README/CHANGELOG z a komitem (bez weryfikacji)"

  # Zabezpieczenie przed pętlą w hookach
  if git diff --exit-code README.md CHANGELOG.md > /dev/null; then
    echo "ⓘ README/CHANGELOG nie zmieniły się naprawdę"
  else
    git add README.md CHANGELOG.md
    git commit --no-verify -m "docs: aktualizacja README/CHANGELOG po ostatnim change"
  fi
else
  echo "ⓘ README.md i CHANGELOG.md nie wymagają aktualizacji"
fi

exit 0