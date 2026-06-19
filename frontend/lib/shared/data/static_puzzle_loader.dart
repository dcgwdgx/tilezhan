/// 静态何切题库加载器。
///
/// 从 `assets/data/nanikiru_puzzles.json` 加载手工设计的何切谜题，
/// 作为随机生成的补充。静态谜题按难度排序，调用方可根据目标难度
/// 选取最接近的题目。
import 'dart:convert';
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
    final jsonStr = await rootBundle.loadString('assets/data/nanikiru_puzzles.json');
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _cache = list.map((item) {
      final m = item as Map<String, dynamic>;
      return Puzzle(
        puzzleId: 'static_${list.indexOf(item)}',
        hand13Ids: List<String>.from(m['hand13Ids']),
        drawnTileId: m['drawnTileId'] as String,
        correctDiscardId: m['correctDiscardId'] as String,
        ukeireCount: m['ukeireCount'] as int,
        ukeireTypes: m['ukeireTypes'] as int,
        ukeireTileIds: List<String>.from(m['ukeireTileIds']),
        difficulty: m['difficulty'] as int,
      );
    }).toList();
    // 按难度升序排列，便于二分查找
    _cache!.sort((a, b) => a.difficulty.compareTo(b.difficulty));
    return _cache!;
  } catch (_) {
    _cache = [];
    return _cache!;
  }
}

/// 从静态题库中选取与 [targetDifficulty] 最接近的一道谜题。
///
/// 返回 `null` 表示静态题库为空（加载失败或未配置），
/// 调用方应回退到随机生成。
Future<Puzzle?> pickStaticPuzzle(int targetDifficulty) async {
  final puzzles = await loadStaticPuzzles();
  if (puzzles.isEmpty) return null;

  // 二分查找最接近 targetDifficulty 的谜题
  int lo = 0, hi = puzzles.length - 1;
  while (lo < hi) {
    final mid = (lo + hi) ~/ 2;
    if (puzzles[mid].difficulty < targetDifficulty) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  // 比较 lo 和 lo-1 哪个更接近
  if (lo > 0) {
    final dLo = (puzzles[lo].difficulty - targetDifficulty).abs();
    final dPrev = (puzzles[lo - 1].difficulty - targetDifficulty).abs();
    if (dPrev < dLo) lo = lo - 1;
  }
  return puzzles[lo];
}
