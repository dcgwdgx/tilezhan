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
import 'dart:math';
import '../../../shared/models/puzzle_model.dart';
import '../../../shared/engine/shanten_calculator.dart';
import '../../../shared/engine/ukeire_calculator.dart';
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
class PuzzleGenerator {
  static final _rng = Random();
  static int _counter = 0;

  static const _all34 = [
    'm1','m2','m3','m4','m5','m6','m7','m8','m9',
    'p1','p2','p3','p4','p5','p6','p7','p8','p9',
    's1','s2','s3','s4','s5','s6','s7','s8','s9',
    'z1','z2','z3','z4','z5','z6','z7',
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
  static Puzzle generate({int targetDifficulty = 1000}) {
    Puzzle? bestPuzzle;
    int bestDiff = 99999;

    for (int attempt = 0; attempt < 50; attempt++) {
      final hand13 = _randomHand(13);
      final drawn = _randomDraw(hand13);
      final hand14 = [...hand13, drawn];

      final shanten = ShantenCalculator.fromIds(hand14).calculate();
      if (shanten > 3 || shanten < 0) continue;

      final results = UkeireCalculator(hand14).calculate();
      if (results.isEmpty) continue;

      int bestShanten = 99;
      for (final r in results.values) {
        if (r.shantenAfter < bestShanten) bestShanten = r.shantenAfter;
      }

      String? best;
      int maxUkeire = -1;
      int bestTypes = 0;
      List<String> bestTiles = [];
      for (final e in results.entries) {
        final v = e.value;
        if (v.shantenAfter == bestShanten && v.ukeireCount > maxUkeire) {
          maxUkeire = v.ukeireCount;
          best = e.key;
          bestTypes = v.ukeireTypes.length;
          bestTiles = v.ukeireTypes;
        }
      }

      if (best == null || maxUkeire < 2) continue;

      _counter++;
      final puzzle = Puzzle(
        puzzleId: 'puzzle_$_counter',
        hand13Ids: hand13,
        drawnTileId: drawn,
        correctDiscardId: best,
        ukeireCount: maxUkeire,
        ukeireTypes: bestTypes,
        ukeireTileIds: bestTiles,
        difficulty: 0, // scored below
      );

      final score = DifficultyScorer.score(puzzle);
      final diff = (score - targetDifficulty).abs();

      if (diff < bestDiff) {
        bestDiff = diff;
        bestPuzzle = Puzzle(
          puzzleId: puzzle.puzzleId,
          hand13Ids: hand13,
          drawnTileId: drawn,
          correctDiscardId: best,
          ukeireCount: maxUkeire,
          ukeireTypes: bestTypes,
          ukeireTileIds: bestTiles,
          difficulty: score,
        );
      }
    }

    if (bestPuzzle != null) return bestPuzzle;

    // Fallback
    _counter++;
    return Puzzle(
      puzzleId: 'fallback_$_counter',
      hand13Ids: const ['m1','m1','m2','m3','m3','m4','m5','m5','m6','m7','m8','m8','m9'],
      drawnTileId: 's7',
      correctDiscardId: 'm4',
      ukeireCount: 11, ukeireTypes: 3,
      ukeireTileIds: const ['2p','5p','8p'],
      difficulty: 950,
    );
  }

  /// Draw [count] tiles uniformly from the 34 tile types (max 4 copies each),
  /// returning a randomly-generated Mahjong hand.
  static List<String> _randomHand(int count) {
    final counts = <String, int>{};
    final hand = <String>[];
    while (hand.length < count) {
      final tile = _all34[_rng.nextInt(34)];
      final c = counts[tile] ?? 0;
      if (c < 4) { counts[tile] = c + 1; hand.add(tile); }
    }
    return hand;
  }

  /// Pick a random draw tile that is not already at its maximum of 4 copies
  /// in [hand], ensuring a legal Mahjong hand (no 5th copy of any tile).
  static String _randomDraw(List<String> hand) {
    final counts = <String, int>{};
    for (final t in hand) { counts[t] = (counts[t] ?? 0) + 1; }
    final candidates = _all34.where((t) => (counts[t] ?? 0) < 4).toList();
    return candidates[_rng.nextInt(candidates.length)];
  }
}
