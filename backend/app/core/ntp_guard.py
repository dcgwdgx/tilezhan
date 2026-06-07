"""NTP anti-tampering — server-side timestamp validation.

Rejects requests where client timestamp deviates > 5 minutes from server time.
Prevents stamina cheating by modifying phone clock.
"""

from datetime import datetime, timedelta, timezone


MAX_DEVIATION_SECONDS = 300  # 5 minutes


def validate_client_timestamp(client_timestamp_ms: int) -> None:
    """Raise TimestampTampered if client time is too far from server."""
    from app.core.exceptions import TimestampTampered

    server_now = datetime.now(timezone.utc)
    client_time = datetime.fromtimestamp(client_timestamp_ms / 1000, tz=timezone.utc)
    deviation = abs((server_now - client_time).total_seconds())

    if deviation > MAX_DEVIATION_SECONDS:
        raise TimestampTampered()
