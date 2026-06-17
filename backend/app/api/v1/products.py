"""
产品定义 API — IAP 商品列表与权限映射。

提供面向客户端的 IAP 商品信息端点：
- GET /products/：返回所有可购买商品及对应的权限映射

数据来源：
    从 products_data 模块导入 PRODUCTS（商品定义）和
    ENTITLEMENT_MAP（商品 ID → 权限等级映射），
    确保产品信息在整个后端中只有单一数据源。

用途：
    客户端在展示付费墙或商品列表时调用此端点，
    获取价格、周期、描述等展示信息。
"""

from fastapi import APIRouter

from app.api.v1.products_data import PRODUCTS, ENTITLEMENT_MAP

router = APIRouter(prefix="/products", tags=["Products"])


@router.get("/")
async def list_products():
    """
    返回所有可购买的 IAP 商品及其权限映射。

    Returns:
        dict: 包含两个字段：
            - products (dict): 商品 ID → 商品详情 {type, price, currency, period, title, description}
            - entitlement_map (dict): 商品 ID → 权限等级（如 "premium"）
    """
    return {"products": PRODUCTS, "entitlement_map": ENTITLEMENT_MAP}
