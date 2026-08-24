"""Runtime configuration security checks."""

import pytest

from app.config import Settings, validate_runtime_settings


def _production_settings(**overrides) -> Settings:
    values = {
        "APP_ENV": "production",
        "DEBUG": False,
        "ALLOW_DEV_AUTH_BYPASS": False,
        "FIREBASE_PROJECT_ID": "tilezhan-production",
        "FIREBASE_PRIVATE_KEY": "test-private-key",
        "FIREBASE_CLIENT_EMAIL": "service@tilezhan-production.iam.gserviceaccount.com",
        "REVENUECAT_WEBHOOK_SECRET": "test-webhook-secret",
    }
    values.update(overrides)
    return Settings(_env_file=None, **values)


def test_development_allows_missing_external_credentials():
    runtime_settings = Settings(
        _env_file=None,
        APP_ENV="development",
        FIREBASE_PROJECT_ID="",
        FIREBASE_PRIVATE_KEY="",
        FIREBASE_CLIENT_EMAIL="",
        REVENUECAT_WEBHOOK_SECRET="",
    )

    validate_runtime_settings(runtime_settings)


def test_production_requires_all_security_credentials():
    runtime_settings = _production_settings(
        FIREBASE_PROJECT_ID="",
        FIREBASE_PRIVATE_KEY="",
        FIREBASE_CLIENT_EMAIL="",
        REVENUECAT_WEBHOOK_SECRET="",
    )

    with pytest.raises(RuntimeError) as exc_info:
        validate_runtime_settings(runtime_settings)

    message = str(exc_info.value)
    assert "FIREBASE_PROJECT_ID" in message
    assert "FIREBASE_PRIVATE_KEY" in message
    assert "FIREBASE_CLIENT_EMAIL" in message
    assert "REVENUECAT_WEBHOOK_SECRET" in message


@pytest.mark.parametrize(
    ("overrides", "expected_message"),
    [
        ({"DEBUG": True}, "DEBUG must be false"),
        (
            {"ALLOW_DEV_AUTH_BYPASS": True},
            "ALLOW_DEV_AUTH_BYPASS must be false",
        ),
    ],
)
def test_production_rejects_unsafe_flags(overrides, expected_message):
    runtime_settings = _production_settings(**overrides)

    with pytest.raises(RuntimeError, match=expected_message):
        validate_runtime_settings(runtime_settings)


def test_complete_production_configuration_is_accepted():
    validate_runtime_settings(_production_settings())
