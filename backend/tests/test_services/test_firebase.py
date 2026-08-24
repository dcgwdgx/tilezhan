"""Firebase initialization behavior."""

import pytest

from app.core import firebase


def _reset_firebase(monkeypatch):
    monkeypatch.setattr(firebase, "_firebase_app", None)
    monkeypatch.setattr(firebase, "_db", None)


def test_optional_firebase_is_disabled_when_configuration_is_missing(monkeypatch):
    _reset_firebase(monkeypatch)
    monkeypatch.setattr(firebase.settings, "FIREBASE_PROJECT_ID", "")
    monkeypatch.setattr(firebase.settings, "FIREBASE_PRIVATE_KEY", "")
    monkeypatch.setattr(firebase.settings, "FIREBASE_CLIENT_EMAIL", "")

    assert firebase.initialize_firebase(required=False) is None


def test_required_firebase_fails_closed_when_configuration_is_missing(monkeypatch):
    _reset_firebase(monkeypatch)
    monkeypatch.setattr(firebase.settings, "FIREBASE_PROJECT_ID", "")
    monkeypatch.setattr(firebase.settings, "FIREBASE_PRIVATE_KEY", "")
    monkeypatch.setattr(firebase.settings, "FIREBASE_CLIENT_EMAIL", "")

    with pytest.raises(RuntimeError, match="configuration is incomplete"):
        firebase.initialize_firebase(required=True)


def test_firebase_app_is_initialized_once_and_cached(monkeypatch):
    import firebase_admin
    from firebase_admin import credentials

    _reset_firebase(monkeypatch)
    monkeypatch.setattr(firebase.settings, "FIREBASE_PROJECT_ID", "tilezhan-test")
    monkeypatch.setattr(firebase.settings, "FIREBASE_PRIVATE_KEY", "test-key")
    monkeypatch.setattr(
        firebase.settings,
        "FIREBASE_CLIENT_EMAIL",
        "service@tilezhan-test.iam.gserviceaccount.com",
    )

    fake_app = type("FakeFirebaseApp", (), {"project_id": "tilezhan-test"})()
    calls = {"credential": 0, "initialize": 0}

    def no_existing_app():
        raise ValueError("default app does not exist")

    def build_credential(payload):
        calls["credential"] += 1
        assert payload["project_id"] == "tilezhan-test"
        return object()

    def initialize_app(_credential, *, options):
        calls["initialize"] += 1
        assert options == {"projectId": "tilezhan-test"}
        return fake_app

    monkeypatch.setattr(firebase_admin, "get_app", no_existing_app)
    monkeypatch.setattr(firebase_admin, "initialize_app", initialize_app)
    monkeypatch.setattr(credentials, "Certificate", build_credential)

    assert firebase.initialize_firebase(required=True) is fake_app
    assert firebase.initialize_firebase(required=True) is fake_app
    assert calls == {"credential": 1, "initialize": 1}
