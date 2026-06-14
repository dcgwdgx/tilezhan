/// 牌库仓库 — 34牌加载、查询与过滤。
///
/// 从捆绑的 [assets/data/tiles.json] 加载全量 34 张牌数据，
/// 提供按 ID 查找、按花色筛选、以及为闪卡测验生成干扰项等查询能力。
/// 内部维护缓存，避免重复解析 JSON。
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/tile_model.dart';

/// 34 牌牌的仓库，负责加载、缓存与查询牌数据。
///
/// 用法：先调用 [loadAllTiles] 获取全量列表，再将其传入 [getById]、
/// [getBySuit]、[getDistractors] 等查询方法。缓存机制确保 JSON 只解析一次。
class TileRepository {
  List<TileModel>? _cache;

  /// Load all 34 tiles from bundled JSON
  Future<List<TileModel>> loadAllTiles() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle.loadString('assets/data/tiles.json');
    final list = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
    _cache = list.map((j) => TileModel.fromJson(j)).toList();
    return _cache!;
  }

  /// 按 [id] 从 [tiles] 列表中查找单张牌，找不到返回 `null`。
  TileModel? getById(String id, List<TileModel> tiles) {
    try {
      return tiles.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 返回 [tiles] 中所有属于指定 [suit] 花色的牌。
  List<TileModel> getBySuit(TileSuit suit, List<TileModel> tiles) =>
      tiles.where((t) => t.suit == suit).toList();

  /// Get distractor tiles for flashcard quiz (prefers confused_with)
  List<TileModel> getDistractors(
      TileModel correct, List<TileModel> allTiles, int count) {
    final confused = correct.confusedWith
        .map((id) => getById(id, allTiles))
        .whereType<TileModel>()
        .toList();
    final others = allTiles
        .where((t) => t.id != correct.id && !correct.confusedWith.contains(t.id))
        .toList();
    others.shuffle();
    final candidates = [...confused, ...others.take(count * 2)];
    candidates.shuffle();
    return candidates.take(count).toList();
  }
}
