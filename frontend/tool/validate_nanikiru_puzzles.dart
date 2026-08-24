import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:tilezhan/features/nanikiru/domain/puzzle_generator.dart';
import 'package:tilezhan/features/nanikiru/domain/difficulty_scorer.dart';
import 'package:tilezhan/features/nanikiru/domain/nanikiru_teaching_analysis.dart';
import 'package:tilezhan/shared/engine/ukeire_calculator.dart';
import 'package:tilezhan/shared/models/puzzle_model.dart';

const _catalogPath = 'assets/data/nanikiru_puzzles.json';
const _targetCatalogSize = 80;

void main(List<String> arguments) {
  final rebuild = arguments.contains('--rebuild');
  final rewrite = rebuild || arguments.contains('--rewrite');
  final file = File(_catalogPath);
  final raw = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  final retained = <Map<String, dynamic>>[];
  var ambiguous = 0;
  var incorrectAnswer = 0;
  var correctedMetadata = 0;
  var invalid = 0;

  for (var index = 0; index < raw.length; index++) {
    final source = Map<String, dynamic>.from(raw[index] as Map);
    try {
      final hand13 = List<String>.from(source['hand13Ids'] as List);
      final drawn = source['drawnTileId'] as String;
      final suppliedAnswer = source['correctDiscardId'] as String;
      final hand14 = [...hand13, drawn];
      if (hand13.length != 13 || !hand14.contains(suppliedAnswer)) {
        throw const FormatException('Invalid hand or answer shape');
      }

      final results = UkeireCalculator(hand14).calculate();
      final bestShanten =
          results.values.map((result) => result.shantenAfter).reduce(min);
      final bestUkeire = results.values
          .where((result) => result.shantenAfter == bestShanten)
          .map((result) => result.ukeireCount)
          .reduce(max);
      final winners = results.entries
          .where((entry) =>
              entry.value.shantenAfter == bestShanten &&
              entry.value.ukeireCount == bestUkeire)
          .toList();

      if (winners.length != 1) {
        ambiguous++;
        stdout.writeln(
          'AMBIGUOUS #$index ${winners.map((entry) => entry.key).join(',')}',
        );
        continue;
      }

      final winner = winners.single;
      if (winner.key != suppliedAnswer) {
        incorrectAnswer++;
        stdout.writeln(
          'WRONG #$index supplied=$suppliedAnswer actual=${winner.key}',
        );
        continue;
      }

      final suppliedTiles = List<String>.from(source['ukeireTileIds'] as List);
      final verifiedPuzzle = Puzzle(
        puzzleId: 'static_$index',
        hand13Ids: hand13,
        drawnTileId: drawn,
        correctDiscardId: winner.key,
        ukeireCount: winner.value.ukeireCount,
        ukeireTypes: winner.value.ukeireTypes.length,
        ukeireTileIds: winner.value.ukeireTypes,
        difficulty: source['difficulty'] as int? ?? 1000,
      );
      final expectedDifficulty = DifficultyScorer.score(
        verifiedPuzzle,
        discardResults: results,
      );
      final metadataMatches =
          source['ukeireCount'] == winner.value.ukeireCount &&
              source['ukeireTypes'] == winner.value.ukeireTypes.length &&
              _sameItems(suppliedTiles, winner.value.ukeireTypes) &&
              source['difficulty'] == expectedDifficulty;
      if (!metadataMatches) {
        correctedMetadata++;
        stdout.writeln(
          'METADATA #$index answer=${winner.key} '
          'types=${winner.value.ukeireTypes.join(',')} '
          'count=${winner.value.ukeireCount} '
          'difficulty=$expectedDifficulty',
        );
      }

      source['ukeireCount'] = winner.value.ukeireCount;
      source['ukeireTypes'] = winner.value.ukeireTypes.length;
      source['ukeireTileIds'] = winner.value.ukeireTypes;
      source['difficulty'] = expectedDifficulty;
      if (rebuild && !source.containsKey('hint')) continue;
      retained.add(source);
    } on Object catch (error) {
      invalid++;
      stdout.writeln('INVALID #$index $error');
    }
  }

  stdout.writeln(
    'SUMMARY total=${raw.length} retained=${retained.length} '
    'ambiguous=$ambiguous incorrect=$incorrectAnswer '
    'metadata=$correctedMetadata invalid=$invalid',
  );

  final coverageValid = _printCoverage(retained);

  if (rewrite) {
    _fillCatalog(retained);
    const encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync('${encoder.convert(retained)}\n');
    stdout.writeln(
        'REWROTE $_catalogPath with ${retained.length} verified puzzles');
    return;
  }

  if (ambiguous > 0 ||
      incorrectAnswer > 0 ||
      correctedMetadata > 0 ||
      invalid > 0 ||
      !coverageValid) {
    exitCode = 1;
  }
}

void _fillCatalog(List<Map<String, dynamic>> retained) {
  final seen = retained.map(_contentKey).toSet();
  _addStructuredEasyPuzzles(retained, seen);
  if (retained.length < _targetCatalogSize) {
    _addSemanticCoveragePuzzles(retained, seen);
  }

  for (var seed = 1;
      retained.length < _targetCatalogSize && seed <= 5000;
      seed++) {
    final targetDifficulty = 800 + ((retained.length * 97) % 801);
    final puzzle = PuzzleGenerator.generate(
      targetDifficulty: targetDifficulty,
      random: Random(0x5A17E + seed),
      maxAttempts: 30,
    );
    final map = _puzzleToJson(puzzle);
    if (!seen.add(_contentKey(map))) continue;
    retained.add(map);
    stdout.writeln(
      'GENERATED ${retained.length}/$_targetCatalogSize '
      'difficulty=${puzzle.difficulty}',
    );
  }

  if (retained.length != _targetCatalogSize) {
    throw StateError(
      'Could only build ${retained.length} unique verified puzzles',
    );
  }
  if (!_hasRequiredCoverage(retained)) {
    throw StateError('Generated catalog does not cover all ELO bands');
  }
  if (!_hasRequiredSemanticCoverage(retained)) {
    throw StateError('Generated catalog does not cover all teaching topics');
  }
}

/// Adds engine-verified, uniquely answered anchors for the three semantic
/// topics that ordinary random generation rarely reaches. Metadata is always
/// recomputed through [_verifiedPuzzle], so these are hand templates rather
/// than trusted answer fixtures.
void _addSemanticCoveragePuzzles(
  List<Map<String, dynamic>> retained,
  Set<String> seen,
) {
  const hands = <List<String>>[
    // General efficiency: discard the duplicate 1p to preserve the stronger
    // m34/m45 shape; the optimal tile is neither isolated nor pair-protection.
    [
      'z1',
      'z1',
      'p1',
      'p2',
      'p3',
      's1',
      's2',
      's3',
      'm1',
      'm2',
      'm3',
      'm4',
      'm5',
      'p1',
    ],
    // Chiitoitsu remains live alongside ordinary shapes.
    [
      'm9',
      'm4',
      'm3',
      'p6',
      'm5',
      'm6',
      'p6',
      'm9',
      'm3',
      'p7',
      'p5',
      'm5',
      'p5',
      's4',
    ],
    // Twelve orphan kinds plus a pair make the lone simple tile the unique
    // discard while teaching the missing z7 wait.
    [
      'm1',
      'm1',
      'm9',
      'p1',
      'p9',
      's1',
      's9',
      'z1',
      'z2',
      'z3',
      'z4',
      'z5',
      'z6',
      'm5',
    ],
  ];

  for (final hand14 in hands) {
    if (retained.length >= _targetCatalogSize) return;
    final puzzle = _verifiedPuzzle(
      hand14.take(13).toList(),
      hand14.last,
      'semantic_${retained.length}',
    );
    if (puzzle == null) {
      throw StateError('Semantic template has no unique engine answer');
    }
    final map = _puzzleToJson(puzzle);
    if (seen.add(_contentKey(map))) retained.add(map);
  }
}

void _addStructuredEasyPuzzles(
  List<Map<String, dynamic>> retained,
  Set<String> seen,
) {
  const suits = ['m', 'p', 's'];
  for (final meldSuit in suits) {
    for (final waitSuit in suits.where((suit) => suit != meldSuit)) {
      for (var meldStart = 1; meldStart <= 4; meldStart++) {
        for (var waitStart = 1; waitStart <= 5; waitStart++) {
          for (var pairHonor = 1; pairHonor <= 7; pairHonor++) {
            final isolatedHonor = pairHonor == 7 ? 1 : pairHonor + 1;
            final hand13 = <String>[
              for (var rank = meldStart; rank < meldStart + 6; rank++)
                '$meldSuit$rank',
              for (var rank = waitStart; rank < waitStart + 5; rank++)
                '$waitSuit$rank',
              'z$pairHonor',
              'z$pairHonor',
            ];
            final puzzle = _verifiedPuzzle(
              hand13,
              'z$isolatedHonor',
              'structured_${retained.length}',
            );
            if (puzzle == null || puzzle.difficulty > 1099) continue;
            final map = _puzzleToJson(puzzle);
            if (!seen.add(_contentKey(map))) continue;
            retained.add(map);
            if (_bandCounts(retained).easy >= 20) return;
          }
        }
      }
    }
  }
}

Puzzle? _verifiedPuzzle(
  List<String> hand13,
  String drawn,
  String puzzleId,
) {
  final results = UkeireCalculator([...hand13, drawn]).calculate();
  final bestShanten =
      results.values.map((result) => result.shantenAfter).reduce(min);
  final bestUkeire = results.values
      .where((result) => result.shantenAfter == bestShanten)
      .map((result) => result.ukeireCount)
      .reduce(max);
  final winners = results.entries
      .where((entry) =>
          entry.value.shantenAfter == bestShanten &&
          entry.value.ukeireCount == bestUkeire)
      .toList();
  if (winners.length != 1) return null;

  final winner = winners.single;
  final provisional = Puzzle(
    puzzleId: puzzleId,
    hand13Ids: hand13,
    drawnTileId: drawn,
    correctDiscardId: winner.key,
    ukeireCount: winner.value.ukeireCount,
    ukeireTypes: winner.value.ukeireTypes.length,
    ukeireTileIds: winner.value.ukeireTypes,
    difficulty: 0,
  );
  return Puzzle(
    puzzleId: puzzleId,
    hand13Ids: hand13,
    drawnTileId: drawn,
    correctDiscardId: winner.key,
    ukeireCount: winner.value.ukeireCount,
    ukeireTypes: winner.value.ukeireTypes.length,
    ukeireTileIds: winner.value.ukeireTypes,
    difficulty: DifficultyScorer.score(
      provisional,
      discardResults: results,
    ),
  );
}

Map<String, dynamic> _puzzleToJson(Puzzle puzzle) => {
      'hand13Ids': puzzle.hand13Ids,
      'drawnTileId': puzzle.drawnTileId,
      'correctDiscardId': puzzle.correctDiscardId,
      'ukeireCount': puzzle.ukeireCount,
      'ukeireTypes': puzzle.ukeireTypes,
      'ukeireTileIds': puzzle.ukeireTileIds,
      'difficulty': puzzle.difficulty,
    };

String _contentKey(Map<String, dynamic> puzzle) {
  final hand = [
    ...List<String>.from(puzzle['hand13Ids'] as List),
    puzzle['drawnTileId'] as String,
  ]..sort();
  return hand.join(',');
}

({int easy, int medium, int hard}) _bandCounts(
  List<Map<String, dynamic>> puzzles,
) {
  var easy = 0;
  var medium = 0;
  var hard = 0;
  for (final puzzle in puzzles) {
    final difficulty = puzzle['difficulty'] as int;
    if (difficulty <= 1099) {
      easy++;
    } else if (difficulty <= 1299) {
      medium++;
    } else {
      hard++;
    }
  }
  return (easy: easy, medium: medium, hard: hard);
}

bool _hasRequiredCoverage(List<Map<String, dynamic>> puzzles) {
  final counts = _bandCounts(puzzles);
  return counts.easy >= 16 && counts.medium >= 20 && counts.hard >= 16;
}

bool _hasRequiredSemanticCoverage(List<Map<String, dynamic>> puzzles) {
  final represented = <NanikiruTeachingTag>{};
  for (final puzzle in puzzles) {
    final hand14 = [
      ...List<String>.from(puzzle['hand13Ids'] as List),
      puzzle['drawnTileId'] as String,
    ];
    represented.addAll(
      NanikiruTeachingAnalyzer.analyze(
        hand14: hand14,
        selectedDiscardId: null,
        results: UkeireCalculator(hand14).calculate(),
      ).optimalTags,
    );
  }
  return represented.containsAll(NanikiruTeachingTag.values);
}

bool _printCoverage(List<Map<String, dynamic>> puzzles) {
  final counts = _bandCounts(puzzles);
  final bandValid = _hasRequiredCoverage(puzzles);
  final semanticValid = _hasRequiredSemanticCoverage(puzzles);
  stdout.writeln(
    'COVERAGE easy=${counts.easy} medium=${counts.medium} '
    'hard=${counts.hard} bands=$bandValid semantic=$semanticValid',
  );
  return bandValid && semanticValid;
}

bool _sameItems(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  return left.toSet().containsAll(right) && right.toSet().containsAll(left);
}
