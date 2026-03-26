# Suggested API Tests (Adventure OTS)

This list extends current coverage for backend API validation without OTClient.

## Authentication and Session

- Login throttling behavior (if rate limit is enabled): repeated invalid attempts should eventually return the expected throttling status.
- JWT invalid token formats: malformed token, expired token, and token signed with wrong secret should return `401`.
- Password change flow: login with old password succeeds before change, fails after change, and new password login succeeds.

## Account Registration

- Boundary validation for account name length: exactly 3 and 32 chars accepted; 2 and 33 rejected.
- Password minimum length boundary: exactly 4 accepted; 3 rejected.
- Account name character policy: only alphanumeric allowed, symbols and spaces rejected.

## Character Management

- Character create validation: invalid vocation (`0`, `5`, string) and invalid sex payload values.
- Character name validation boundaries: short names, long names, consecutive spaces, and symbols.
- Character uniqueness: creating same character name twice should return conflict.

## Data Contract and Stability

- Response schema checks: verify required keys for each endpoint (`error`, `message`, `token`, `account`, `characters`).
- Content type checks: API returns JSON content type for both success and failure responses.
- Non-regression smoke set: `/health`, `/online`, `/account/login`, `/account/register`, `/account/characters`.

## Persistence and Integration

- Register -> login -> create character -> list character persistence chain in one parameterized test.
- Seed data contract checks: seeded account (`1`/`1`) login and seeded admin character visibility (if tied to token account).
- Concurrent registration collision: two near-simultaneous requests with same account name should create one account and reject the second.
