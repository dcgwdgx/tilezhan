"""SRS (间隔重复系统) 服务模块 —— 基于 SM-2 算法实现。

本模块实现了 Piotr Woźniak 的 SuperMemo SM-2 算法，用于驱动间隔重复学习。
SM-2 通过三个核心参数控制复习节奏：
  - EF (Easiness Factor)：易度因子，反映卡片的难易程度，初始值 2.5
  - Reps (Repetitions)：连续正确回忆次数
  - Interval：当前复习间隔（天）

核心公式：
  new_ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
  new_ef ≥ 1.3（下限保护）
  new_interval = { 1 (首次) | 6 (第二次) | round(interval * new_ef) (第三次及以上) }
"""
# ========== 导入 ==========
from datetime import datetime, timedelta, timezone  # 时间处理：到期判断、下次复习时间计算


class SrsService:
    """SM-2 间隔重复服务。

    职责：
      1. 封装 SM-2 算法核心逻辑（_sm2 静态方法）
      2. 提供面向业务的服务接口：查询到期卡片、更新单张卡片、批量同步离线操作
      3. 作为领域服务层，不直接操作数据库——通过传入的 db 参数委托数据访问

    使用场景：
      - 用户完成一张牌的学习后调用 update_item 计算下次复习时间
      - 首页/复习页调用 get_due_items 获取到期待复习的卡片列表
      - 离线学习后联网时调用 batch_sync 批量同步操作记录

    注意事项：
      - EF 下限为 1.3，防止卡片永远不出现在复习队列中
      - quality < 3 视为遗忘，重置 reps 和 interval 但不降低 EF
      - 当前 get_due_items / update_item / batch_sync 为 stub 实现，待接入数据库层
    """

    # ========================================================================
    # SM-2 算法核心
    # ========================================================================

    @staticmethod
    def _sm2(ef: float, reps: int, interval: int, quality: int) -> tuple[float, int, int]:
        """
        执行一次 SM-2 算法迭代，根据用户评分更新卡片的学习状态。

        SM-2 算法将用户对卡片的回忆质量量化为 0-5 分：
          0 — 完全遗忘（blackout）
          1 — 错误回忆，但看到答案后有印象
          2 — 错误回忆，但看到答案后觉得简单
          3 — 正确回忆，但很费力
          4 — 正确回忆，稍有犹豫
          5 — 完全流畅，瞬间回忆

        Args:
            ef (float): 当前易度因子（Easiness Factor），初始值 2.5。
                        值越大表示卡片越容易，复习间隔增长越快。
            reps (int): 当前连续正确回忆次数。每次 quality >= 3 时 +1，
                        quality < 3 时重置为 0。
            interval (int): 当前复习间隔（天）。
                            首次正确 1 天，第二次正确 6 天，
                            之后按 interval * ef 递增。
            quality (int): 本次回忆质量评分，取值范围 0-5。

        Returns:
            tuple[float, int, int]: 三元组 (new_ef, new_reps, new_interval)
              - new_ef (float): 更新后的易度因子，不低于 1.3
              - new_reps (int): 更新后的连续正确次数
              - new_interval (int): 下次复习前应等待的天数
        """
        # --- 遗忘分支：评分低于 3 视为未能正确回忆 ---
        if quality < 3:
            # 重置复习进度，但保留 EF——卡片难度不会因为一次遗忘而改变
            return ef, 0, 1

        # --- 正确回忆分支：quality >= 3 ---

        # 计算新的易度因子
        # 公式拆解：
        #   quality_diff = 5 - quality  → 评分越低，惩罚越大
        #   penalty = quality_diff * (0.08 + quality_diff * 0.02)  → 二次函数，越差扣越多
        #   new_ef = ef + 0.1 - penalty
        #   当 quality = 5 时：penalty = 0, new_ef = ef + 0.1  → 微涨
        #   当 quality = 4 时：penalty = 0.10, new_ef = ef      → 不变
        #   当 quality = 3 时：penalty = 0.24, new_ef = ef - 0.14 → 下降
        new_ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
        # EF 下限保护：不能低于 1.3，否则间隔永远拉不长，卡片会过于频繁地出现
        new_ef = max(1.3, new_ef)

        # 连续正确次数 +1
        new_reps = reps + 1

        # 根据新的重复次数计算下次复习间隔（天）
        if new_reps == 1:
            # 首次正确回忆：1 天后复习
            new_interval = 1
        elif new_reps == 2:
            # 第二次正确回忆：6 天后复习（加速跳过早期频繁阶段）
            new_interval = 6
        else:
            # 第三次及以上：间隔 = 当前间隔 × 易度因子，四舍五入取整
            new_interval = round(interval * new_ef)

        return new_ef, new_reps, new_interval

    # ========================================================================
    # 业务服务接口
    # ========================================================================

    def get_due_items(self, uid: str, db) -> list:
        """
        查询指定用户当前到期的 SRS 复习卡片。

        到期判定条件：卡片的 next_review 时间 <= 当前时间（UTC）。

        Args:
            uid (str): 用户唯一标识符（User ID）。
            db: 数据库会话/连接对象（接口待定，当前为 stub 占位）。

        Returns:
            list: 到期卡片列表，每项为包含卡片复习状态的数据字典。
                  Stub 实现暂时返回空列表。

        TODO:
            - 接入数据库后，查询条件：WHERE user_id = uid AND next_review <= now()
            - 返回字段应包含：tile_id, ef, reps, interval, next_review, last_review
        """
        return []  # Stub：尚未接入数据库层

    def update_item(self, uid: str, tile_id: str, quality: int, db) -> dict:
        """
        处理用户对单张卡片的复习评分，计算并返回新的学习状态。

        工作流程：
          1. 从数据库读取该卡片的当前状态（ef, reps, interval）——Stub 阶段使用默认初始值
          2. 调用 _sm2 算法计算新状态
          3. 将新状态写回数据库
          4. 返回更新后的状态

        Args:
            uid (str): 用户唯一标识符（User ID）。
            tile_id (str): 被复习的卡片唯一标识符（Tile ID）。
            quality (int): 用户对本次回忆质量的评分，0-5 分。
            db: 数据库会话/连接对象（接口待定，当前为 stub 占位）。

        Returns:
            dict: 更新后的学习状态，包含以下字段：
              - ef (float): 易度因子
              - reps (int): 连续正确回忆次数
              - interval (int): 下次复习间隔（天）

        TODO:
            - 接入数据库后，先查询现有状态，而非使用硬编码初始值
            - 写入新的 next_review = now + interval 天
            - 记录 last_review = now
        """
        # Stub：使用 SM-2 默认初始值，实际应从数据库读取
        ef, reps, interval = 2.5, 0, 1
        return self._sm2(ef, reps, interval, quality)

    def batch_sync(self, uid: str, operations: list[dict], db) -> dict:
        """
        批量同步离线期间积累的 SRS 操作记录。

        适用场景：用户在无网络环境学习后回到在线状态，需要将本地的复习记录
        一次性同步到服务器。每条操作记录包含 tile_id、quality、timestamp 等字段。

        同步策略：
          - 按时间戳顺序处理每条操作，确保因果一致性
          - 每条操作独立调用 _sm2 更新状态
          - 返回成功同步的操作数量

        Args:
            uid (str): 用户唯一标识符（User ID）。
            operations (list[dict]): 离线操作列表，每条记录包含：
              - tile_id (str): 卡片标识符
              - quality (int): 回忆质量评分 0-5
              - timestamp (str/ISO): 操作发生的时间戳
            db: 数据库会话/连接对象（接口待定，当前为 stub 占位）。

        Returns:
            dict: 同步结果摘要，包含以下字段：
              - synced (int): 成功同步的操作数量

        TODO:
            - 实现按 timestamp 排序后再逐条处理的逻辑
            - 加入事务保护：部分失败时回滚，避免数据不一致
            - 处理冲突：若服务器端已有更新的操作记录，如何合并
        """
        return {"synced": len(operations)}  # Stub：仅返回操作计数，未实际处理
