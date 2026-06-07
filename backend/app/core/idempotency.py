"""Idempotency guard — prevents duplicate operations.

Compares client `updated_at` against server record.
If server has newer data, rejects the operation to prevent stale overwrites.
"""


def check_idempotency(client_updated_at: int, server_updated_at: int) -> bool:
    """Return True if the client operation should proceed (client data is newer)."""
    return client_updated_at >= server_updated_at
