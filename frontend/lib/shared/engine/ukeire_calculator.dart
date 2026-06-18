/// 立直麻将的牌效率（有効牌／受け入れ）计算器。
///
/// 中文概念说明：
/// - **有効牌（ウケイレ / ukeire）**：摸进来之后能**减少向听数**的牌，即"对你前进有帮助的牌"。
/// - **受け入れ枚数**：考虑墙中剩余张数后的实际有効牌总数（本类用
///   `ukeireCount` 表示，扣除了手中已持有的张数）。
/// - **牌效率（牌効率）**：衡量一手牌的进张广度——有効牌种类越多、枚数
///   越大，听牌速度越快。
///
/// 工作原理：
/// 给定一副 14 张的手牌（门清状态），对每个可以打出的候选牌，模拟"打出
/// 后再摸进 34 种牌中的每一种"，检查向听数是否下降。结果用于 AI 比较
/// 不同切牌候选的优劣：有効牌枚数越多 → 进张路径越多 → 越优先保留。
///
/// 移植自后端 app/engine/ukeire.py。
library ukeire_calculator;

import 'shanten_calculator.dart';

/// 计算打出某张牌后的有効牌（进张）情况。
///
/// ## 算法概述
///
/// 对一副 14 张的手牌，逐一尝试打出每种不重复的牌，模拟"打出 1 张 + 摸
/// 进 1 张（遍历全部 34 种牌）"的组合，统计能降低向听数的进张牌种类和
/// 总枚数。
///
/// ## 使用场景
///
/// - AI 切牌决策：比较各候选切牌的有効牌枚数，选择进张最广的一打。
/// - 牌局分析：判断当前手牌距离听牌还有多远，以及哪些牌是"关键牌"。
/// - 防守判断：了解对手可能的有効牌范围（结合读牌）。
///
/// ## 性能说明
///
/// 最坏情况：13 种不同牌 × 34 种摸进 = 442 次向听计算。每次向听计算
/// 为 O(1) 查表操作，因此总耗时极低，适合在 AI 遍历决策树时高频调用。
class UkeireCalculator {
  /// 待分析的 14 张手牌（门清，未打牌前）。
  ///
  /// 牌 ID 格式为 `'m1'`~`'m9'`（万）、`'p1'`~`'p9'`（筒）、
  /// `'s1'`~`'s9'`（索）、`'z1'`~`'z7'`（字）。
  ///
  /// 恰好 14 张，由构造函数校验。允许包含重复牌（如对子、刻子）。
  final List<String> hand14;

  /// 构造一个 UkeireCalculator 实例。
  ///
  /// [hand14] 必须恰好包含 14 个牌 ID，否则抛出 [ArgumentError]。
  /// 传入的列表不会被拷贝——调用方应确保在计算期间不修改它。
  UkeireCalculator(this.hand14) {
    if (hand14.length != 14) throw ArgumentError('Expected 14 tiles');
  }

  /// 计算每张可打出的候选牌对应的有効牌信息。
  ///
  /// ## 算法步骤
  ///
  /// 1. 遍历手牌中每种**不重复**的牌作为切牌候选（相同的牌只算一次，
  ///    因为打出哪张同名牌进张结果完全一样）。
  /// 2. 从手牌中移除该候选牌，得到 13 张残留手牌。
  /// 3. 计算残留手牌的向听数作为基准（`baseShanten`）。
  /// 4. 对全部 34 种牌逐一模拟"摸进 1 张"：
  ///    - 如果该牌在残留手中已有 4 张（赤牌 / 正常上限），跳过。
  ///    - 用残留手牌 + 摸进牌（共 14 张）重新计算向听数。
  ///    - 如果新向听数 < 基准向听数 → 此牌是有効牌。
  /// 5. 有効牌枚数 = Σ(4 - 残留手中该牌的张数)，即考虑了墙中实际
  ///    剩余数（一副牌同种最多 4 张）。
  ///
  /// ## 返回值
  ///
  /// `Map<String, _DiscardResult>` — key 为切牌候选牌的 ID，value 包含：
  /// - 切牌后的向听数
  /// - 有効牌种类列表
  /// - 有効牌总枚数
  ///
  /// ## 注意
  ///
  /// 本方法不扣除其他玩家已打出的牌（河底牌）或副露中的牌——仅考虑
  /// 纯理论最大值。实际对局中应结合可见牌张调整计数。
  Map<String, DiscardResult> calculate() {
    final results = <String, DiscardResult>{};
    final seen = <String>{};

    for (var i = 0; i < hand14.length; i++) {
      final discardId = hand14[i];
      // 同名牌只计算一次：打出哪张都一样
      if (seen.contains(discardId)) continue;
      seen.add(discardId);

      // 移除第 i 张后剩余的 13 张手牌
      final remaining = <String>[...hand14.sublist(0, i), ...hand14.sublist(i + 1)];
      final ukeireTypes = <String>[];
      var ukeireCount = 0;
      // 切牌后的基准向听数
      final baseShanten = ShantenCalculator.fromIds(remaining).calculate();

      // 遍历全部 34 种牌，测试每种摸进是否能降低向听数
      for (final testId in _allTileIds) {
        // 同种牌手里已有 4 张则不可能再摸到，跳过
        if (remaining.where((t) => t == testId).length >= 4) continue;
        final candidate = [...remaining, testId];
        final newShanten = ShantenCalculator.fromIds(candidate).calculate();
        if (newShanten < baseShanten) {
          // 此牌摸进后向听数下降 → 是有効牌
          ukeireTypes.add(testId);
          // 剩余枚数 = 理论 4 张 - 手中已持有的张数
          ukeireCount += 4 - remaining.where((t) => t == testId).length;
        }
      }

      results[discardId] = DiscardResult(
        shantenAfter: baseShanten,
        ukeireTypes: ukeireTypes,
        ukeireCount: ukeireCount,
      );
    }
    return results;
  }

  /// 日本麻将全部 34 种牌的 ID 列表。
  ///
  /// - 万子（Manzu / 萬子）：1m ~ 9m
  /// - 筒子（Pinzu / 筒子）：1p ~ 9p
  /// - 索子（Souzu / 索子）：1s ~ 9s
  /// - 字牌（Jihai / 字牌）：1z ~ 7z（東南西北白發中）
  ///
  /// 此列表为编译时常量，在所有 UkeireCalculator 实例间共享。
  static const _allTileIds = [
    'm1','m2','m3','m4','m5','m6','m7','m8','m9',
    'p1','p2','p3','p4','p5','p6','p7','p8','p9',
    's1','s2','s3','s4','s5','s6','s7','s8','s9',
    'z1','z2','z3','z4','z5','z6','z7',
  ];
}

/// 单次切牌候选的计算结果。
///
/// 记录打出某张牌后：手牌的向听数、有哪些进张牌、理论最大进张枚数。
/// 调用方（如 [NanikiruNotifier]）通过这三个维度综合评判切牌优劣，
/// 并存入 [NaniKiruState] 供复盘面板使用。
class DiscardResult {
  /// 打出该候选牌后的向听数（`shantenAfter`）。
  ///
  /// - 0 表示已经听牌（门前清听牌状态）。
  /// - 数值越小越接近听牌，-1 表示已经和牌（通常不会出现在此处）。
  /// - 此值在所有候选牌中可能不同：有的牌打出后反而退向听（如拆搭子）。
  final int shantenAfter;

  /// 有効牌的种类列表（`ukeireTypes`）。
  ///
  /// 存储的是牌 ID 字符串，如 `['m3', 'm6', 'p7']`，表示摸进这些牌
  /// 中的任意一种都能降低向听数。
  ///
  /// 种类数（`ukeireTypes.length`）反映了进张的"广度"——种类越多，
  /// 摸到进张的概率越高。但某些进张可能枚数很少（如字牌单骑），
  /// 因此需结合 `ukeireCount` 综合判断。
  final List<String> ukeireTypes;

  /// 有効牌的理论最大剩余枚数（`ukeireCount`）。
  ///
  /// 计算方式：对有効牌种类中的每一种，取 `4 - 手中已持枚数` 再求和。
  /// 例如：摸 `m3` 和 `m6` 都是进张，手中已有 1 张 `m3`、0 张 `m6`，
  /// 则 `ukeireCount = (4-1) + (4-0) = 7`。
  ///
  /// 此值反映进张的"厚度"——枚数越多，实际摸到的概率越大。
  /// AI 决策时通常以枚数最大化为首要目标，种类数为次要参考。
  final int ukeireCount;

  /// 构造一个切牌评估结果对象。
  ///
  /// 所有字段为 `required`，调用方必须同时提供向听数、有効牌种类和枚数。
  const DiscardResult({required this.shantenAfter, required this.ukeireTypes, required this.ukeireCount});
}
