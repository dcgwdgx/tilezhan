"""Ukeire (进张数 / 有効牌) 计算器 —— 日麻弃牌后的受入分析
=====================================================================

术语说明：
  - 向听数 (shanten)：手牌距离听牌 (tenpai) 还差几张牌。0 表示已经听牌。
  - 进张数 (ukeire / 有効牌)：打出某张牌后, 摸到能使向听数下降的牌的种类数与总枚数。
  - 有効牌种类 (ukeire_types)：打出某张牌后能改善牌效的牌面种类列表。
  - 有効牌枚数 (ukeire_count)：打出某张牌后能改善牌效的牌面总剩余枚数 (扣除手牌已占)。

算法概要：
  给定 14 张手牌, 对每张唯一的候选弃牌:
    1. 模拟弃牌 (从手牌中移除, 得到 13 张剩余牌)
    2. 遍历全部 34 种牌面, 模拟摸入, 形成 14 张新组合
    3. 计算新组合的向听数, 若比弃牌前的基准向听数小, 则该牌面为有効牌
    4. 该牌面的有効枚数 = 4 (每种牌共 4 枚) - 手牌中已有枚数

用途：
  供 AI 决策引擎在《牌占》游戏中评估弃牌候选的质量,
  选出进张数最高的弃牌选项以最大化听牌概率。
"""

from app.engine.shanten import ShantenCalculator  # 向听数计算器: 计算手牌距离听牌的最小牌数
from app.domain.models.tile import ALL_TILE_IDS  # 全部 34 种牌面 ID 列表 (m1-m9, p1-p9, s1-s9, z1-z7)


class UkeireCalculator:
    """进张数 (有効牌) 计算器 —— 分析 14 张手牌中每张弃牌的受入能力。

    对一副完整的 14 张手牌 (配牌或中盘状态), 逐一模拟打出每张唯一的牌,
    然后遍历所有可能的摸入牌面, 统计能降低向听数的牌面种类数与剩余枚数。

    典型用法:
        calc = UkeireCalculator(hand_14_tiles)
        results = calc.calculate()
        # results[discard_id] = {
        #     "shanten_after": 弃牌后手牌的向听数,
        #     "ukeire_types":   有效进张的种类列表,
        #     "ukeire_count":   有效进张的总枚数,
        # }

    Attributes:
        tiles (list[str]): 14 张手牌的牌面 ID 列表 (如 ["m1", "m1", "p3", ...])
        _base_shanten (int): 弃牌前整副手牌的基准向听数 (所有弃牌候选都与此比较)
    """

    def __init__(self, tile_ids: list[str]):
        """初始化进张数计算器。

        校验输入必须是 14 张牌 (日麻配牌标准数量), 并预先计算基准向听数,
        避免在遍历弃牌 / 摸入时重复计算。

        Args:
            tile_ids: 14 张手牌的牌面 ID 列表, 每张为 "m1"~"z7" 格式。

        Raises:
            ValueError: 当输入牌数不为 14 时抛出。
        """
        if len(tile_ids) != 14:
            raise ValueError(f"Expected 14 tiles, got {len(tile_ids)}")
        self.tiles = tile_ids  # 原始手牌 (不可变, 用于后续枚数计数和索引访问)
        self._base_shanten = ShantenCalculator(tile_ids).calculate()  # 弃牌前的基准向听数

    def calculate(self) -> dict[str, dict]:
        """计算每张唯一弃牌候选的进张数信息。

        核心流程:
          1. 遍历手牌, 跳过已处理过的重复牌面 (同种牌面结果相同, 避免重复计算)
          2. 对每张候选弃牌, 构建弃后 13 张剩余牌
          3. 遍历全部 34 种牌面, 模拟摸入形成 14 张, 判断向听数是否改善
          4. 统计有効牌种类和枚数, 其中枚数需扣除手牌中已占用的数量

        Returns:
            dict: key 为弃牌牌面 ID (str), value 为一个包含以下字段的字典:
                - shanten_after (int): 弃牌后 (13 张) 的向听数
                - ukeire_types (list[str]): 有效进张的牌面种类列表
                - ukeire_count (int): 有效进张的总剩余枚数 (已扣除手牌占用)
        """
        results: dict[str, dict] = {}
        seen: set[str] = set()  # 已处理过的牌面集合, 用于跳过同种弃牌 (结果相同)

        for i, discard_id in enumerate(self.tiles):
            # --- 去重：同种牌面只算一次, 因为打出任意一张 m1 的进张数相同 ---
            if discard_id in seen:
                continue
            seen.add(discard_id)

            # --- 构建弃后 13 张剩余牌: 移除当前索引的牌 ---
            remaining = self.tiles[:i] + self.tiles[i + 1:]

            ukeire_types: list[str] = []  # 有效进张的种类列表
            ukeire_count = 0              # 有效进张的总枚数

            # --- 遍历全部 34 种牌面, 模拟摸入 ---
            for test_id in ALL_TILE_IDS:
                candidate = remaining + [test_id]  # 模拟摸入后的 14 张手牌
                shanten = ShantenCalculator(candidate).calculate()  # 计算新向听数

                # 若新向听数 < 基准向听数, 说明这张摸入牌能改善牌效
                if shanten < self._base_shanten:
                    ukeire_types.append(test_id)
                    # 每种牌在牌山中初始有 4 枚, 减去手牌中已占用的枚数即为剩余有效枚数
                    ukeire_count += 4 - self.tiles.count(test_id)

            # --- 计算弃牌后剩余 13 张牌的向听数 (用于 UI 展示或进一步分析) ---
            results[discard_id] = {
                "shanten_after": ShantenCalculator(remaining).calculate(),
                "ukeire_types": ukeire_types,
                "ukeire_count": ukeire_count,
            }

        return results
