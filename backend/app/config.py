"""Mahjong Backend — Configuration"""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    APP_NAME: str = "TileZhan API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False

    FIREBASE_PROJECT_ID: str = ""
    FIREBASE_PRIVATE_KEY: str = ""
    FIREBASE_CLIENT_EMAIL: str = ""
    FIRESTORE_DATABASE: str = "(default)"

    REVENUECAT_API_KEY: str = ""
    REVENUECAT_WEBHOOK_SECRET: str = ""

    REDIS_URL: str = "redis://localhost:6379/0"

    RATE_LIMIT_PER_MINUTE: int = 100
    ALLOWED_ORIGINS: list[str] = ["https://tilezhan.app"]

    MAHJONG_RULE_SET: str = "riichi"

    model_config = {"env_file": ".env"}


settings = Settings()
