"""Clientless API tests for login and account creation flows.

These tests validate login behavior without OTClient. They target the HTTP API
directly and use seeded DB data plus unique runtime accounts.

Usage:
  API_BASE_URL=http://localhost/api pytest -q test/api/test_clientless_login_flow.py
"""

from __future__ import annotations

import json
import os
import random
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
    """Send a JSON request and return (status_code, parsed_json_body)."""
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
        raw = error.read().decode("utf-8")
        return error.code, json.loads(raw) if raw else {}


@pytest.fixture(scope="session", autouse=True)
def require_live_api() -> None:
    """Skip this suite if the API is not available."""
    try:
        status, body = _request_json("GET", "/health")
    except Exception as exc:  # pragma: no cover
        pytest.skip(f"API is not reachable at {API_BASE_URL}: {exc}")

    if status != 200:
        pytest.skip(f"API healthcheck returned status {status}, body={body}")


def _unique_suffix() -> str:
    return f"{int(time.time() * 1000)}{random.randint(100, 999)}"


def test_login_seeded_admin_account_success() -> None:
    """Seeded db account from sql/02_seed_data.sql should authenticate (1/1)."""
    status, body = _request_json(
        "POST",
        "/account/login",
        {"name": "1", "password": "1"},
    )

    assert status == 200, f"Expected 200 for seeded account login, got {status}: {body}"
    assert body.get("token")
    assert body.get("account", {}).get("name") == "1"


@pytest.mark.parametrize(
    "payload, expected_status",
    [
        ({"name": "1", "password": "wrong-password"}, 401),
        ({"name": "definitely_missing_account", "password": "1"}, 401),
        ({"name": "1"}, 400),
        ({"password": "1"}, 400),
        ({}, 400),
    ],
)
def test_login_failure_cases(payload: dict[str, str], expected_status: int) -> None:
    """Invalid credentials and invalid payloads must return controlled API errors."""
    status, body = _request_json("POST", "/account/login", payload)
    assert status == expected_status, f"Expected {expected_status}, got {status}: {body}"
    assert "error" in body


def test_register_new_account_then_login_and_access_protected_route() -> None:
    """Create account, login, then verify JWT can access protected endpoint."""
    suffix = _unique_suffix()
    credentials = {
        "name": f"apitest{suffix}",
        "password": "testpass123",
        "email": f"apitest{suffix}@example.com",
    }

    register_status, register_body = _request_json("POST", "/account/register", credentials)
    assert register_status == 201, f"Register failed: {register_status}, {register_body}"
    assert register_body.get("accountId")

    login_status, login_body = _request_json(
        "POST",
        "/account/login",
        {"name": credentials["name"], "password": credentials["password"]},
    )
    assert login_status == 200, f"Login failed: {login_status}, {login_body}"

    token = login_body.get("token", "")
    assert token, f"Token missing after successful login: {login_body}"

    characters_status, characters_body = _request_json(
        "GET", "/account/characters", token=token
    )
    assert characters_status == 200, (
        f"Protected route failed: {characters_status}, {characters_body}"
    )
    assert "characters" in characters_body


def test_register_duplicate_name_and_email_conflicts() -> None:
    """Duplicate account name and email should be blocked with 409 conflicts."""
    suffix = _unique_suffix()
    base_name = f"duptest{suffix}"
    base_email = f"duptest{suffix}@example.com"

    first_status, first_body = _request_json(
        "POST",
        "/account/register",
        {"name": base_name, "password": "testpass123", "email": base_email},
    )
    assert first_status == 201, f"Initial register failed: {first_status}, {first_body}"

    same_name_status, same_name_body = _request_json(
        "POST",
        "/account/register",
        {
            "name": base_name,
            "password": "anotherpass",
            "email": f"other-{suffix}@example.com",
        },
    )
    assert same_name_status == 409, (
        f"Expected 409 for duplicate name, got {same_name_status}: {same_name_body}"
    )

    same_email_status, same_email_body = _request_json(
        "POST",
        "/account/register",
        {
            "name": f"other{suffix}",
            "password": "anotherpass",
            "email": base_email,
        },
    )
    assert same_email_status == 409, (
        f"Expected 409 for duplicate email, got {same_email_status}: {same_email_body}"
    )
