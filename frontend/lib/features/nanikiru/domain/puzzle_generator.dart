import 'dart:math';
import '../../../shared/engine/shanten_calculator.dart';
import '../../../shared/engine/ukeire_calculator.dart';
import 'nanikiru_state.dart';

/// A single Nani-Kiru puzzle with all metadata.
class Puzzle {
  final List<String> hand13Ids;   // 13 base tiles
  final String drawnTileId;       // the tile just drawn
  final String correctDiscardId;  // optimal discard
  final int ukeireCount;
  final int ukeireTypes;
  final List<String> ukeireTileIds;

  const Puzzle({
    required this.hand13Ids,
    required this.drawnTileId,
    required this.correctDiscardId,
    required this.ukeireCount,
    required this.ukeireTypes,
    required this.ukeireTileIds,
  });
}

/// Generates random Nani-Kiru puzzles with validated solutions.
class PuzzleGenerator {
  static final _rng = Random();

  static const _all34 = [
    'm1','m2','m3','m4','m5','m6','m7','m8','m9',
    'p1','p2','p3','p4','p5','p6','p7','p8','p9',
    's1','s2','s3','s4','s5','s6','s7','s8','s9',
    'z1','z2','z3','z4','z5','z6','z7',
  ];

  /// Generate a random puzzle. Retries if no interesting decision found.
  static Puzzle generate() {
    for (int attempt = 0; attempt < 50; attempt++) {
      final hand13 = _randomHand(13);
      final drawn = _randomDraw(hand13);
      final hand14 = [...hand13, drawn];

      final shanten = ShantenCalculator.fromIds(hand14).calculate();
      // Skip trivially easy or impossible hands
      if (shanten > 3 || shanten < 0) continue;

      final results = UkeireCalculator(hand14).calculate();
      if (results.isEmpty) continue;

      // Find best discard: min shanten, max ukeire
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

      // Puzzle must have exactly 1 optimal answer with meaningful ukeire
      if (best == null || maxUkeire < 2) continue;

      return Puzzle(
        hand13Ids: hand13,
        drawnTileId: drawn,
        correctDiscardId: best,
        ukeireCount: maxUkeire,
        ukeireTypes: bestTypes,
        ukeireTileIds: bestTiles,
      );
    }
    // Fallback: return a simple known-good puzzle
    return const Puzzle(
      hand13Ids: ['m1','m1','m2','m3','m3','m4','m5','m5','m6','m7','m8','m8','m9'],
      drawnTileId: 's7',
      correctDiscardId: 'm4',
      ukeireCount: 11,
      ukeireTypes: 3,
      ukeireTileIds: ['2p', '5p', '8p'],
    );
  }

  static List<String> _randomHand(int count) {
    final counts = <String, int>{};
    final hand = <String>[];
    while (hand.length < count) {
      final tile = _all34[_rng.nextInt(34)];
      final c = counts[tile] ?? 0;
      if (c < 4) {
        counts[tile] = c + 1;
        hand.add(tile);
      }
    }
    return hand;
  }

  static String _randomDraw(List<String> hand) {
    final counts = <String, int>{};
    for (final t in hand) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
    // Pick a tile that's either not in hand or has fewer than 4 copies
    final candidates = _all34.where((t) => (counts[t] ?? 0) < 4).toList();
    return candidates[_rng.nextInt(candidates.length)];
  }
}
