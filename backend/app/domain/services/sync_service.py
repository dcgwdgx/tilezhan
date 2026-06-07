"""SRS offline sync service — batch writes with LWW conflict resolution."""

from datetime import datetime, timedelta, timezone
from app.core.idempotency import check_idempotency
from app.domain.services.srs_service import SrsService


class SyncService:
    def __init__(self):
        self._srs = SrsService()

    async def process_sync(self, uid: str, operations: list[dict], db) -> dict:
        """Batch-process offline SRS operations with LWW.

        Uses Firestore batch writes for performance.
        """
        srs_ref = db.collection("users").document(uid).collection("srs_items")
        batch = db.batch()
        applied = 0

        for op in operations:
            doc_ref = srs_ref.document(op["item_id"])
            doc = await doc_ref.get()

            if doc.exists:
                server_updated_at = doc.to_dict().get("updated_at", 0)
                if not check_idempotency(op["client_timestamp"], server_updated_at):
                    continue  # stale data, skip

                ef = doc.to_dict().get("easiness_factor", 2.5)
                reps = doc.to_dict().get("repetitions", 0)
                interval = doc.to_dict().get("interval_days", 0)
            else:
                ef, reps, interval = 2.5, 0, 0

            # SM-2 update
            quality = op.get("quality", 3)
            new_ef, new_reps, new_interval = self._sm2(ef, reps, interval, quality)
            now = datetime.now(timezone.utc)

            batch.set(doc_ref, {
                "item_id": op["item_id"],
                "tile_id": op.get("tile_id", op["item_id"]),
                "type": op.get("type", "flashcard"),
                "easiness_factor": new_ef,
                "repetitions": new_reps,
                "interval_days": new_interval,
                "next_review": int((now + timedelta(days=new_interval)).timestamp() * 1000),
                "updated_at": op["client_timestamp"],
            }, merge=True)
            applied += 1

        await batch.commit()
        return {"synced": applied}

    @staticmethod
    def _sm2(ef: float, reps: int, interval: int, quality: int) -> tuple:
        if quality < 3:
            return ef, 0, 1
        new_ef = max(1.3, ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
        new_reps = reps + 1
        new_interval = 1 if new_reps == 1 else (6 if new_reps == 2 else round(interval * new_ef))
        return new_ef, new_reps, new_interval
