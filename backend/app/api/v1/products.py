"""Product Definitions API + RevenueCat Entitlement Map"""

from fastapi import APIRouter

from app.api.v1.products_data import PRODUCTS, ENTITLEMENT_MAP

router = APIRouter(prefix="/products", tags=["Products"])


@router.get("/")
async def list_products():
    """Return all available IAP products."""
    return {"products": PRODUCTS, "entitlement_map": ENTITLEMENT_MAP}
