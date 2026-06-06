/// Shanten (向听数) Calculator — Dart implementation for client-side use.
///
/// Hand representation: 34-element list (0-8=Man, 9-17=Pin, 18-26=Sou, 27-33=Honors).

const terminalIndices = [0, 8, 9, 17, 18, 26, 27, 28, 29, 30, 31, 32, 33];

class ShantenCalculator {
  final List<int> tiles34;
  int _best = 999;

  ShantenCalculator(this.tiles34) : assert(tiles34.length == 34);

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

  int calculate() {
    _best = 999;

    // Chiitoitsu
    final pairs = tiles34.where((c) => c >= 2).length;
    _best = (_best < 6 - pairs) ? _best : 6 - pairs;

    // Kokushi
    final kokushi = _kokushiShanten();
    _best = (_best < kokushi) ? _best : kokushi;

    // Standard
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
    if (mentsu == 0 && jantou == 0) {
      _best = 0;
      return;
    }

    // Pair
    if (jantou == 1) {
      for (int i = 0; i < 34; i++) {
        if (tiles34[i] >= 2) {
          tiles34[i] -= 2;
          _searchMelds(mentsu, 0);
          tiles34[i] += 2;
        }
      }
    }

    // Triplet
    if (mentsu > 0) {
      for (int i = 0; i < 34; i++) {
        if (tiles34[i] >= 3) {
          tiles34[i] -= 3;
          _searchMelds(mentsu - 1, jantou);
          tiles34[i] += 3;
        }
      }

      // Sequence
      for (int i = 0; i < 27; i++) {
        if (i % 9 <= 6) {
          if (tiles34[i] > 0 && tiles34[i + 1] > 0 && tiles34[i + 2] > 0) {
            tiles34[i] -= 1;
            tiles34[i + 1] -= 1;
            tiles34[i + 2] -= 1;
            _searchMelds(mentsu - 1, jantou);
            tiles34[i] += 1;
            tiles34[i + 1] += 1;
            tiles34[i + 2] += 1;
          }
        }
      }
    }
  }
}
