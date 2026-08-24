"""Firebase ID-token verification with sanitized client errors."""

import logging

from fastapi import HTTPException, status

from app.core.firebase import initialize_firebase

logger = logging.getLogger(__name__)


async def verify_firebase_token(token: str) -> dict:
    """Verify a Firebase ID token and return its decoded claims.

    Internal SDK and credential details are logged server-side but never exposed
    to the client. Authentication failures return 401; unavailable server-side
    authentication infrastructure returns 503.
    """
    try:
        from firebase_admin import auth as firebase_auth
    except ImportError:
        logger.exception("Firebase Admin SDK is unavailable")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service unavailable",
        )

    try:
        firebase_app = initialize_firebase(required=True)
    except RuntimeError:
        logger.exception("Firebase is not initialized for authentication")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service unavailable",
        )

    try:
        return firebase_auth.verify_id_token(
            token,
            app=firebase_app,
            check_revoked=True,
        )
    except Exception as exc:
        logger.warning(
            "Firebase token verification failed (%s)",
            type(exc).__name__,
            exc_info=True,
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
