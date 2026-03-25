# Frontend Login Flow Tests (Non-E2E)

This folder contains frontend-facing login flow checks without browser E2E automation.

The tests call API routes through frontend/proxy path (`/api/*`) and validate:

- successful login flow (`Patryk` / `test`)
- invalid credentials handling
- missing fields validation
- auth checks for protected routes
- persistence behavior for account registration + login

## Prerequisites

1. Start stack:

```bash
cd adventure-ots
docker compose up -d --build
```

2. Confirm proxy health:

```bash
curl http://localhost/api/health
```

## Run tests

From repository root:

```bash
python -m pip install pytest
FRONTEND_BASE_URL=http://localhost pytest -q test/frontend/test_frontend_login_flow.py
```

Environment parameters:

- `FRONTEND_BASE_URL` (default: `http://localhost`)
- `API_TEST_TIMEOUT` in seconds (default: `8`)

## Manual test form

For quick manual verification, open:

- `test/frontend/login_form_test.html`

This form supports register/login/authorized characters fetch against the configured API base URL.
