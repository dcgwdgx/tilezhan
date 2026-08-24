/// Nani-Kiru (何切る) puzzle generator.
///
/// Generates random Mahjong tile-discard puzzles with progressive difficulty
/// scoring via ELO-calibrated heuristics. The generator uses a generate-and-test
/// approach: random 14-tile hands are sampled, filtered for playability (shanten
/// 0-3 and non-trivial uke-ire), scored against a target difficulty rating, and
/// the best match over 50 attempts is returned.
///
/// The difficulty scoring pipeline:
/// 1. A random 13-tile hand + 1 drawn tile form a 14-tile puzzle state.
/// 2. [ShantenCalculator] determines the current shanten number.
/// 3. [UkeireCalculator] evaluates every possible discard, computing uke-ire
///    count, types, and resulting shanten.
/// 4. [DifficultyScorer] rates the puzzle on an ELO-like 800-1600 scale
///    based on hand complexity, uke-ire distribution, and decision ambiguity.
///
/// A static fallback puzzle is provided for resilience when the generator fails
/// to produce a suitable puzzle within 50 attempts.
///
/// ============================================================================
/// 【中文说明】何切る（打哪张）谜题生成器
///
/// 使用基于 ELO 校准启发式算法的渐进式难度评分，随机生成麻将切牌谜题。
/// 生成器采用"生成-测试"策略：随机抽取 14 张手牌样本，经过可玩性过滤
/// （向听数 0-3 且有效进张数非平凡），按目标难度评分，在 50 次尝试中
/// 返回最佳匹配。
///
/// 难度评分流水线：
/// 1. 随机生成 13 张手牌 + 1 张摸牌，构成 14 张谜题状态。
/// 2. [ShantenCalculator] 计算当前向听数。
/// 3. [UkeireCalculator] 评估每种可能的切牌，计算有效进张数、种类和切后向听数。
/// 4. [DifficultyScorer] 基于手牌复杂度、进张分布和决策歧义度，按类 ELO 的
///    800-1600 分制对谜题进行评分。
///
/// 当生成器在 50 次尝试内无法生成合适谜题时，提供一个静态兜底谜题以保证可用性。
import 'dart:math';
import 'package:tilezhan/shared/engine/shanten_calculator.dart';
import 'package:tilezhan/shared/engine/ukeire_calculator.dart';
import 'package:tilezhan/shared/models/puzzle_model.dart';
import 'difficulty_scorer.dart';

/// Generates random Nani-Kiru (何切る) puzzles with ELO-calibrated difficulty scoring.
///
/// The generator produces tile-discard decision puzzles suitable for player training.
/// Each puzzle presents a 14-tile hand (13 in hand + 1 drawn) and asks the player
/// to identify the single best discard. Correctness is determined by maximum uke-ire
/// count among moves that achieve the lowest post-discard shanten.
///
/// Puzzles are generated via repeated random sampling (up to 50 attempts per call),
/// with each candidate scored by [DifficultyScorer] and the closest match to the
/// requested [targetDifficulty] (default 1000) selected.
///
/// See [generate] for the main entry point.
///
/// 【中文】何切る谜题生成器类。
///
/// 生成适合玩家训练的切牌决策谜题。每个谜题呈现 14 张手牌（手牌 13 张 + 摸牌 1 张），
/// 要求玩家找出唯一最优切牌。正确判定标准为：在达到最低切后向听数的出牌中，
/// 有效进张数最多的那张即为正确答案。
///
/// 谜题通过重复随机采样生成（每次调用最多 50 次尝试），每个候选谜题由
/// [DifficultyScorer] 评分，最终选取与目标难度 [targetDifficulty]（默认 1000）
/// 最接近的一个返回。
///
/// 主入口方法参见 [generate]。
class PuzzleGenerator {
  /// 【字段】随机数生成器实例，用于手牌采样和摸牌随机选择。
  /// 使用 Dart 标准库的 [Random] 类，保证每次调用独立随机。
  static final _rng = Random();

  /// 【字段】谜题全局递增计数器，用于生成唯一 puzzleId。
  /// 每成功生成一个候选谜题（通过可玩性过滤后）自增 1。
  static int _counter = 0;

  /// 【常量】所有 34 种麻将牌的 ID 列表。
  ///
  /// 包含万子（m1-m9）、筒子（p1-p9）、索子（s1-s9）各 9 种，
  /// 以及字牌（z1-z7）7 种，共计 34 种牌型。
  /// 每种牌最多 4 张，由随机生成逻辑保证不超过上限。
  static const _all34 = [
    'm1',
    'm2',
    'm3',
    'm4',
    'm5',
    'm6',
    'm7',
    'm8',
    'm9',
    'p1',
    'p2',
    'p3',
    'p4',
    'p5',
    'p6',
    'p7',
    'p8',
    'p9',
    's1',
    's2',
    's3',
    's4',
    's5',
    's6',
    's7',
    's8',
    's9',
    'z1',
    'z2',
    'z3',
    'z4',
    'z5',
    'z6',
    'z7',
  ];

  /// Generate a single Nani-Kiru puzzle.
  ///
  /// Samples up to 50 random 14-tile hands, filters them for playability
  /// (shanten 0-3, at least one discard with uke-ire >= 2), scores each
  /// candidate via [DifficultyScorer.score], and returns the puzzle whose
  /// difficulty rating is closest to [targetDifficulty] (default 1000, range
  /// 800-1600).
  ///
  /// If no suitable candidate is found within 50 attempts, a static fallback
  /// puzzle (a simple penchan-wait hand) is returned.
  ///
  /// Returns a fully-scored [Puzzle] with hand, drawn tile, correct discard,
  /// uke-ire counts/types, and a difficulty rating.
  ///
  /// 【中文】生成单个何切る谜题。
  ///
  /// 流程：
  /// 1. 最多进行 50 次随机采样，每次生成 14 张手牌。
  /// 2. 过滤可玩性：向听数必须在 0-3 之间，且至少存在一种切牌的有效进张数 >= 2。
  /// 3. 通过 [DifficultyScorer.score] 对每个候选谜题评分。
  /// 4. 返回难度评分最接近 [targetDifficulty]（默认 1000，范围 800-1600）的谜题。
  ///
  /// 若 50 次尝试内未找到合适候选，返回一个静态兜底谜题（简单的边张听牌手牌）。
  ///
  /// 返回值：一个完全评分的 [Puzzle] 对象，包含手牌、摸牌、正确切牌、
  /// 有效进张数/种类及难度评分。
  static Puzzle generate({
    int targetDifficulty = 1000,
    Random? random,
    int maxAttempts = 50,
  }) {
    if (maxAttempts < 0) {
      throw ArgumentError.value(
          maxAttempts, 'maxAttempts', 'Must not be negative');
    }
    final rng = random ?? _rng;
    Puzzle? bestPuzzle;
    int bestDiff = 99999;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final hand13 = _randomHand(13, rng);
      final drawn = _randomDraw(hand13, rng);
      final hand14 = [...hand13, drawn];

      final shanten = ShantenCalculator.fromIds(hand14).calculate();
      if (shanten > 3 || shanten < 0) continue;

      final results = UkeireCalculator(hand14).calculate();
      if (results.isEmpty) continue;

      int bestShanten = 99;
      for (final r in results.values) {
        if (r.shantenAfter < bestShanten) bestShanten = r.shantenAfter;
      }

      int maxUkeire = -1;
      for (final result in results.values) {
        if (result.shantenAfter == bestShanten &&
            result.ukeireCount > maxUkeire) {
          maxUkeire = result.ukeireCount;
        }
      }

      final bestEntries = results.entries
          .where((entry) =>
              entry.value.shantenAfter == bestShanten &&
              entry.value.ukeireCount == maxUkeire)
          .toList();

      // This is a single-answer exercise. If multiple tile kinds are equally
      // optimal, accepting only whichever appeared first would teach a false
      // distinction, so discard the candidate and sample another hand.
      if (bestEntries.length != 1 || maxUkeire < 2) continue;
      final bestEntry = bestEntries.single;
      final best = bestEntry.key;
      final bestTiles = bestEntry.value.ukeireTypes;

      _counter++;
      final puzzle = Puzzle(
        puzzleId: 'puzzle_$_counter',
        hand13Ids: hand13,
        drawnTileId: drawn,
        correctDiscardId: best,
        ukeireCount: maxUkeire,
        ukeireTypes: bestTiles.length,
        ukeireTileIds: bestTiles,
        difficulty: 0, // scored below
      );

      final score = DifficultyScorer.score(
        puzzle,
        discardResults: results,
      );
      final diff = (score - targetDifficulty).abs();

      if (diff < bestDiff) {
        bestDiff = diff;
        bestPuzzle = Puzzle(
          puzzleId: puzzle.puzzleId,
          hand13Ids: hand13,
          drawnTileId: drawn,
          correctDiscardId: best,
          ukeireCount: maxUkeire,
          ukeireTypes: bestTiles.length,
          ukeireTileIds: bestTiles,
          difficulty: score,
        );
        if (bestDiff <= 25) return bestPuzzle;
      }
    }

    if (bestPuzzle != null) return bestPuzzle;

    // Fallback — 兜底谜题：当 50 次尝试全部失败时，返回一个预定义的简单边张听牌手牌，
    // 保证 API 调用方始终能获得一个可用的谜题，不会因随机生成失败而抛出异常。
    _counter++;
    final fallback = Puzzle(
      puzzleId: 'fallback_$_counter',
      hand13Ids: const [
        'm1',
        'm2',
        'm3',
        'm4',
        'm5',
        'm6',
        'p5',
        'p6',
        'p7',
        'p8',
        'p9',
        'z1',
        'z1',
      ],
      drawnTileId: 'z2',
      correctDiscardId: 'z2',
      ukeireCount: 7,
      ukeireTypes: 2,
      ukeireTileIds: const ['p4', 'p7'],
      difficulty: 0,
    );
    final fallbackAnalysis = UkeireCalculator([
      ...fallback.hand13Ids,
      fallback.drawnTileId,
    ]).calculate();
    return Puzzle(
      puzzleId: fallback.puzzleId,
      hand13Ids: fallback.hand13Ids,
      drawnTileId: fallback.drawnTileId,
      correctDiscardId: fallback.correctDiscardId,
      ukeireCount: fallback.ukeireCount,
      ukeireTypes: fallback.ukeireTypes,
      ukeireTileIds: fallback.ukeireTileIds,
      difficulty: DifficultyScorer.score(
        fallback,
        discardResults: fallbackAnalysis,
      ),
    );
  }

  /// 【方法】从 34 种牌型中均匀随机抽取 [count] 张牌，生成一副麻将手牌。
  ///
  /// 每种牌最多 4 张 —— 当某牌的计数已达 4 时跳过该牌重新抽取，
  /// 保证生成的手牌始终符合麻将规则（不会出现第 5 张同种牌）。
  ///
  /// 参数 [count]：需要生成的手牌张数（通常为 13）。
  /// 返回值：长度为 [count] 的牌 ID 字符串列表。
  static List<String> _randomHand(int count, Random rng) {
    if (count < 0 || count > 136) {
      throw ArgumentError.value(count, 'count', 'Must be between 0 and 136');
    }
    final wall = [
      for (final tileId in _all34)
        for (var copy = 0; copy < 4; copy++) tileId,
    ]..shuffle(rng);
    final hand = wall.take(count).toList();
    hand.sort(
        (left, right) => _all34.indexOf(left).compareTo(_all34.indexOf(right)));
    return hand;
  }

  /// 【方法】从不在 [hand] 中（或未满 4 张）的牌型中随机选取一张作为摸牌。
  ///
  /// 先统计当前手牌中各牌型的张数，排除已达到 4 张上限的牌型，
  /// 从剩余候选牌中均匀随机选取一张。保证不会出现第 5 张同种牌。
  ///
  /// 参数 [hand]：当前 13 张手牌列表。
  /// 返回值：一张合法的摸牌 ID 字符串。
  static String _randomDraw(List<String> hand, Random rng) {
    final counts = <String, int>{};
    for (final t in hand) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
    final remainingWall = [
      for (final tileId in _all34)
        for (var copy = counts[tileId] ?? 0; copy < 4; copy++) tileId,
    ];
    return remainingWall[rng.nextInt(remainingWall.length)];
  }
}
