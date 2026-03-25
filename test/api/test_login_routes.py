"""Login-focused API integration tests for Adventure OTS backend.

Covers successful and failed login process, field validation, auth checks,
and persistence-related behavior (name/email/password via register+login).

Usage:
  API_BASE_URL=http://localhost/api pytest -q test/api/test_login_routes.py
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


def _unique_suffix() -> str:
    return f"{int(time.time() * 1000)}{random.randint(100, 999)}"


@pytest.fixture(scope="session", autouse=True)
def require_live_api() -> None:
    try:
        status, body = _request_json("GET", "/health")
    except Exception as exc:
        pytest.skip(f"API is not reachable at {API_BASE_URL}: {exc}")

    if status != 200:
        pytest.skip(f"API healthcheck returned status {status}, body={body}")


def _ensure_patryk_test_account() -> None:
    status, _ = _request_json(
        "POST",
        "/account/login",
        {"name": "Patryk", "password": "test"},
    )

    if status == 200:
        return

    register_status, _ = _request_json(
        "POST",
        "/account/register",
        {
            "name": "Patryk",
            "password": "test",
            "email": "patryk.test@adventure.ots",
        },
    )

    if register_status not in {201, 409}:
        pytest.fail(f"Could not ensure Patryk/test account, register status={register_status}")

    login_status, login_body = _request_json(
        "POST",
        "/account/login",
        {"name": "Patryk", "password": "test"},
    )
    assert login_status == 200, (
        "Expected Patryk/test to be valid after ensure step, "
        f"got {login_status}: {login_body}"
    )


def test_login_happy_path_with_patryk_test_credentials() -> None:
    _ensure_patryk_test_account()
    status, body = _request_json(
        "POST",
        "/account/login",
        {"name": "Patryk", "password": "test"},
    )

    assert status == 200
    assert body.get("token")
    assert body.get("account", {}).get("name") == "Patryk"


@pytest.mark.parametrize(
    "payload, expected_status",
    [
        ({"name": "Patryk", "password": "invalid-pass"}, 401),
        ({"name": "DefinitelyMissingUser", "password": "test"}, 401),
        ({"name": "Patryk"}, 400),
        ({"password": "test"}, 400),
        ({}, 400),
    ],
)
def test_login_invalid_and_missing_field_cases(
    payload: dict[str, str], expected_status: int
) -> None:
    status, body = _request_json("POST", "/account/login", payload)
    assert status == expected_status, f"Expected {expected_status}, got {status}: {body}"
    assert "error" in body


def test_auth_check_protected_route_requires_jwt() -> None:
    status, body = _request_json("GET", "/account/characters")
    assert status == 401
    assert "error" in body


def test_account_persistence_name_password_email_constraints() -> None:
    suffix = _unique_suffix()
    name = f"patryk{suffix}"
    password = "test"
    email = f"patryk{suffix}@example.com"

    register_status, register_body = _request_json(
        "POST",
        "/account/register",
        {"name": name, "password": password, "email": email},
    )
    assert register_status == 201, f"Register failed: {register_status}, {register_body}"

    login_status, login_body = _request_json(
        "POST",
        "/account/login",
        {"name": name, "password": password},
    )
    assert login_status == 200, f"Login failed: {login_status}, {login_body}"
    token = login_body.get("token")
    assert token

    same_name_status, _ = _request_json(
        "POST",
        "/account/register",
        {
            "name": name,
            "password": "test2",
            "email": f"other-{suffix}@example.com",
        },
    )
    assert same_name_status == 409

    same_email_status, _ = _request_json(
        "POST",
        "/account/register",
        {
            "name": f"other{suffix}",
            "password": "test2",
            "email": email,
        },
    )
    assert same_email_status == 409

    characters_status, characters_body = _request_json(
        "GET", "/account/characters", token=token
    )
    assert characters_status == 200, f"Characters fetch failed: {characters_status}, {characters_body}"
    assert "characters" in characters_body
