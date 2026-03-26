# API Tests (AAC Backend)

This folder contains integration tests for Adventure OTS AAC API.

The tests validate:
- public API availability (`/api/health`, `/api/online`)
- account registration and login
- login route success/failure cases with parameterized credentials
- clientless login flow using seeded DB account (`1` / `1`) and failed auth variants
- character creation flow
- persistence check through list endpoint (`/api/account/characters`)
- request validation errors
- account persistence constraints (`name` and `email` duplicates)

Login route analysis is documented in:

- `test/api/login_routes_analysis.md`

Additional test ideas are documented in:

- `test/api/api_test_suggestions.md`

## Prerequisites

1. Run the project stack:

```bash
cd adventure-ots
docker compose up -d --build
```

2. Ensure API is reachable:

```bash
curl http://localhost/api/health
```

## How to run tests

From repository root:

```bash
python -m pip install pytest
API_BASE_URL=http://localhost/api pytest -q test/api/test_aac_api.py
API_BASE_URL=http://localhost/api pytest -q test/api/test_login_routes.py
API_BASE_URL=http://localhost/api pytest -q test/api/test_clientless_login_flow.py
```

Alternative (direct backend port, without nginx):

```bash
API_BASE_URL=http://localhost:3001/api pytest -q test/api/test_aac_api.py
API_BASE_URL=http://localhost:3001/api pytest -q test/api/test_login_routes.py
API_BASE_URL=http://localhost:3001/api pytest -q test/api/test_clientless_login_flow.py
```

## Parameters

The test module is parameterized with `pytest.mark.parametrize` for:
- endpoint smoke checks
- register validation cases
- character creation variants (`vocation`, `sex`)

Runtime parameters via environment variables:
- `API_BASE_URL` (default: `http://localhost/api`)
- `API_TEST_TIMEOUT` in seconds (default: `8`)

Example:

```bash
API_BASE_URL=http://localhost/api API_TEST_TIMEOUT=12 pytest -q test/api/test_aac_api.py
API_BASE_URL=http://localhost/api API_TEST_TIMEOUT=12 pytest -q test/api/test_login_routes.py
API_BASE_URL=http://localhost/api API_TEST_TIMEOUT=12 pytest -q test/api/test_clientless_login_flow.py
```

## Notes

- Tests create temporary accounts using unique names per test run.
- If API is unavailable, the suite is skipped with a clear message.
- The persistence assertion is API-level: it verifies created data can be read back from backend endpoints that use MariaDB.
