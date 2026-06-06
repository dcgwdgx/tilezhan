"""Firebase Auth token verification — with lazy import for dev without Firebase SDK."""

from fastapi import HTTPException, status


async def verify_firebase_token(token: str) -> dict:
    try:
        from firebase_admin import auth as firebase_auth
        return firebase_auth.verify_id_token(token, check_revoked=True)
    except ImportError:
        raise HTTPException(
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            detail="Firebase Admin SDK not installed. Run: pip install firebase-admin",
        )
    except Exception as e:
        err = str(e)
        if "expired" in err.lower():
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token expired")
        if "revoked" in err.lower():
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token revoked")
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))
