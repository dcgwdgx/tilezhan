"""Idempotency guard tests."""

from app.core.idempotency import check_idempotency


class TestIdempotency:
    def test_newer_client_accepted(self):
        """Client timestamp newer than server → accept"""
        assert check_idempotency(client_updated_at=200, server_updated_at=100) is True

    def test_equal_timestamp_accepted(self):
        """Same timestamp → accept"""
        assert check_idempotency(client_updated_at=100, server_updated_at=100) is True

    def test_older_client_rejected(self):
        """Client timestamp older → reject (stale data)"""
        assert check_idempotency(client_updated_at=100, server_updated_at=200) is False

    def test_zero_server_timestamp(self):
        """Server has no data (0) → accept"""
        assert check_idempotency(client_updated_at=100, server_updated_at=0) is True
