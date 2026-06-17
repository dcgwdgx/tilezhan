"""SRS 离线同步服务 — 批量写入，采用 LWW（Last-Writer-Wins）冲突解决策略。

本模块负责处理客户端离线期间积累的 SRS 复习操作，在恢复网络连接后
一次性批量同步到 Firestore。核心逻辑：
  1. 对每个操作按 item_id 定位 Firestore 文档。
  2. 用 client_timestamp 与服务器 updated_at 做 LWW 比较，
     过时操作直接跳过（幂等性保护）。
  3. 若文档已存在则读取现有 SM-2 状态；否则使用默认初始值。
  4. 调用 SM-2 算法计算新的记忆参数，写入 Firestore 批量提交。
"""

from datetime import datetime, timedelta, timezone

from app.core.idempotency import check_idempotency  # LWW 幂等性检查：客户端时间戳 vs 服务端时间戳
from app.domain.services.srs_service import SrsService  # SRS 核心服务（当前预留，未在 SyncService 中使用）


class SyncService:
    """SRS 离线同步服务。

    将客户端离线期间产生的 SRS 复习操作批量写入 Firestore，
    使用 LWW（Last-Writer-Wins）策略解决多端并发冲突。

    设计要点：
      - 使用 Firestore batch write，一次提交最多 500 条操作，
        避免逐条写入带来的延迟和成本。
      - 每条操作在写入前做幂等性检查，防止旧数据覆盖新数据。
      - SM-2 算法在服务端重新计算，确保参数一致性。
    """

    def __init__(self):
        """初始化同步服务，创建内部 SRS 服务实例（预留扩展点）。"""
        self._srs = SrsService()  # 当前仅持有引用，未来可用于校验或额外处理

    async def process_sync(self, uid: str, operations: list[dict], db) -> dict:
        """批量处理离线 SRS 操作并同步到 Firestore。

        对每个操作执行 LWW 冲突检测，过时操作直接丢弃；
        对有效操作在服务端重新运行 SM-2 算法后批量写入。

        Args:
            uid: 用户唯一标识，对应 Firestore users/{uid}/srs_items 子集合。
            operations: 客户端离线期间累积的操作列表，每条为 dict，包含：
                - item_id (str): 必填，SRS 项目唯一 ID。
                - client_timestamp (int): 必填，客户端操作时间戳（毫秒级 Unix 时间），
                  用于 LWW 冲突比较。
                - tile_id (str): 可选，关联的牌 ID，默认等于 item_id。
                - type (str): 可选，复习类型（如 "flashcard"），默认 "flashcard"。
                - quality (int): 可选，用户自评回忆质量 0-5，默认 3。
            db: Firestore 客户端实例（由调用方注入，避免硬编码依赖）。

        Returns:
            dict: {"synced": <int>} — 实际成功写入 Firestore 的操作数量。
        """
        # 定位用户的 SRS 子集合路径
        srs_ref = db.collection("users").document(uid).collection("srs_items")
        batch = db.batch()  # Firestore 批量写入对象，减少 RTT
        applied = 0  # 实际应用的操作计数

        for op in operations:
            # 定位目标文档
            doc_ref = srs_ref.document(op["item_id"])
            doc = await doc_ref.get()

            if doc.exists:
                # 文档已存在 — 读取当前 SM-2 状态并做 LWW 冲突检测
                server_updated_at = doc.to_dict().get("updated_at", 0)
                if not check_idempotency(op["client_timestamp"], server_updated_at):
                    # 客户端数据过时，跳过此操作，防止旧状态覆盖新状态
                    continue

                # 提取当前记忆参数作为 SM-2 计算的输入
                ef = doc.to_dict().get("easiness_factor", 2.5)
                reps = doc.to_dict().get("repetitions", 0)
                interval = doc.to_dict().get("interval_days", 0)
            else:
                # 新文档 — 使用 SM-2 默认初始值
                ef, reps, interval = 2.5, 0, 0

            # --- SM-2 算法更新 ---
            quality = op.get("quality", 3)  # 用户自评质量（0-5），默认 3 表示中等
            new_ef, new_reps, new_interval = self._sm2(ef, reps, interval, quality)

            # 计算下次复习时间：当前 UTC 时间 + 新间隔天数
            now = datetime.now(timezone.utc)
            next_review_ts = int((now + timedelta(days=new_interval)).timestamp() * 1000)

            # 批量写入：merge=True 表示合并而非覆盖整个文档
            batch.set(doc_ref, {
                "item_id": op["item_id"],
                "tile_id": op.get("tile_id", op["item_id"]),
                "type": op.get("type", "flashcard"),
                "easiness_factor": new_ef,
                "repetitions": new_reps,
                "interval_days": new_interval,
                "next_review": next_review_ts,
                "updated_at": op["client_timestamp"],
            }, merge=True)
            applied += 1

        # 一次性提交所有批量操作到 Firestore
        await batch.commit()
        return {"synced": applied}

    @staticmethod
    def _sm2(ef: float, reps: int, interval: int, quality: int) -> tuple:
        """SM-2 间隔重复算法的核心计算逻辑。

        根据 Piotr Woźniak 的 SuperMemo SM-2 算法，基于用户自评质量
        更新易度因子（easiness factor）、重复次数和复习间隔。

        Args:
            ef: 当前易度因子（easiness factor），最小值 1.3，初始值 2.5。
            reps: 当前连续正确回忆的次数。
            interval: 当前复习间隔（天）。
            quality: 用户自评回忆质量，取值 0-5：
                0-2 — 失败/勉强，重置重复计数，间隔降为 1 天。
                3   — 及格但不够流畅。
                4   — 流畅但略有犹豫。
                5   — 完美回忆。

        Returns:
            tuple: (new_ef, new_reps, new_interval)
                - new_ef (float): 更新后的易度因子，不会低于 1.3。
                - new_reps (int): 更新后的重复次数。
                - new_interval (int): 下一次复习应间隔的天数。
        """
        # 质量低于 3 视为遗忘：重置复习进度，间隔回到 1 天
        if quality < 3:
            return ef, 0, 1

        # SM-2 易度因子更新公式：
        # EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        # 质量越高 EF 增幅越大，质量越低 EF 降幅越大，但不低于 1.3
        new_ef = max(1.3, ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
        new_reps = reps + 1

        # 间隔计算规则：
        #   第 1 次成功 → 1 天
        #   第 2 次成功 → 6 天
        #   第 3 次及以后 → 当前间隔 × 新易度因子（四舍五入）
        if new_reps == 1:
            new_interval = 1
        elif new_reps == 2:
            new_interval = 6
        else:
            new_interval = round(interval * new_ef)

        return new_ef, new_reps, new_interval
