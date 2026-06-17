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
  /// 内部缓存，存储从 JSON 解析后的 34 张牌全量列表。
  ///
  /// 为 `null` 表示尚未加载，首次调用 [loadAllTiles] 后填充，
  /// 后续调用直接返回缓存结果，避免重复读取 assets 和重复解析 JSON。
  List<TileModel>? _cache;

  /// 加载全部 34 张牌的数据，带内存缓存。
  ///
  /// 从捆绑资源 [assets/data/tiles.json] 读取 JSON，解析为 [TileModel] 列表。
  /// 首次调用执行 I/O 与 JSON 解析；其后直接从 [_cache] 返回，零开销。
  ///
  /// 返回的列表长度固定为 34，按 JSON 中的原始顺序排列。
  /// 若 assets 文件不存在或 JSON 格式错误，本方法会抛出异常（不吞错）。
  Future<List<TileModel>> loadAllTiles() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle.loadString('assets/data/tiles.json');
    final list = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
    _cache = list.map((j) => TileModel.fromJson(j)).toList();
    return _cache!;
  }

  /// 按牌的唯一标识 [id] 在 [tiles] 列表中精确查找一张牌。
  ///
  /// 使用 [Iterable.firstWhere] 进行线性扫描（列表仅 34 项，性能无虞）。
  /// 若 [tiles] 中不存在匹配的 [id]，捕获异常并返回 `null`，
  /// 不会向上抛出异常，调用方可安全判空。
  ///
  /// 典型调用场景：干扰项生成、按 ID 关联展示、测验答案校验。
  TileModel? getById(String id, List<TileModel> tiles) {
    try {
      return tiles.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 筛选 [tiles] 中所有花色为 [suit] 的牌，返回子列表。
  ///
  /// 按 [TileSuit] 枚举值精确匹配，返回的列表按 [tiles] 中原始顺序排列。
  /// 若 [tiles] 中没有对应花色的牌，返回空列表（不会返回 `null`）。
  ///
  /// 花色对应关系：万(tong/characters)、条(strings/bamboo)、
  /// 饼(balls/dots)、风(winds)、箭(dragons)、花(flowers)、季(seasons)。
  List<TileModel> getBySuit(TileSuit suit, List<TileModel> tiles) =>
      tiles.where((t) => t.suit == suit).toList();

  /// 为闪卡测验生成与正确答案 [correct] 相似的干扰项，数量为 [count]。
  ///
  /// 算法分三步：
  /// 1. **优先取"易混牌"** — 从 [correct.confusedWith] 指定的 ID 列表中
  ///    查找对应牌，这些是预设的最容易混淆的牌。
  /// 2. **随机补充其他牌** — 从剩余牌中（排除正确答案自身和已被步骤 1 选中的）
  ///    随机打乱，截取 `count * 2` 张作为候选池，确保有足够余地。
  /// 3. **合并并打乱** — 将易混牌与候选池合并后再次 [shuffle]，取前 [count] 张返回。
  ///
  /// 注意：
  /// - 返回的干扰项**不包含**正确答案 [correct] 自身。
  /// - 若 [allTiles] 总牌数不足 `count` 张，返回的实际数量可能少于 [count]。
  /// - [confusedWith] 中的 ID 若实际不存在，会被 [getById] 返回的 `null` 经
  ///   [whereType] 过滤掉，不会导致异常。
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
