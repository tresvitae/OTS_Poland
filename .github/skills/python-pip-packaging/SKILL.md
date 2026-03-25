---
name: python-pip-packaging
description: 'Python dependency and packaging operations for this repository. Use when: creating virtualenvs, installing packages, pinning versions, updating requirements, and troubleshooting import or resolution errors.'
license: MIT
---

# Python Pip Packaging

Use this skill for Python environment reliability and reproducible dependencies.

## When to Use

- `requirements.txt` updates
- Virtual environment setup or repair
- Package install/upgrade/downgrade tasks
- Dependency conflict resolution
- Missing module troubleshooting

## Workflow

1. Activate or create a project virtual environment.
2. Install/update packages with explicit versions.
3. Validate imports and command entrypoints.
4. Persist pinned dependencies to requirements.

## Guardrails

- Prefer pinned versions for reproducibility.
- Do not mix global and virtualenv package installs.
- Validate the active interpreter before pip operations.
- Keep dependency changes minimal and documented.

## Output Contract

1. Environment details
2. Packages changed
3. Verification commands
4. Follow-up notes
