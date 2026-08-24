import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/shared/data/static_puzzle_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the complete verified catalog sorted by difficulty', () async {
    final puzzles = await loadStaticPuzzles();

    expect(puzzles, hasLength(80));
    for (var index = 1; index < puzzles.length; index++) {
      expect(
        puzzles[index].difficulty,
        greaterThanOrEqualTo(puzzles[index - 1].difficulty),
      );
    }

    expect(identical(puzzles, await loadStaticPuzzles()), isTrue);
    expect(() => puzzles.clear(), throwsUnsupportedError);
    expect(() => puzzles.first.hand13Ids.clear(), throwsUnsupportedError);
    expect(() => puzzles.first.ukeireTileIds.clear(), throwsUnsupportedError);
  });

  test('skips one malformed entry while retaining valid entries', () {
    final catalog = jsonEncode([
      _puzzleJson(difficulty: 1200),
      _puzzleJson(hand13Ids: const ['m1']),
      _puzzleJson(difficulty: 800, correctDiscardId: 'z2'),
    ]);

    final puzzles = parseStaticPuzzlesForTest(catalog);

    expect(puzzles, hasLength(2));
    expect(
      puzzles.map((puzzle) => puzzle.puzzleId),
      orderedEquals(['static_2', 'static_0']),
    );
    expect(() => puzzles.add(puzzles.first), throwsUnsupportedError);
    expect(() => puzzles.first.hand13Ids.add('z3'), throwsUnsupportedError);
  });

  test('recent exclusions prevent immediate puzzle repetition', () async {
    final first = await pickStaticPuzzle(1000, random: Random(42));
    final second = await pickStaticPuzzle(
      1000,
      random: Random(42),
      excludedPuzzleIds: {first!.puzzleId},
    );

    expect(second, isNotNull);
    expect(second!.puzzleId, isNot(first.puzzleId));
  });
}

Map<String, Object> _puzzleJson({
  List<String> hand13Ids = const [
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
  String correctDiscardId = 'z2',
  int difficulty = 1000,
}) =>
    {
      'hand13Ids': hand13Ids,
      'drawnTileId': 'z2',
      'correctDiscardId': correctDiscardId,
      'ukeireCount': 7,
      'ukeireTypes': 2,
      'ukeireTileIds': const ['p4', 'p7'],
      'difficulty': difficulty,
    };
