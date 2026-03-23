#!/usr/bin/env bash
# Copilot hook: update docs only when today's commits include Tibia client files.
#
# Client area for this repo:
# - adventure-ots/client/**

set -euo pipefail

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  exit 0
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

readme_file="README.md"
changelog_file="CHANGELOG.md"
today="$(date +%Y-%m-%d)"
docs_commit_pattern='^docs: update README/CHANGELOG'

build_summary_from_today_client_commits() {
  local max_items=6
  local -a subjects=()

  while IFS= read -r subject; do
    [[ -z "$subject" ]] && continue
    subjects+=("$subject")
  done < <(git --no-pager log --since="${today} 00:00:00" --until="${today} 23:59:59" --pretty=%s --invert-grep --grep="$docs_commit_pattern" -- adventure-ots/client 2>/dev/null || true)

  local count="${#subjects[@]}"
  if (( count == 0 )); then
    echo ""
    return
  fi

  local summary=""
  local idx=0
  while (( idx < count && idx < max_items )); do
    if [[ -n "$summary" ]]; then
      summary+="; "
    fi
    summary+="${subjects[$idx]}"
    ((idx += 1))
  done

  if (( count > max_items )); then
    summary+="; +$((count - max_items)) more"
  fi

  echo "$summary"
}

summary="$(build_summary_from_today_client_commits)"
if [[ -z "$summary" ]]; then
  echo "No Tibia client changes found for today - skipping docs update."
  exit 0
fi

entry="${today} - ${summary}"
entry="${entry:0:320}"

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

remove_section_lines_by_prefix() {
  local file="$1"
  local section="$2"
  local prefix="$3"

  local tmp
  tmp="$(mktemp)"
  awk -v section="$section" -v prefix="$prefix" '
    {
      if ($0 == section) {
        print $0
        in_section = 1
        next
      }

      if (in_section && $0 ~ /^### /) {
        in_section = 0
      }

      if (in_section && index($0, prefix) == 1) {
        next
      }

      print $0
    }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

upsert_under_section_by_prefix() {
  local file="$1"
  local section="$2"
  local prefix="$3"
  local line="$4"

  if grep -qF "$line" "$file"; then
    return 1
  fi

  remove_section_lines_by_prefix "$file" "$section" "$prefix"
  insert_under_section_once "$file" "$section" "$line"
  return 0
}

ensure_file "$readme_file"
ensure_file "$changelog_file"

readme_section="### Client changes"
legacy_readme_section="### Zmiany klienta"
if grep -qF "$legacy_readme_section" "$readme_file"; then
  readme_section="$legacy_readme_section"
fi

ensure_section "$readme_file" "$readme_section"
ensure_section "$changelog_file" "### $today"

updated=false

if upsert_under_section_by_prefix "$readme_file" "$readme_section" "- [Client] ${today} - " "- [Client] $entry"; then
  echo "Updated README section: $readme_section"
  updated=true
fi

if upsert_under_section_by_prefix "$changelog_file" "### $today" "- [Client] ${today} - " "- [Client] $entry"; then
  echo "Updated CHANGELOG section: ### $today"
  updated=true
fi

if [[ "$updated" == true ]]; then
  if ! git diff --quiet -- "$readme_file" "$changelog_file"; then
    git_user_name="$(git config --get user.name 2>/dev/null || true)"
    git_user_email="$(git config --get user.email 2>/dev/null || true)"
    if [[ -z "$git_user_name" || -z "$git_user_email" ]]; then
      echo "Skipping docs commit: git user.name/user.email are not configured."
      echo "Set them with: git config --global user.name 'Your Name' && git config --global user.email 'you@example.com'"
      exit 0
    fi

    git add "$readme_file" "$changelog_file"
    git commit --no-verify -m "docs: update README/CHANGELOG for Tibia client"
  fi
else
  echo "No client README/CHANGELOG update needed."
fi

exit 0