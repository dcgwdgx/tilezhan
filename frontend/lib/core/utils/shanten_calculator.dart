/// Shanten (向听数) Calculator — Dart implementation for client-side use.
///
/// Computes the minimum number of tiles needed to reach tenpai (听牌) from a
/// given 34-element hand vector. This is a re-export / alias module that
/// mirrors the canonical implementation to maintain backwards compatibility
/// during the migration to the unified `lib/core/` layout.
///
/// Per design spec: lib/core/utils/shanten_calculator.dart

/// The 13 terminal and honour tile indices (1-9-1-9 pattern across suits +
/// 7 honours). Used exclusively by the Kokushi (国士無双) shanten calculation.
const terminalIndices = [0, 8, 9, 17, 18, 26, 27, 28, 29, 30, 31, 32, 33];

/// Calculates the shanten number for a Mahjong hand represented as a
/// 34-element count vector (m1-m9, p1-p9, s1-s9, z1-z7).
///
/// Supports standard (mentsu + jantou) decomposition as well as the Kokushi
/// musou special case. The hand MUST contain exactly 3n+1, 3n+2, or 3n tiles;
/// violation of this precondition yields undefined results.
class ShantenCalculator {
  /// The 34-element hand vector. Index mapping:
  /// [0-8] m1-m9, [9-17] p1-p9, [18-26] s1-s9, [27-33] z1-z7.
  /// Each element is the count of that tile in the hand.
  final List<int> tiles34;

  /// Internal best shanten value found during the search.
  int _best = 999;

  /// Constructs a calculator from a raw 34-element count vector.
  ///
  /// The [tiles34] list must have exactly 34 integer elements (counts).
  ShantenCalculator(this.tiles34) : assert(tiles34.length == 34);

  /// Constructs a calculator from a list of tile ID strings (e.g. ["m1", "p5", "z7"]).
  ///
  /// Each string must start with a valid suit letter (m/p/s/z) followed by a
  /// numeric rank. The resulting hand is a simple count bucket; duplicate tiles
  /// are accumulated normally.
  factory ShantenCalculator.fromIds(List<String> tileIds) {
    final arr = List.filled(34, 0);
    for (final tid in tileIds) {
      arr[_tileIdToIndex(tid)] += 1;
    }
    return ShantenCalculator(arr);
  }

  static int _tileIdToIndex(String tid) {
    final suit = tid[0];
    final num = int.parse(tid.substring(1));
    return switch (suit) {
      'm' => num - 1,
      'p' => 9 + (num - 1),
      's' => 18 + (num - 1),
      'z' => 27 + (num - 1),
      _ => throw ArgumentError('Invalid tile: $tid'),
    };
  }

  /// Computes and returns the current hand's shanten number.
  ///
  /// Returns the minimum number of tiles away from tenpai.
  /// A return of 0 means the hand is already tenpai; -1 is agari (complete).
  int calculate() {
    _best = 999;
    final pairs = tiles34.where((c) => c >= 2).length;
    _best = (_best < 6 - pairs) ? _best : 6 - pairs;
    final kokushi = _kokushiShanten();
    _best = (_best < kokushi) ? _best : kokushi;
    _searchMelds(4, 1);
    return _best;
  }

  int _kokushiShanten() {
    int kinds = 0;
    bool hasPair = false;
    for (final i in terminalIndices) {
      if (tiles34[i] > 0) kinds++;
      if (tiles34[i] >= 2) hasPair = true;
    }
    return 13 - kinds - (hasPair ? 1 : 0);
  }

  void _searchMelds(int mentsu, int jantou) {
    if (_best == 0) return;
    if (mentsu == 0 && jantou == 0) { _best = 0; return; }
    if (jantou == 1) {
      for (int i = 0; i < 34; i++) {
        if (tiles34[i] >= 2) { tiles34[i] -= 2; _searchMelds(mentsu, 0); tiles34[i] += 2; }
      }
    }
    if (mentsu > 0) {
      for (int i = 0; i < 34; i++) {
        if (tiles34[i] >= 3) { tiles34[i] -= 3; _searchMelds(mentsu - 1, jantou); tiles34[i] += 3; }
      }
      for (int i = 0; i < 27; i++) {
        if (i % 9 <= 6) {
          if (tiles34[i] > 0 && tiles34[i + 1] > 0 && tiles34[i + 2] > 0) {
            tiles34[i] -= 1; tiles34[i + 1] -= 1; tiles34[i + 2] -= 1;
            _searchMelds(mentsu - 1, jantou);
            tiles34[i] += 1; tiles34[i + 1] += 1; tiles34[i + 2] += 1;
          }
        }
      }
    }
  }
}
