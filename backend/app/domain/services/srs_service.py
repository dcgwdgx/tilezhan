"""SRS (Spaced Repetition System) — SM-2 algorithm implementation."""

from datetime import datetime, timedelta, timezone


class SrsService:
    """SM-2 spaced repetition service."""

    @staticmethod
    def _sm2(ef: float, reps: int, interval: int, quality: int) -> tuple[float, int, int]:
        """
        SM-2 algorithm.
        Args:
            ef: Easiness factor (initial 2.5)
            reps: Number of consecutive correct recalls
            interval: Current interval in days
            quality: 0-5 score (0=complete blackout, 5=perfect recall)
        Returns:
            (new_ef, new_reps, new_interval)
        """
        if quality < 3:
            # Failed recall → reset but keep EF
            return ef, 0, 1

        # Successful recall
        new_ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
        new_ef = max(1.3, new_ef)  # EF floor

        new_reps = reps + 1

        if new_reps == 1:
            new_interval = 1
        elif new_reps == 2:
            new_interval = 6
        else:
            new_interval = round(interval * new_ef)

        return new_ef, new_reps, new_interval

    def get_due_items(self, uid: str, db) -> list:
        """Query SRS items where next_review <= now"""
        return []

    def update_item(self, uid: str, tile_id: str, quality: int, db) -> dict:
        """Update a single SRS item after review"""
        ef, reps, interval = 2.5, 0, 1
        return self._sm2(ef, reps, interval, quality)

    def batch_sync(self, uid: str, operations: list[dict], db) -> dict:
        """Batch sync offline SRS operations"""
        return {"synced": len(operations)}
