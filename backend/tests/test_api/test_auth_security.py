"""Authentication and application-startup security regression tests."""

import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

import app.main as main_module
from app.api import deps
from app.core import security as auth_security


def _credentials(token: str = "test-token") -> HTTPAuthorizationCredentials:
    return HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)


@pytest.mark.asyncio
async def test_dev_auth_bypass_must_be_explicit(monkeypatch):
    monkeypatch.setattr(deps.settings, "APP_ENV", "development")
    monkeypatch.setattr(deps.settings, "ALLOW_DEV_AUTH_BYPASS", True)

    async def should_not_verify(_token):
        raise AssertionError("Firebase verification must not run in explicit bypass mode")

    monkeypatch.setattr(deps, "verify_firebase_token", should_not_verify)

    user = await deps.get_current_user(_credentials())

    assert user == {"uid": "dev-user", "email": "dev@tilezhan.app"}


@pytest.mark.asyncio
async def test_missing_project_or_debug_no_longer_bypasses_auth(monkeypatch):
    monkeypatch.setattr(deps.settings, "APP_ENV", "development")
    monkeypatch.setattr(deps.settings, "DEBUG", True)
    monkeypatch.setattr(deps.settings, "ALLOW_DEV_AUTH_BYPASS", False)
    monkeypatch.setattr(deps.settings, "FIREBASE_PROJECT_ID", "")
    observed = {}

    async def verify(token):
        observed["token"] = token
        return {"uid": "verified-user"}

    monkeypatch.setattr(deps, "verify_firebase_token", verify)

    user = await deps.get_current_user(_credentials("real-token"))

    assert observed["token"] == "real-token"
    assert user["uid"] == "verified-user"


@pytest.mark.asyncio
async def test_production_never_allows_dev_auth_bypass(monkeypatch):
    monkeypatch.setattr(deps.settings, "APP_ENV", "production")
    monkeypatch.setattr(deps.settings, "ALLOW_DEV_AUTH_BYPASS", True)

    with pytest.raises(HTTPException) as exc_info:
        await deps.get_current_user(_credentials())

    assert exc_info.value.status_code == 503
    assert exc_info.value.detail == "Authentication service unavailable"


@pytest.mark.asyncio
async def test_dependency_does_not_expose_unexpected_auth_errors(monkeypatch):
    monkeypatch.setattr(deps.settings, "APP_ENV", "test")
    monkeypatch.setattr(deps.settings, "ALLOW_DEV_AUTH_BYPASS", False)

    async def fail_verification(_token):
        raise RuntimeError("sensitive service-account detail")

    monkeypatch.setattr(deps, "verify_firebase_token", fail_verification)

    with pytest.raises(HTTPException) as exc_info:
        await deps.get_current_user(_credentials())

    assert exc_info.value.status_code == 503
    assert exc_info.value.detail == "Authentication service unavailable"
    assert "sensitive" not in exc_info.value.detail


@pytest.mark.asyncio
async def test_invalid_firebase_token_error_is_sanitized(monkeypatch):
    from firebase_admin import auth as firebase_auth

    fake_app = object()
    monkeypatch.setattr(
        auth_security,
        "initialize_firebase",
        lambda *, required: fake_app,
    )

    def reject_token(*_args, **_kwargs):
        raise ValueError("sensitive certificate and project details")

    monkeypatch.setattr(firebase_auth, "verify_id_token", reject_token)

    with pytest.raises(HTTPException) as exc_info:
        await auth_security.verify_firebase_token("bad-token")

    assert exc_info.value.status_code == 401
    assert exc_info.value.detail == "Invalid authentication credentials"
    assert "sensitive" not in exc_info.value.detail
    assert exc_info.value.headers == {"WWW-Authenticate": "Bearer"}


@pytest.mark.asyncio
async def test_firebase_initialization_error_is_sanitized(monkeypatch):
    def fail_initialization(*, required):
        raise RuntimeError("sensitive private-key detail")

    monkeypatch.setattr(auth_security, "initialize_firebase", fail_initialization)

    with pytest.raises(HTTPException) as exc_info:
        await auth_security.verify_firebase_token("token")

    assert exc_info.value.status_code == 503
    assert exc_info.value.detail == "Authentication service unavailable"
    assert "private-key" not in exc_info.value.detail


@pytest.mark.asyncio
async def test_lifespan_validates_before_initializing_firebase(monkeypatch):
    calls = []
    fake_app = object()
    monkeypatch.setattr(main_module.settings, "APP_ENV", "production")

    def validate(runtime_settings):
        calls.append(("validate", runtime_settings))

    def initialize(*, required):
        calls.append(("initialize", required))
        return fake_app

    monkeypatch.setattr(main_module, "validate_runtime_settings", validate)
    monkeypatch.setattr(main_module, "initialize_firebase", initialize)

    async with main_module.lifespan(main_module.app):
        assert main_module.app.state.firebase_app is fake_app

    assert calls == [
        ("validate", main_module.settings),
        ("initialize", True),
    ]


@pytest.mark.asyncio
async def test_lifespan_stops_before_firebase_when_validation_fails(monkeypatch):
    initialized = False

    def reject_configuration(_runtime_settings):
        raise RuntimeError("invalid production configuration")

    def initialize(*, required):
        nonlocal initialized
        initialized = True

    monkeypatch.setattr(main_module, "validate_runtime_settings", reject_configuration)
    monkeypatch.setattr(main_module, "initialize_firebase", initialize)

    with pytest.raises(RuntimeError, match="invalid production configuration"):
        async with main_module.lifespan(main_module.app):
            pass

    assert initialized is False
