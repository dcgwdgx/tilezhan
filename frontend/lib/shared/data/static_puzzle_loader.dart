/// 静态何切题库加载器。
///
/// 从 `assets/data/nanikiru_puzzles.json` 加载手工设计的何切谜题，
/// 作为随机生成的补充。静态谜题按难度排序，调用方可根据目标难度
/// 选取最接近的题目。
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/puzzle_model.dart';

/// 静态题库缓存（首次加载后复用，避免重复读取 assets）。
List<Puzzle>? _cache;

/// 从 assets 加载静态何切题库。
///
/// 首次调用时读取 JSON 并缓存为 [Puzzle] 列表，后续调用直接返回缓存。
/// 加载失败（文件不存在、格式错误等）返回空列表并缓存，避免反复尝试。
Future<List<Puzzle>> loadStaticPuzzles() async {
  if (_cache != null) return _cache!;

  try {
    final jsonStr =
        await rootBundle.loadString('assets/data/nanikiru_puzzles.json');
    _cache = _parseStaticPuzzles(jsonStr);
    return _cache!;
  } catch (error, stackTrace) {
    developer.log(
      'Failed to load the Nanikiru puzzle catalog',
      name: 'tilezhan.static_puzzle_loader',
      error: error,
      stackTrace: stackTrace,
    );
    _cache = List<Puzzle>.unmodifiable(const <Puzzle>[]);
    return _cache!;
  }
}

/// Parses a static puzzle catalog while skipping malformed individual entries.
///
/// Exposed only so unit tests can cover partial-catalog recovery without
/// replacing Flutter's root asset bundle.
@visibleForTesting
List<Puzzle> parseStaticPuzzlesForTest(String jsonStr) =>
    _parseStaticPuzzles(jsonStr);

List<Puzzle> _parseStaticPuzzles(String jsonStr) {
  final decoded = jsonDecode(jsonStr);
  if (decoded is! List<dynamic>) {
    throw const FormatException('Nanikiru puzzle catalog must be a JSON list');
  }

  final puzzles = <Puzzle>[];
  for (final entry in decoded.asMap().entries) {
    try {
      final value = entry.value;
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Puzzle entry must be a JSON object');
      }

      final hand13Ids = _readStringList(value, 'hand13Ids');
      final drawnTileId = value['drawnTileId'] as String;
      final correctDiscardId = value['correctDiscardId'] as String;
      final ukeireTileIds = _readStringList(value, 'ukeireTileIds');
      final ukeireTypes = value['ukeireTypes'] as int;
      if (hand13Ids.length != 13 ||
          ![...hand13Ids, drawnTileId].contains(correctDiscardId) ||
          ukeireTypes != ukeireTileIds.length) {
        throw const FormatException('Puzzle entry violates catalog invariants');
      }

      puzzles.add(
        Puzzle(
          puzzleId: 'static_${entry.key}',
          hand13Ids: hand13Ids,
          drawnTileId: drawnTileId,
          correctDiscardId: correctDiscardId,
          ukeireCount: value['ukeireCount'] as int,
          ukeireTypes: ukeireTypes,
          ukeireTileIds: ukeireTileIds,
          difficulty: value['difficulty'] as int,
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Skipping invalid Nanikiru puzzle at index ${entry.key}',
        name: 'tilezhan.static_puzzle_loader',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  puzzles.sort((a, b) => a.difficulty.compareTo(b.difficulty));
  return List<Puzzle>.unmodifiable(puzzles);
}

List<String> _readStringList(Map<String, dynamic> value, String key) {
  final items = value[key];
  if (items is! List<dynamic> || items.any((item) => item is! String)) {
    throw FormatException('$key must be a list of strings');
  }
  return List<String>.unmodifiable(items.cast<String>());
}

/// 从静态题库中选取与 [targetDifficulty] 最接近的一道谜题。
///
/// 返回 `null` 表示静态题库为空（加载失败或未配置），
/// 调用方应回退到随机生成。
Future<Puzzle?> pickStaticPuzzle(
  int targetDifficulty, {
  Set<String> excludedPuzzleIds = const {},
  Random? random,
}) async {
  final puzzles = await loadStaticPuzzles();
  if (puzzles.isEmpty) return null;

  var candidates = puzzles
      .where((puzzle) => !excludedPuzzleIds.contains(puzzle.puzzleId))
      .toList();
  if (candidates.isEmpty) candidates = List<Puzzle>.from(puzzles);

  candidates.sort((left, right) {
    final leftDistance = (left.difficulty - targetDifficulty).abs();
    final rightDistance = (right.difficulty - targetDifficulty).abs();
    final byDistance = leftDistance.compareTo(rightDistance);
    return byDistance != 0
        ? byDistance
        : left.puzzleId.compareTo(right.puzzleId);
  });

  // Randomize among the nearest verified questions so the same ELO does not
  // repeatedly receive one identical hand.
  final nearest = candidates.take(min(8, candidates.length)).toList();
  return nearest[(random ?? Random()).nextInt(nearest.length)];
}
