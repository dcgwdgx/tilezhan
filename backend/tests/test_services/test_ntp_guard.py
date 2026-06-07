"""NTP anti-tampering guard tests."""

import pytest
import time
from app.core.ntp_guard import validate_client_timestamp, MAX_DEVIATION_SECONDS
from app.core.exceptions import TimestampTampered


class TestNTPGuard:
    def test_valid_timestamp_passes(self):
        """Current timestamp should pass validation"""
        now_ms = int(time.time() * 1000)
        validate_client_timestamp(now_ms)

    def test_future_timestamp_within_tolerance(self):
        """Timestamp 4 minutes ahead should pass"""
        now_ms = int(time.time() * 1000) + (MAX_DEVIATION_SECONDS - 60) * 1000
        validate_client_timestamp(now_ms)

    def test_future_timestamp_exceeds_tolerance(self):
        """Timestamp 10 minutes ahead should fail"""
        now_ms = int(time.time() * 1000) + (MAX_DEVIATION_SECONDS + 300) * 1000
        with pytest.raises(TimestampTampered):
            validate_client_timestamp(now_ms)

    def test_past_timestamp_exceeds_tolerance(self):
        """Timestamp 10 minutes ago should fail"""
        now_ms = int(time.time() * 1000) - (MAX_DEVIATION_SECONDS + 300) * 1000
        with pytest.raises(TimestampTampered):
            validate_client_timestamp(now_ms)
