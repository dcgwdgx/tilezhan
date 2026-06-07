"""Subscription API — RevenueCat verification + webhooks."""

from fastapi import APIRouter, Depends, Request
from app.api.deps import get_current_user

router = APIRouter(prefix="/subscription", tags=["Subscription"])


@router.post("/verify")
async def verify_subscription(user: dict = Depends(get_current_user)):
    return {"is_pro": False, "expires_at": None}


@router.get("/status")
async def get_status(user: dict = Depends(get_current_user)):
    return {"tier": "free", "expires_at": None}


@router.post("/webhooks/revenuecat")
async def revenuecat_webhook(request: Request):
    return {"status": "ok"}
