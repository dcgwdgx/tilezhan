"""Global exception handlers with HTTP status code mapping."""

from fastapi import Request
from fastapi.responses import JSONResponse


class AppError(Exception):
    def __init__(self, message: str, status_code: int = 400):
        self.message = message
        self.status_code = status_code


class StaleDataError(AppError):
    """Client data is older than server — reject to prevent overwrite."""
    def __init__(self):
        super().__init__("Data is stale. Refresh and retry.", 409)


class RateLimitExceeded(AppError):
    def __init__(self):
        super().__init__("Too many requests", 429)


class InsufficientStamina(AppError):
    def __init__(self):
        super().__init__("No hearts remaining", 400)


class TimestampTampered(AppError):
    def __init__(self):
        super().__init__("Client timestamp deviates from server time", 400)


async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.message, "code": type(exc).__name__},
    )
