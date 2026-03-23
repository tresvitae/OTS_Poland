# Copilot Hooks

This folder contains GitHub Copilot Chat hook configuration and scripts used to automate documentation updates after tool usage.

## What is a hook?

A hook is an automatic command that runs at a specific Copilot lifecycle event.

In this project, `postToolUse` hooks run after Copilot uses a tool. They are configured in `.github/hooks/hooks.json` and execute Bash scripts in `.github/hooks/scripts/`.

Current behavior:
- `update-readme-changelog.bash`: updates root `README.md` and `CHANGELOG.md` with the latest commit summary.
- `update-tibia-client-readme-changelog.bash`: adds a `[Client]` entry only when the latest relevant commit touched `adventure-ots/client/**`.

Both scripts are idempotent (no duplicate entries) and skip when there is nothing to update.

## How to use hooks

1. Keep the config file at `.github/hooks/hooks.json`.
2. Ensure scripts are executable in your environment (Git Bash/WSL/bash).
3. Configure Git identity (required for automatic docs commits):

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

4. Use Copilot Chat tools as normal. After each tool run, Copilot executes the `postToolUse` hook commands.

If docs changed, the scripts can create an automatic docs commit.

## Manual test

Run from repo root:

```bash
bash .github/hooks/scripts/update-readme-changelog.bash
bash .github/hooks/scripts/update-tibia-client-readme-changelog.bash
```

Check results:

```bash
git --no-pager log --oneline -n 5
git --no-pager diff -- README.md CHANGELOG.md
```

## Troubleshooting

### "empty ident name" or missing author error

Cause: Git identity is not configured.

Fix:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

The scripts now detect missing identity and skip commit with a clear message instead of failing.

### No update created

Expected in these cases:
- Latest relevant commit is a docs auto-commit.
- No new line needs to be inserted (already present).
- Latest relevant commit did not touch `adventure-ots/client/**` (for client hook).

### Bash not found on Windows

Use Git Bash or WSL, and make sure the hook command paths resolve from repository root.
