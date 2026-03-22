#!/bin/bash
# 
# Copilot hook: po toolUse (np. git commit/push) sprawdza, czy zmiana dotyczy
# Tibia Clienta (katalogi modules/, data/, layouts/, themes/, src/otclient) 
# i aktualizuje README.md oraz CHANGELOG.md tylko dla client‑changes.
# 
# Format: 
#  - README.md: sekcja "### Zmiany klienta"
#  - CHANGELOG.md: wpisy z tagiem [Client]

set -euo pipefail

# 1. Jeśli nie jesteśmy w repo z git — wyjdź szybko
if ! git rev-parse --git-dir &>/dev/null; then
  exit 0
fi

# 2. Pobierz ostatni komit
last_commit=$(git log --format="%cd - %s" --date=short -n 1 | head -n 1) || exit 0
last_commit_short=$(echo "$last_commit" | cut -d ' ' -f 4- | head -c 80)

# 3. Sprawdź, czy zmiana dotyczy Tibia Clienta (katalogi typowe dla clienta)
client_dirs_re="^(modules/|data/|layouts/|themes/|src/otclient/|src/protocol/|src/input/)$"

# Sprawdź pliki z ostatniego komita
changed_paths=$(git diff-tree --no-commit-id --name-only -r HEAD -- 2>/dev/null || true)

is_client_change=false
while IFS= read -r file; do
  dirname=$(dirname "$file")/
  if [[ "$dirname" =~ $client_dirs_re ]]; then
    is_client_change=true
    break
  fi
done <<< "$changed_paths"

# 4. Jeśli nie jest to zmiana w kliencie — nie aktualizuj README/CHANGELOG
if [ "$is_client_change" != true ]; then
  echo "ⓘ Komit nie dotyczy Tibia Clienta – pomijam aktualizację README/CHANGELOG"
  exit 0
fi

echo "🐷 Zmiana dotyczy Tibia Clienta: $last_commit_short"

# 5. Aktualizuj README.md (sekcja Tibia Client)
UPDATE_README=false

if grep -q "^### Zmiany klienta" README.md; then
  if grep -qF "$last_commit_short" README.md; then
    echo "ⓘ README.md: ta zmiana klienta jest już wypisana"
  else
    echo "🔄 README.md: dodaję zmianę klienta do sekcji 'Zmiany klienta'"
    UPDATE_README=true
  fi
else
  echo "🔧 README.md: dodaję sekcję 'Zmiany klienta'"
  printf '\n### Zmiany klienta\n\n- %s\n' "$last_commit_short" >> README.md
  UPDATE_README=true
fi

if [ "$UPDATE_README" = true ]; then
  # Zaktualizuj sekcję bez duplikatów
  tmp=$(mktemp)
  sed '/^### Zmiany klienta$/q' README.md > "$tmp"
  echo "### Zmiany klienta" >> "$tmp"
  echo "" >> "$tmp"
  echo "- $last_commit_short" >> "$tmp"
  tail -n +$(($(grep -n "^### Zmiany klienta" README.md | cut -d ':' -f 1) + 1)) README.md | \
    grep -v "$last_commit_short" | head -n 100 >> "$tmp"
  cp "$tmp" README.md
  rm "$tmp"
fi

# 6. Aktualizuj CHANGELOG.md (wpisy z tagiem [Client])
# Format: ### 2025‑03‑22
#   - [Client] nowy blur w UI
UPDATE_CHANGELOG=false

if grep -q "^### 20" CHANGELOG.md; then
  last_changelog_date_line=$(grep -n "^### 20" CHANGELOG.md | tail -n 1 | cut -d ':' -f 1)
  last_changelog_line=$(wc -l < CHANGELOG.md)

  if [ "$last_changelog_date_line" -eq "$last_changelog_line" ]; then
    echo "🔄 CHANGELOG.md: dodaję wpis z tagiem [Client] do sekcji z dzisiejszą datą"
    echo "- [Client] $last_commit_short" >> CHANGELOG.md
    UPDATE_CHANGELOG=true
  else
    if grep -A 50 "^###.*$(date +%Y-%m-%d)" CHANGELOG.md | grep -qF "[Client] $last_commit_short"; then
      echo "ⓘ CHANGELOG.md: ten wpis [Client] jest już w CHANGELOG"
    else
      echo "🔄 CHANGELOG.md: dodaję wpis z tagiem [Client] do najnowszej sekcji z dzisiejszą datą"
      sed -i.bak "s|^###.*$(date +%Y-%m-%d)|### $(date +%Y-%m-%d)\n- [Client] $last_commit_short|" CHANGELOG.md
      UPDATE_CHANGELOG=true
    fi
  fi
else
  echo "🔧 CHANGELOG.md: dodaję sekcję z dzisiejszą datą i wpis klienta"
  echo "### $(date +%Y-%m-%d)" >> CHANGELOG.md
  echo "- [Client] $last_commit_short" >> CHANGELOG.md
  UPDATE_CHANGELOG=true
fi

# 7. Zacommituj aktualizacje README/CHANGELOG (bez kolejnego hooka)
if [ "$UPDATE_README" = true ] || [ "$UPDATE_CHANGELOG" = true ]; then
  echo "🌀 Zapisuję zmiany README/CHANGELOG z a komitem (bez weryfikacji)"

  if git diff --exit-code README.md CHANGELOG.md > /dev/null; then
    echo "ⓘ Zmiany README/CHANGELOG są identyczne z HEAD"
  else
    git add README.md CHANGELOG.md
    git commit --no-verify -m "docs: aktualizacja README/CHANGELOG dla Tibia Clienta"
  fi
else
  echo "ⓘ README.md i CHANGELOG.md dla klienta nie wymagają aktualizacji"
fi

exit 0