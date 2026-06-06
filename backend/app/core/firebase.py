"""Firebase Admin SDK — lazy initialization."""

_db = None


def get_firestore():
    global _db
    if _db is not None:
        return _db
    try:
        from firebase_admin import credentials, initialize_app, firestore
        from app.config import settings

        if not settings.FIREBASE_PROJECT_ID:
            return None

        cred = credentials.Certificate({
            "type": "service_account",
            "project_id": settings.FIREBASE_PROJECT_ID,
            "private_key": settings.FIREBASE_PRIVATE_KEY.replace("\\n", "\n"),
            "client_email": settings.FIREBASE_CLIENT_EMAIL,
            "token_uri": "https://oauth2.googleapis.com/token",
        })
        initialize_app(cred)
        _db = firestore.client(database_id=settings.FIRESTORE_DATABASE)
    except (ImportError, ValueError):
        _db = None
    return _db
