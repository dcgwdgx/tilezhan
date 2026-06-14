/// @file 何切题目模型
///
/// TileZhan 核心数据结构之一，描述一道"何切"(Nani-Kiru)题目：
/// 给定 13 张手牌 + 1 张自摸牌，玩家需要从 14 张中选出一张正确舍牌。
/// 模型记录手牌、自摸牌、正确舍牌、以及接受度(ukeire)信息。

/// 何切题目实体类。
///
/// 描述一道何切题目，包含：
/// - 13 张手牌 + 1 张自摸牌构成 14 张待切牌面
/// - 正确舍牌（专家/算法验证的最优解）
/// - 接受度统计（正确舍牌后的进张数与进张种类）
/// - 难度评级（Puzzle Rating, 800-1300）
class Puzzle {
  /// 题目唯一标识符，如 "p001"。
  final String puzzleId;

  /// 手牌 13 张，每张为牌 ID 字符串（如 "1m" = 一萬）。
  final List<String> hand13Ids;
  /// 自摸牌 ID，摸到手牌后总计 14 张。
  final String drawnTileId;

  /// 正确舍牌 ID（最优舍牌，经专家验证）。
  final String correctDiscardId;

  /// 正确舍牌后的总进张数（张数维度）。
  final int ukeireCount;

  /// 正确舍牌后的进张种类数（种类维度）。
  final int ukeireTypes;

  /// 所有有效进张的牌 ID 列表。
  final List<String> ukeireTileIds;

  /// 题目难度评级（Puzzle Rating），范围 800-1300，默认 1000。
  final int difficulty;

  /// 创建何切题目。
  ///
  /// 所有字段除 [difficulty] 外均为必填（[difficulty] 默认 1000）。
  const Puzzle({
    required this.puzzleId,
    required this.hand13Ids,
    required this.drawnTileId,
    required this.correctDiscardId,
    required this.ukeireCount,
    required this.ukeireTypes,
    required this.ukeireTileIds,
    this.difficulty = 1000,
  });
}
