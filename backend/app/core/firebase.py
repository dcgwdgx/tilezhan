"""Firebase Admin SDK initialization shared by authentication and Firestore."""

from __future__ import annotations

import logging
from threading import Lock
from typing import Any

from app.config import settings

logger = logging.getLogger(__name__)

_firebase_app: Any | None = None
_db: Any | None = None
_initialization_lock = Lock()


def _has_complete_firebase_config() -> bool:
    return all(
        str(value).strip()
        for value in (
            settings.FIREBASE_PROJECT_ID,
            settings.FIREBASE_PRIVATE_KEY,
            settings.FIREBASE_CLIENT_EMAIL,
        )
    )


def initialize_firebase(*, required: bool = False):
    """Initialize and return the default Firebase app exactly once.

    Development and test environments may run without Firebase when ``required``
    is false. Production passes ``required=True`` from the application lifespan,
    so missing or invalid credentials prevent the server from accepting traffic.
    """
    global _firebase_app

    if _firebase_app is not None:
        return _firebase_app

    if not _has_complete_firebase_config():
        if required:
            raise RuntimeError("Firebase configuration is incomplete")
        return None

    with _initialization_lock:
        if _firebase_app is not None:
            return _firebase_app

        try:
            import firebase_admin
            from firebase_admin import credentials

            try:
                firebase_app = firebase_admin.get_app()
            except ValueError:
                credential = credentials.Certificate(
                    {
                        "type": "service_account",
                        "project_id": settings.FIREBASE_PROJECT_ID,
                        "private_key": settings.FIREBASE_PRIVATE_KEY.replace(
                            "\\n", "\n"
                        ),
                        "client_email": settings.FIREBASE_CLIENT_EMAIL,
                        "token_uri": "https://oauth2.googleapis.com/token",
                    }
                )
                firebase_app = firebase_admin.initialize_app(
                    credential,
                    options={"projectId": settings.FIREBASE_PROJECT_ID},
                )

            existing_project = getattr(firebase_app, "project_id", None)
            if existing_project and existing_project != settings.FIREBASE_PROJECT_ID:
                raise RuntimeError("Firebase default app uses an unexpected project")

            _firebase_app = firebase_app
            return _firebase_app
        except Exception as exc:
            _firebase_app = None
            if required:
                raise RuntimeError("Firebase initialization failed") from exc
            logger.warning(
                "Firebase initialization failed in a non-production environment",
                exc_info=True,
            )
            return None


def get_firestore(*, required: bool = False):
    """Return the shared Firestore client, or ``None`` when optional and unset."""
    global _db

    if _db is not None:
        return _db

    firebase_app = initialize_firebase(required=required)
    if firebase_app is None:
        return None

    try:
        from firebase_admin import firestore

        _db = firestore.client(
            app=firebase_app,
            database_id=settings.FIRESTORE_DATABASE,
        )
        return _db
    except Exception as exc:
        _db = None
        if required:
            raise RuntimeError("Firestore initialization failed") from exc
        logger.warning(
            "Firestore initialization failed in a non-production environment",
            exc_info=True,
        )
        return None
