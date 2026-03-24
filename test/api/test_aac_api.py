"""Integration tests for Adventure OTS AAC API.

These tests target a running local stack and validate the core flow:
- account registration
- login and JWT issuance
- character creation
- character listing (persistence verification)

Usage examples:
  API_BASE_URL=http://localhost/api pytest -q test/api/test_aac_api.py
  API_BASE_URL=http://localhost:3001/api pytest -q test/api/test_aac_api.py
"""

from __future__ import annotations

import json
import os
import random
import string
import time
import urllib.error
import urllib.request
from typing import Any

import pytest


API_BASE_URL = os.getenv("API_BASE_URL", "http://localhost/api").rstrip("/")
REQUEST_TIMEOUT_SECONDS = float(os.getenv("API_TEST_TIMEOUT", "8"))


def _request_json(
    method: str,
    path: str,
    payload: dict[str, Any] | None = None,
    token: str | None = None,
) -> tuple[int, dict[str, Any]]:
    """Send JSON request and return (status_code, parsed_json_body)."""
    url = f"{API_BASE_URL}{path}"
    body = None
    headers = {"Content-Type": "application/json"}

    if token:
        headers["Authorization"] = f"Bearer {token}"

    if payload is not None:
        body = json.dumps(payload).encode("utf-8")

    request = urllib.request.Request(url, data=body, method=method.upper(), headers=headers)

    try:
        with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT_SECONDS) as response:
            raw = response.read().decode("utf-8")
            return response.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        # API error responses are still JSON; return them for assertions.
        raw = error.read().decode("utf-8")
        return error.code, json.loads(raw) if raw else {}


@pytest.fixture(scope="session", autouse=True)
def require_live_api() -> None:
    """Skip the suite when API is not reachable, instead of hard failing every test."""
    try:
        status, body = _request_json("GET", "/health")
    except Exception as exc:  # pragma: no cover - defensive for connection-level failures.
        pytest.skip(f"API is not reachable at {API_BASE_URL}: {exc}")

    if status != 200:
        pytest.skip(f"API healthcheck returned status {status}, body={body}")


@pytest.fixture
def account_credentials() -> dict[str, str]:
    """Generate unique account credentials for every test function."""
    suffix = f"{int(time.time() * 1000)}{random.randint(100, 999)}"
    return {
        "name": f"apitest{suffix}",
        "password": "testpass123",
        "email": f"apitest{suffix}@example.com",
    }


def _register_and_login(credentials: dict[str, str]) -> tuple[int, dict[str, Any], str]:
    """Create account and log in; returns register_status, login_body, token."""
    register_status, _ = _request_json("POST", "/account/register", credentials)

    login_status, login_body = _request_json(
        "POST",
        "/account/login",
        {"name": credentials["name"], "password": credentials["password"]},
    )

    assert login_status == 200, f"Expected successful login, got {login_status}: {login_body}"
    token = login_body.get("token", "")
    assert token, f"JWT token missing in login response: {login_body}"
    return register_status, login_body, token


def _character_name() -> str:
    """Return valid character name format accepted by backend regex (letters/spaces only)."""
    first = "Test" + "".join(random.choice(string.ascii_lowercase) for _ in range(4)).capitalize()
    last = "Hero" + "".join(random.choice(string.ascii_lowercase) for _ in range(4)).capitalize()
    return f"{first} {last}"


@pytest.mark.parametrize(
    "endpoint, required_keys",
    [
        ("/health", {"status", "service", "timestamp"}),
        ("/online", {"online", "count"}),
    ],
)
def test_public_endpoints(endpoint: str, required_keys: set[str]) -> None:
    """Parameterized smoke test for public endpoints available without JWT."""
    status, body = _request_json("GET", endpoint)
    assert status == 200, f"Unexpected status for {endpoint}: {status}, body={body}"
    assert required_keys.issubset(body.keys())


@pytest.mark.parametrize(
    "payload, expected_status",
    [
        ({"name": "ab", "password": "1234", "email": "x@example.com"}, 400),
        ({"name": "inv@lid", "password": "1234", "email": "x@example.com"}, 400),
        ({"name": "validname", "password": "123", "email": "x@example.com"}, 400),
    ],
)
def test_register_validation_errors(payload: dict[str, str], expected_status: int) -> None:
    """Parameterized validation checks for account registration constraints."""
    status, body = _request_json("POST", "/account/register", payload)
    assert status == expected_status, f"Expected {expected_status}, got {status}: {body}"
    assert "error" in body


def test_register_and_login_persists_account(account_credentials: dict[str, str]) -> None:
    """Ensure account can be created and immediately authenticated."""
    register_status, login_body, token = _register_and_login(account_credentials)

    # The account is unique, so first creation should return HTTP 201.
    assert register_status == 201
    assert login_body["account"]["name"] == account_credentials["name"]
    assert token


@pytest.mark.parametrize("vocation, sex", [(1, 0), (4, 1)])
def test_create_character_and_list_shows_persisted_data(
    account_credentials: dict[str, str],
    vocation: int,
    sex: int,
) -> None:
    """Create character, then read character list to verify DB-backed persistence via API."""
    _, _, token = _register_and_login(account_credentials)
    character_name = _character_name()

    create_status, create_body = _request_json(
        "POST",
        "/character/create",
        {
            "name": character_name,
            "vocation": vocation,
            "sex": sex,
        },
        token=token,
    )

    assert create_status == 201, f"Character creation failed: {create_status}, {create_body}"

    list_status, list_body = _request_json("GET", "/account/characters", token=token)
    assert list_status == 200, f"Characters list failed: {list_status}, {list_body}"

    names = [row["name"] for row in list_body.get("characters", [])]
    assert character_name in names, "Created character was not returned by /account/characters"
