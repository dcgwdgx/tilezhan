import 'dart:math';
import '../../../shared/models/puzzle_model.dart';
import '../../../shared/engine/shanten_calculator.dart';
import '../../../shared/engine/ukeire_calculator.dart';
import 'difficulty_scorer.dart';

/// Generates random Nani-Kiru puzzles with ELO difficulty scoring.
class PuzzleGenerator {
  static final _rng = Random();
  static int _counter = 0;

  static const _all34 = [
    'm1','m2','m3','m4','m5','m6','m7','m8','m9',
    'p1','p2','p3','p4','p5','p6','p7','p8','p9',
    's1','s2','s3','s4','s5','s6','s7','s8','s9',
    'z1','z2','z3','z4','z5','z6','z7',
  ];

  /// Generate a puzzle near [targetDifficulty] (Puzzle Rating 800-1600).
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

  static String _randomDraw(List<String> hand) {
    final counts = <String, int>{};
    for (final t in hand) { counts[t] = (counts[t] ?? 0) + 1; }
    final candidates = _all34.where((t) => (counts[t] ?? 0) < 4).toList();
    return candidates[_rng.nextInt(candidates.length)];
  }
}
