# Login Route Analysis

This document summarizes login-related API routes implemented in the backend and how they are validated in tests.

## Route: `POST /api/account/login`

- Purpose: Authenticate user account by `name` + `password`.
- Input JSON:
  - `name` (required)
  - `password` (required)
- Backend behavior:
  - SHA1 hash is computed from incoming password.
  - Query checks `accounts.name` and `accounts.password`.
- Success response:
  - HTTP `200`
  - JSON contains `message`, `token`, `account.id`, `account.name`
- Error responses:
  - HTTP `400` if missing `name` or `password`
  - HTTP `401` if credentials are invalid
  - HTTP `500` for unexpected server failure

## Route: `POST /api/account/register`

- Purpose: Create account used by login flow and persistence checks.
- Input JSON:
  - `name` (required, 3-32, alphanumeric)
  - `password` (required, min 4)
  - `email` (required)
- Success response:
  - HTTP `201` with `accountId`
- Validation/Conflict responses:
  - HTTP `400` for invalid payload
  - HTTP `409` when account `name` or `email` already exists

## Route: `GET /api/account/characters`

- Purpose: Auth check after login and persistence readback.
- Auth:
  - Requires `Authorization: Bearer <token>`
- Success response:
  - HTTP `200` with `characters` array
- Error responses:
  - HTTP `401` when token is missing/invalid

## Test Coverage Mapping

- Happy path:
  - Existing credentials login (`Patryk` / `test`)
  - Newly registered account login
- Failed login:
  - Invalid password
  - Unknown account name
- Validation:
  - Missing `name` and/or `password`
- Auth checks:
  - Protected endpoint request without token
- Persistence:
  - Register account, then login succeeds
  - Duplicate `name` rejected
  - Duplicate `email` rejected
