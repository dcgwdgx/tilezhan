"""FastAPI Dependencies — Auth, DB"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.config import settings
from app.core.security import verify_firebase_token

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """Verify Firebase ID Token. Falls back to dev mode if Firebase not configured."""
    token = credentials.credentials

    if settings.DEBUG or not settings.FIREBASE_PROJECT_ID:
        return {"uid": "dev-user", "email": "dev@tilezhan.app"}

    try:
        return await verify_firebase_token(token)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))
