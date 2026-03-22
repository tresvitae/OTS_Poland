#!/usr/bin/env bash
# Copilot hook: update root README.md and CHANGELOG.md with the last commit summary.
#
# Project standards:
# - Works from any subdirectory inside the git repo
# - Idempotent (no duplicate entries)
# - Uses English section titles by default
# - Avoids self-trigger loops by skipping hook-generated docs commits

set -euo pipefail

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  exit 0
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

readme_file="README.md"
changelog_file="CHANGELOG.md"
today="$(date +%Y-%m-%d)"
last_subject="$(git log -n 1 --pretty=%s 2>/dev/null || true)"

if [[ -z "$last_subject" ]]; then
  exit 0
fi

# Skip self-generated docs commit to avoid loops.
if [[ "$last_subject" =~ ^docs:\ update\ README/CHANGELOG ]]; then
  exit 0
fi

entry="${today} - ${last_subject}"
entry="${entry:0:140}"

ensure_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    if [[ "$file" == "$changelog_file" ]]; then
      printf "# Changelog\n" > "$file"
    else
      printf "# Project\n" > "$file"
    fi
  fi
}

ensure_section() {
  local file="$1"
  local section="$2"
  if ! grep -qF "$section" "$file"; then
    printf "\n%s\n\n" "$section" >> "$file"
  fi
}

insert_under_section_once() {
  local file="$1"
  local section="$2"
  local line="$3"

  if grep -qF "$line" "$file"; then
    return 1
  fi

  local tmp
  tmp="$(mktemp)"
  awk -v section="$section" -v line="$line" '
    {
      print $0
      if ($0 == section && !inserted) {
        print ""
        print line
        inserted = 1
      }
    }
    END {
      if (!inserted) {
        print ""
        print section
        print ""
        print line
      }
    }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
  return 0
}

ensure_file "$readme_file"
ensure_file "$changelog_file"

readme_section="### Recent changes"
legacy_readme_section="### Ostatnie zmiany"

if grep -qF "$legacy_readme_section" "$readme_file"; then
  readme_section="$legacy_readme_section"
fi

ensure_section "$readme_file" "$readme_section"
ensure_section "$changelog_file" "### $today"

updated=false

if insert_under_section_once "$readme_file" "$readme_section" "- $entry"; then
  echo "Updated README section: $readme_section"
  updated=true
fi

if insert_under_section_once "$changelog_file" "### $today" "- $entry"; then
  echo "Updated CHANGELOG section: ### $today"
  updated=true
fi

if [[ "$updated" == true ]]; then
  if ! git diff --quiet -- "$readme_file" "$changelog_file"; then
    git add "$readme_file" "$changelog_file"
    git commit --no-verify -m "docs: update README/CHANGELOG after latest commit"
  fi
else
  echo "No README/CHANGELOG update needed."
fi

exit 0