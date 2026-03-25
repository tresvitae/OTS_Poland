"""Frontend proxy login flow tests (non-E2E).

These tests target frontend-exposed `/api/*` routes through Nginx/Next proxy,
without browser automation. They verify login success/failure behavior,
validation, auth checks, and persistence behavior for register+login.

Usage:
  FRONTEND_BASE_URL=http://localhost pytest -q test/frontend/test_frontend_login_flow.py
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


FRONTEND_BASE_URL = os.getenv("FRONTEND_BASE_URL", "http://localhost").rstrip("/")
REQUEST_TIMEOUT_SECONDS = float(os.getenv("API_TEST_TIMEOUT", "8"))


def _request_json(
    method: str,
    path: str,
    payload: dict[str, Any] | None = None,
    token: str | None = None,
) -> tuple[int, dict[str, Any]]:
    url = f"{FRONTEND_BASE_URL}{path}"
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
def require_live_frontend_proxy() -> None:
    try:
        health_status, health_body = _request_json("GET", "/api/health")
    except Exception as exc:
        pytest.skip(f"Frontend/API proxy is not reachable at {FRONTEND_BASE_URL}: {exc}")

    if health_status != 200:
        pytest.skip(
            f"Proxy healthcheck returned status {health_status}, body={health_body}"
        )


def _ensure_patryk_test_account() -> None:
    status, _ = _request_json(
        "POST",
        "/api/account/login",
        {"name": "Patryk", "password": "test"},
    )

    if status == 200:
        return

    register_status, _ = _request_json(
        "POST",
        "/api/account/register",
        {
            "name": "Patryk",
            "password": "test",
            "email": "patryk.test@adventure.ots",
        },
    )

    if register_status not in {201, 409}:
        pytest.fail(
            f"Could not ensure Patryk/test through proxy, register status={register_status}"
        )

    login_status, login_body = _request_json(
        "POST",
        "/api/account/login",
        {"name": "Patryk", "password": "test"},
    )
    assert login_status == 200, (
        "Expected Patryk/test to be valid after ensure step, "
        f"got {login_status}: {login_body}"
    )


def test_frontend_proxy_login_happy_path() -> None:
    _ensure_patryk_test_account()
    status, body = _request_json(
        "POST",
        "/api/account/login",
        {"name": "Patryk", "password": "test"},
    )

    assert status == 200
    assert body.get("token")
    assert body.get("account", {}).get("name") == "Patryk"


@pytest.mark.parametrize(
    "payload, expected_status",
    [
        ({"name": "Patryk", "password": "wrong"}, 401),
        ({"name": "MissingProxyUser", "password": "test"}, 401),
        ({"name": "Patryk"}, 400),
        ({"password": "test"}, 400),
        ({}, 400),
    ],
)
def test_frontend_proxy_login_invalid_and_missing_cases(
    payload: dict[str, str], expected_status: int
) -> None:
    status, body = _request_json("POST", "/api/account/login", payload)
    assert status == expected_status, f"Expected {expected_status}, got {status}: {body}"
    assert "error" in body


def test_frontend_proxy_auth_check_requires_token() -> None:
    status, body = _request_json("GET", "/api/account/characters")
    assert status == 401
    assert "error" in body


def test_frontend_proxy_register_login_persistence_flow() -> None:
    suffix = _unique_suffix()
    name = f"frontend{suffix}"
    password = "test"
    email = f"frontend{suffix}@example.com"

    register_status, register_body = _request_json(
        "POST",
        "/api/account/register",
        {"name": name, "password": password, "email": email},
    )
    assert register_status == 201, (
        f"Register through proxy failed: {register_status}, {register_body}"
    )

    login_status, login_body = _request_json(
        "POST",
        "/api/account/login",
        {"name": name, "password": password},
    )
    assert login_status == 200, f"Proxy login failed: {login_status}, {login_body}"
    token = login_body.get("token")
    assert token

    duplicate_name_status, _ = _request_json(
        "POST",
        "/api/account/register",
        {
            "name": name,
            "password": "test2",
            "email": f"frontend2-{suffix}@example.com",
        },
    )
    assert duplicate_name_status == 409

    duplicate_email_status, _ = _request_json(
        "POST",
        "/api/account/register",
        {
            "name": f"frontend2{suffix}",
            "password": "test2",
            "email": email,
        },
    )
    assert duplicate_email_status == 409

    characters_status, characters_body = _request_json(
        "GET",
        "/api/account/characters",
        token=token,
    )
    assert characters_status == 200, (
        f"Proxy characters fetch failed: {characters_status}, {characters_body}"
    )
    assert "characters" in characters_body
