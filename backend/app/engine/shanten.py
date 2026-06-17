"""向听数（Shanten）计算器 — 日本立直麻将

向听数 = 手牌距离听牌（tenpai）还差几张有效牌。
- 向听数 0 表示已经听牌（差 0 张即可和牌）
- 向听数 1 表示差 1 张有效牌即可听牌（一向听）
- 以此类推

核心算法：带剪枝的递归回溯搜索，覆盖三种和牌形态：
  1. 标准形（4 面子 + 1 雀头）
  2. 七对子（7 个对子）
  3. 国士无双（13 种幺九牌各至少 1 张 + 1 个对子）

手牌内部表示：长度为 34 的整数数组（list[int]），索引约定如下：
  - 0-8:   万子（1m ~ 9m）
  - 9-17:  筒子（1p ~ 9p）
  - 18-26: 索子（1s ~ 9s）
  - 27-33: 字牌（东 南 西 北 白 发 中，通常按 1z ~ 7z 排序）
"""

from dataclasses import dataclass
from typing import Optional

# 幺九牌索引列表：含万/筒/索的两端（1/9）以及所有字牌（27~33）
# 用于国士无双向听数计算时遍历所有幺九牌
TERMINAL_INDICES = [0, 8, 9, 17, 18, 26] + list(range(27, 34))


class ShantenCalculator:
    """计算一手牌的最小向听数。

    向听数定义为：要使手牌达到听牌状态所需替换的最少牌数。
    0 = 已听牌，1 = 一向听，以此类推。

    使用方式：
        calc = ShantenCalculator(["1m","1m","2m","3m",...])
        shanten = calc.calculate()  # 返回最小向听数

    内部状态：
        - tiles34: 34 元数组，每种牌出现的张数
        - _best: 搜索过程中当前最优（最小）向听数，初始为极大值
    """

    def __init__(self, tile_ids: list[str]):
        """初始化向听数计算器。

        Args:
            tile_ids: 牌 ID 字符串列表，格式为 "<数字><花色>"，
                      例如 "1m"=一萬, "5p"=五筒, "9s"=九索, "1z"=东。

        Raises:
            ValueError: 如果 tile_ids 为空列表。
        """
        if not tile_ids:
            raise ValueError("Tile list must not be empty")
        # 将字符串牌 ID 转换为 34 元内部数组
        self.tiles34 = self._to_34_array(tile_ids)
        # 最优向听数，初始化为极大值，搜索过程中逐步收敛
        self._best: int = 999

    @staticmethod
    def _to_34_array(tile_ids: list[str]) -> list[int]:
        """将牌 ID 字符串列表转换为 34 元计数数组。

        花色映射规则：
            'm' (万) → 索引 0~8，由数字直接映射
            'p' (筒) → 索引 9~17，偏移 +9
            's' (索) → 索引 18~26，偏移 +18
            'z' (字) → 索引 27~33，偏移 +27

        Args:
            tile_ids: 牌 ID 字符串列表，如 ["1m", "2m", "3m", "1z"]。

        Returns:
            长度为 34 的 list[int]，每个元素表示该索引对应牌的张数（0~4）。
        """
        arr = [0] * 34
        # 花色到索引起始偏移的映射
        suit_map = {'m': 0, 'p': 1, 's': 2, 'z': 3}
        for tid in tile_ids:
            suit_char = tid[0]           # 花色字符: m/p/s/z
            num = int(tid[1:])           # 数字部分: 1~9
            if suit_char == 'z':
                # 字牌: 索引 = 27 + (数字-1)，例如 1z→27, 7z→33
                idx = 27 + (num - 1)
            elif suit_char == 'm':
                # 万子: 索引 = 数字-1，例如 1m→0, 9m→8
                idx = num - 1
            elif suit_char == 'p':
                # 筒子: 索引 = 9 + (数字-1)，例如 1p→9, 9p→17
                idx = 9 + (num - 1)
            elif suit_char == 's':
                # 索子: 索引 = 18 + (数字-1)，例如 1s→18, 9s→26
                idx = 18 + (num - 1)
            else:
                raise ValueError(f"Invalid tile: {tid}")
            arr[idx] += 1
        return arr

    def calculate(self) -> int:
        """计算手牌的最小向听数。

        依次计算三种和牌形态的向听数，取最小值：
          1. 七对子形：6 - 对子数（简单公式，无需搜索）
          2. 国士无双形：13 - 幺九种类数 -（有无对子）
          3. 标准形（4 面子 + 1 雀头）：递归回溯搜索

        Returns:
            int: 最小向听数（0 = 已听牌，值越小越好）。
        """
        self._best = 999

        # --- 七对子（Chiitoitsu）向听数 ---
        # 七对子需要 7 个对子。每有一个对子就少需要一张牌。
        # 向听数 = 6 - 对子数（因为 7 个对子 = 0 向听, 6 个 = 1 向听, ...）
        pairs = sum(1 for c in self.tiles34 if c >= 2)
        chiitoi = 6 - pairs
        self._best = min(self._best, chiitoi)

        # --- 国士无双（Kokushi musou）向听数 ---
        kokushi = self._kokushi_shanten()
        self._best = min(self._best, kokushi)

        # --- 标准形（4 面子 + 1 雀头）向听数 ---
        # 使用递归回溯搜索，从 4 面子 1 雀头开始尝试各种拆分方式
        self._search_melds(4, 1)
        return self._best

    def _kokushi_shanten(self) -> int:
        """计算国士无双（十三幺）的向听数。

        国士无双的完成形：13 种幺九牌各至少 1 张，且其中一种至少 2 张（雀头）。
        向听数 = 13 -（已拥有的幺九牌种类数）-（已有一对时额外减 1）

        Returns:
            int: 国士无双形向听数。值越小越好，0 表示已听牌。
        """
        kinds = 0       # 已拥有的幺九牌种类数
        has_pair = False  # 是否已有一个幺九对子（某幺九牌 ≥ 2 张）
        for i in TERMINAL_INDICES:
            if self.tiles34[i] > 0:
                kinds += 1       # 该种幺九牌至少有一张
            if self.tiles34[i] >= 2:
                has_pair = True  # 该种幺九牌已有一对，可作雀头
        # 需要 13 种全有 + 一个对子。缺的种类 = 13 - kinds，少对子再 +1
        return 13 - kinds - (1 if has_pair else 0)

    def _count_isolated_and_partials(self) -> int:
        """贪心估算手牌中"未成形"的孤立牌张数。

        用于递归搜索中的启发式剪枝。按以下顺序贪心移除已成形组合：
          1. 先移除所有刻子（3 张相同）
          2. 再移除所有顺子（3 张连续同花色）
          3. 最后至多移除一对雀头（2 张相同）

        剩下的牌张数即为"未成形"牌数的下界估计。

        Returns:
            int: 贪心处理后剩余的孤立牌张数（估计值，实际最优值 ≤ 此值）。
        """
        count = 0
        # 复制手牌数组，避免修改原始数据
        remaining = self.tiles34[:]

        # 第一轮：贪心移除所有刻子（相同牌 × 3）
        # 为什么先移除刻子：相比顺子，刻子不会跨索引，移除后不会影响其他牌的配对
        for i in range(34):
            while remaining[i] >= 3:
                remaining[i] -= 3

        # 第二轮：贪心移除所有顺子（连续 3 张同花色）
        # 仅遍历数牌（0~26，即 m/p/s），且从每段的第 1~7 位开始（i%9 ≤ 6）
        # 因为顺子需要 i, i+1, i+2 三张连续，不能跨越花色边界
        for i in range(27):
            if i % 9 <= 6:  # 不在每段花色的末尾两张（第 8、9 位无法作为顺子起点）
                while remaining[i] > 0 and remaining[i+1] > 0 and remaining[i+2] > 0:
                    remaining[i] -= 1
                    remaining[i+1] -= 1
                    remaining[i+2] -= 1

        # 第三轮：贪心移除至多一对雀头
        pairs_removed = 0
        for i in range(34):
            if remaining[i] >= 2 and pairs_removed < 1:
                remaining[i] -= 2
                pairs_removed += 1

        # 剩余牌张总和 = 无法构成完整面子/雀头的孤立牌估算数
        return sum(remaining)

    def _search_melds(self, mentsu: int, jantou: int):
        """递归回溯搜索标准形（4 面子 + 1 雀头）的最小向听数。

        核心思路：
          - 从手牌中递归地尝试取出面子（顺子/刻子）或雀头
          - 每取出一个组件，剩余需求减少，递归深入
          - 当 mentsu 和 jantou 都为 0 时，手牌已完全分解为 4+1，向听数为 0
          - 使用启发式剪枝（_count_isolated_and_partials）提前终止劣化分支

        Args:
            mentsu: 还需形成的面子数（初始为 4，每次递归递减）。
            jantou: 是否还需要雀头（1 = 需要, 0 = 已有/不需要）。
        """
        # ====== 启发式剪枝：估算当前分支的最优可能 ======
        # partial = 贪心估算剩余未成形牌数
        partial = self._count_isolated_and_partials()

        # 粗略向听数估算：
        #   needed = 剩余未成形牌数
        #   每张有效进张可以消除 2 张孤立牌（1 张自摸 + 1 张手中牌构成组合）
        #   est ≈ max(0, (needed - 已成形吸收的牌数 + 1) // 2)
        needed = partial
        est = max(0, (needed - mentsu * 3 - jantou * 2 + 1) // 2)
        # 加上剩余面子数作为惩罚（每缺一个面子至少需要 1 向听）
        self._best = min(self._best, max(0, est + (4 - mentsu)))

        # 已找到最优解（向听数 0），无需继续搜索
        if self._best == 0:
            return

        # 基底情况：所有面子和雀头都已取出，手牌完美分解 → 向听数 0
        if mentsu == 0 and jantou == 0:
            self._best = 0
            return

        # ====== 分支 1：尝试取出一个雀头（对子） ======
        # 仅当还需要雀头（jantou == 1）时尝试
        if jantou == 1:
            for i in range(34):
                if self.tiles34[i] >= 2:
                    # 取出 2 张相同牌作为雀头
                    self.tiles34[i] -= 2
                    self._search_melds(mentsu, 0)  # 雀头需求已满足
                    self.tiles34[i] += 2            # 回溯恢复

        # ====== 分支 2：尝试取出面子（刻子或顺子） ======
        if mentsu > 0:
            # 分支 2a：尝试取出刻子（相同牌 × 3）
            for i in range(34):
                if self.tiles34[i] >= 3:
                    # 取出 3 张相同牌作为一个刻子
                    self.tiles34[i] -= 3
                    self._search_melds(mentsu - 1, jantou)  # 面子需求 -1
                    self.tiles34[i] += 3                      # 回溯恢复

            # 分支 2b：尝试取出顺子（连续 3 张同花色数牌）
            # 仅遍历可作顺子起点的牌（索引 0~26，且不是每段花色的末尾两张）
            for i in range(27):
                if i % 9 <= 6:  # 确保 i, i+1, i+2 不跨越花色边界
                    if self.tiles34[i] > 0 and self.tiles34[i+1] > 0 and self.tiles34[i+2] > 0:
                        # 取出 3 张连续同花色牌作为一个顺子
                        self.tiles34[i] -= 1
                        self.tiles34[i+1] -= 1
                        self.tiles34[i+2] -= 1
                        self._search_melds(mentsu - 1, jantou)  # 面子需求 -1
                        self.tiles34[i] += 1                     # 回溯恢复
                        self.tiles34[i+1] += 1
                        self.tiles34[i+2] += 1
