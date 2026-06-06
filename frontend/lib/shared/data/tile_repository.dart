import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/tile_model.dart';

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

  TileModel? getById(String id, List<TileModel> tiles) {
    try {
      return tiles.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

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
