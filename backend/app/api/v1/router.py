"""API v1 Router — aggregates all sub-routers"""

from fastapi import APIRouter

from app.api.v1 import puzzles, mahjong, srs, user, subscription, products

api_router = APIRouter()
api_router.include_router(user.router)
api_router.include_router(puzzles.router)
api_router.include_router(mahjong.router)
api_router.include_router(srs.router)
api_router.include_router(subscription.router)
api_router.include_router(products.router)
