/// 何切（Nanikiru）谜题难度评分系统。
///
/// Difficulty scoring system for Nanikiru puzzles.
///
/// 从 6 个正交维度评估每道谜题（向听距离、有效切牌数、受入复杂度、
/// 陷阱吸引力、役种识别难度、时间压力），计算加权总分后映射到
/// PRD §B1.3 定义的 800–1600 谜题评分（Puzzle Rating）区间。
///
/// Evaluates every puzzle on 6 orthogonal dimensions (shanten distance, valid
/// discard count, ukeire complexity, trap attraction, yaku recognition, and
/// time pressure), computes a weighted sum, and maps it to the 800–1600
/// Puzzle Rating scale defined in PRD §B1.3.
///
/// 该评分既用于谜题库的排序，也用于通过 [targetRange] 将谜题匹配到
/// 玩家当前的 ELO 段位。
///
/// The rating is used both for sorting the puzzle library and for matching
/// puzzles to a player's current ELO band via [targetRange].
import 'package:tilezhan/shared/models/puzzle_model.dart';

/// 基于 PRD §B1.3 的六维谜题评分计算器。
///
/// 6-dimensional Puzzle Rating calculator per PRD §B1.3.
///
/// ## 计算公式 / Formula
///
///     Puzzle_Rating = 800 + Σ(维度得分 × 权重 × 400)
///     Puzzle_Rating = 800 + Σ(dimension_score × weight × 400)
///
/// ## 六个维度（权重见 [_weights]）
///
/// Dimensions (weights in [_weights])
///
/// - **向听数 shanten** (0.25)：向听数越高 = 离听牌越远 = 越难。
///   Higher shanten number = further from tenpai = harder.
///
/// - **有效切牌数 validDiscards** (0.20)：正确的切牌选项越少 = 越难。
///   Fewer correct discard options = harder.
///
/// - **受入复杂度 ukeireComplexity** (0.20)：能改良手牌的牌种越多 = 越难
///   识别最优打线。
///   More tile types that improve the hand = harder to identify the optimal line.
///
/// - **陷阱吸引力 trapAttraction** (0.15)：存在看似诱人实则错误的切牌选项。
///   Presence of tempting-but-wrong discards.
///
/// - **役种识别 yakuRecognition** (0.10)：识别获胜役种的难度。
///   Difficulty of spotting the winning yaku.
///
/// - **时间压力 timePressure** (0.10)：限时模式下的时间压力系数（为限时模式预留）。
///   Time pressure multiplier (reserved for timed mode).
class DifficultyScorer {
  /// 各维度权重表，总和必须为 1.0。
  /// 调整这些权重可以改变各维度对最终 Puzzle Rating 的相对贡献比例。
  ///
  /// Dimension weights (must sum to 1.0). Tune these to shift the relative
  /// contribution of each dimension to the final Puzzle Rating.
  static const _weights = {
    'shanten': 0.25,
    'validDiscards': 0.20,
    'ukeireComplexity': 0.20,
    'trapAttraction': 0.15,
    'yakuRecognition': 0.10,
    'timePressure': 0.10,
  };

  /// 对一道谜题进行评分，返回其 Puzzle Rating（范围 800–1600）。
  ///
  /// 计算流程：依次计算六个维度的得分，乘以对应权重后累加，
  /// 最后通过公式 `800 + (总分 × 400)` 映射到目标区间。
  ///
  /// Score a puzzle and return its Puzzle Rating (800-1600).
  static int score(Puzzle puzzle) {
    double total = 0;

    // 向听数维度：向听数越高 = 越难
    // Shanten: higher = harder
    total += _scoreShanten(puzzle) * _weights['shanten']!;

    // 有效切牌数维度：正确选项越少 = 越难
    // Valid discards: fewer correct options = harder
    total += _scoreValidDiscards(puzzle) * _weights['validDiscards']!;

    // 受入复杂度维度：受入牌种越多 = 越难识别最优解
    // Ukeire complexity: more types = harder to identify
    total += _scoreUkeireComplexity(puzzle) * _weights['ukeireComplexity']!;

    // 陷阱吸引力维度：占位实现——需要真实谜题数据才能精确评分
    // Trap: placeholder — needs real puzzle data for accurate scoring
    total += 0.5 * _weights['trapAttraction']!;

    // 役种识别维度：占位实现——MVP 阶段未追踪役种信息
    // Yaku: placeholder — MVP doesn't track yaku
    total += 0.3 * _weights['yakuRecognition']!;

    // 时间压力维度：MVP 阶段固定为 0（无限时模式）
    // Time pressure: fixed for MVP (no timed mode)
    total += 0.0 * _weights['timePressure']!;

    return 800 + (total * 400).round();
  }

  /// 根据向听数评分：1向听=0.0, 2向听=0.3, 3向听=0.6, 4向听及以上=1.0。
  ///
  /// 实现方式：通过受入牌数（ukeireCount）反推向听数——
  /// 受入越多表示离听牌越近、难度越低。
  ///
  /// 1-shanten=0, 2-shanten=0.5, 3+=1.0
  static double _scoreShanten(Puzzle p) {
    // 通过受入牌数估算向听数：受入牌数越多 = 离听牌越近 = 越简单
    // Estimate shanten from ukeire count: more ukeire = closer to tenpai = easier
    if (p.ukeireCount >= 20) return 0.0;
    if (p.ukeireCount >= 12) return 0.3;
    if (p.ukeireCount >= 6) return 0.6;
    return 1.0;
  }

  /// 根据有效切牌选项数量评分：选项越少 = 难度越高。
  ///
  /// 当前为近似实现——精确评分需要完整的弃牌分析。
  /// 通过受入牌数间接衡量：受入少的局面通常有效切牌也少。
  ///
  /// Fewer valid discards = harder
  static double _scoreValidDiscards(Puzzle p) {
    // 近似实现：通过受入牌数估算有效切牌数——精确评分需要完整弃牌分析
    // This is an approximation — real scoring needs full discard analysis
    if (p.ukeireCount <= 3) return 1.0;
    if (p.ukeireCount <= 6) return 0.7;
    if (p.ukeireCount <= 10) return 0.4;
    return 0.1;
  }

  /// 根据受入牌种类数评分：受入牌种越多 = 局面越复杂。
  ///
  /// 受入牌种数（ukeireTypes）表示有多少种不同的牌可以改良当前手牌。
  /// 种类越多，玩家越难在所有可能的改良路线中找出最优解。
  ///
  /// More ukeire types = more complex
  static double _scoreUkeireComplexity(Puzzle p) {
    if (p.ukeireTypes >= 8) return 1.0;
    if (p.ukeireTypes >= 5) return 0.6;
    if (p.ukeireTypes >= 3) return 0.3;
    return 0.0;
  }

  /// 根据用户 ELO 等级返回对应的目标谜题难度区间。
  ///
  /// 匹配逻辑：
  /// - ELO < 900  → 目标难度 850（入门级谜题）
  /// - ELO < 1100 → 目标难度 1000（初级谜题）
  /// - ELO < 1300 → 目标难度 1200（中级谜题）
  /// - ELO ≥ 1300 → 目标难度 1400（高级谜题）
  ///
  /// 该值用于从谜题库中筛选与玩家当前实力匹配的谜题。
  ///
  /// Target difficulty range for user ELO level.
  static int targetRange(int userElo) {
    if (userElo < 900) return 850;
    if (userElo < 1100) return 1000;
    if (userElo < 1300) return 1200;
    return 1400;
  }
}
