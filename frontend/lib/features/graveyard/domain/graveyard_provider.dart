/// =============================================================================
/// 墓地（Graveyard）功能的 Riverpod Provider 定义
/// =============================================================================
///
/// "墓地"即"错题本"页面——用户在此复习所有麻将牌的待复习 SRS 条目，
/// 并通过雷达图查看各花色的错误率分析。
///
/// 本文件暴露两个 Provider：
/// - [graveyardDueProvider] —— 将每个待复习的 [SrsItem] 与其对应的 [TileModel]
///   配对，供墓地复习列表展示使用。
/// - [suitErrorRatesProvider] —— 按麻将花色（万、筒、索、风、龙）聚合错误率，
///   供雷达图展示使用。
///
/// 依赖说明：
/// - [dueItemsProvider]：来自 `srs_provider.dart`，提供所有到期待复习的 SRS 条目。
/// - [srsItemsProvider]：来自 `srs_provider.dart`，提供所有 SRS 条目的完整集合。
/// - [tileDataProvider]：来自 `tile_data_provider.dart`，提供所有麻将牌的元数据。
///
/// 注意：由于 [tileDataProvider] 是异步的，在数据尚未就绪时 [tilesAsync.valueOrNull]
/// 可能返回 null，此时两个 Provider 都会降级为空的 tiles 列表——调用方需自行处理
/// 数据加载中的过渡状态。
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/srs/srs_item.dart';
import '../../../core/srs/srs_provider.dart';
import '../../../core/providers/tile_data_provider.dart';
import '../../../shared/models/tile_model.dart';

/// -----------------------------------------------------------------------------
/// 墓地复习列表 Provider
/// -----------------------------------------------------------------------------
/// 将每个到期待复习的 [SrsItem] 与其对应的 [TileModel] 配对，生成供墓地
/// 复习列表渲染用的 `(SrsItem, TileModel?)` 元组列表。
///
/// 工作原理：
/// 1. 监听 [dueItemsProvider] 获取所有到期的 SRS 条目
/// 2. 监听 [tileDataProvider] 获取所有麻将牌的元数据
/// 3. 对每个到期条目，通过 `item.itemId == tile.id` 匹配对应的牌数据
/// 4. 若匹配不到牌（tile 为 null），说明该牌已被删除或数据异常——
///    调用方应妥善处理此情况（例如跳过该行，或显示占位符）
///
/// 性能考量：
/// - 当前实现使用线性搜索 `tiles.firstWhere`，时间复杂度 O(n*m)。
/// - 若条目数量增长到数百级，可考虑先将 tiles 转为 Map<int, TileModel>
///   实现 O(1) 查找。
///
/// 使用场景：
/// 墓地主列表页面的列表渲染——显示牌面图案、牌名、SRS 各项指标（间隔等级、
/// 错误次数、到期时间等）。
final graveyardDueProvider = Provider<List<(SrsItem, TileModel?)>>((ref) {
  // 获取所有到期待复习的 SRS 条目
  final dueItems = ref.watch(dueItemsProvider);

  // 获取牌数据（异步值，未加载完时为 null）
  final tilesAsync = ref.watch(tileDataProvider);

  // 降级处理：牌数据未就绪时使用空列表
  final tiles = tilesAsync.valueOrNull ?? [];

  // 结果列表：存储 (SRS条目, 匹配的牌数据或null) 元组
  final result = <(SrsItem, TileModel?)>[];

  // 遍历每个到期条目，逐一匹配对应的牌数据
  for (final item in dueItems) {
    TileModel? tile;
    try {
      // 通过 itemId 与 tile.id 进行匹配
      tile = tiles.firstWhere((t) => t.id == item.itemId);
    } catch (_) {
      // 匹配失败（牌已被删除或数据不一致）→ tile 保持 null
      tile = null;
    }
    result.add((item, tile));
  }

  return result;
});

/// -----------------------------------------------------------------------------
/// 花色错误率 Provider（雷达图数据源）
/// -----------------------------------------------------------------------------
/// 计算每个麻将花色的错误率，供墓地的雷达图可视化展示。
///
/// 花色分类（5 类，与雷达图的 5 个轴对应）：
/// - `man`（万）——万子牌
/// - `pin`（筒）——筒子牌
/// - `sou`（索）——索子牌
/// - `wind`（风）——风牌（东、南、西、北）
/// - `dragon`（龙）——龙牌（白、发、中）
///
/// 错误率计算公式：
/// ```
/// suitErrorRate = errorsBySuit[suit] / totalBySuit[suit]
/// ```
/// 其中分母为 `repetitions + 1`（避免除零）。分子为该花色下所有闪卡类型条目
/// 的累计错误次数。
///
/// 数据过滤：
/// - 仅统计 `type == 'flashcard'` 的 SRS 条目（闪卡模式，而非纯复习模式）
/// - 匹配不到对应 TileModel 的条目会被跳过（`continue`，不参与统计）
///
/// 返回值：
/// `Map<String, double>` —— 键为花色名（以上 5 种），值为 [0.0, ...] 范围的
/// 错误率。没有闪卡数据的花色默认返回 0.0。
///
/// 使用场景：
/// 墓地页面的雷达图组件——以五边形雷达图直观展示各花色的薄弱程度，
/// 帮助用户识别需要重点练习的花色。
final suitErrorRatesProvider = Provider<Map<String, double>>((ref) {
  // 获取所有 SRS 条目（不仅仅是到期的）
  final items = ref.watch(srsItemsProvider);

  // 获取牌数据
  final tilesAsync = ref.watch(tileDataProvider);

  // 降级处理：牌数据未就绪时使用空列表
  final tiles = tilesAsync.valueOrNull ?? [];

  // 按花色累计错误次数（分子）
  final errorsBySuit = <String, int>{};

  // 按花色累计总答题次数 = sum(repetitions + 1)（分母）
  final totalBySuit = <String, int>{};

  // 遍历所有 SRS 条目，统计花色维度的错误数据
  for (final item in items.values) {
    // 仅统计闪卡类型的条目
    if (item.type != 'flashcard') continue;

    // 匹配对应的牌数据，匹配不到则跳过该条目
    TileModel? tile;
    try {
      tile = tiles.firstWhere((t) => t.id == item.itemId);
    } catch (_) {
      continue;
    }

    // 获取花色名称（Suit 枚举的 name 属性）
    final suit = tile.suit.name;

    // 累加该花色的总答题次数（分母）
    totalBySuit[suit] = (totalBySuit[suit] ?? 0) + (item.reps + 1);

    // 累加该花色的错误次数（分子）
    errorsBySuit[suit] = (errorsBySuit[suit] ?? 0) + item.errors;
  }

  // 构建返回的 Map：5 个花色，每个花色对应一个计算好的错误率
  return {
    for (final s in ['man', 'pin', 'sou', 'wind', 'dragon'])
      s: totalBySuit.containsKey(s)                     // 该花色是否有闪卡数据？
          ? (errorsBySuit[s] ?? 0) / (totalBySuit[s] ?? 1) // 有数据：计算错误率
          : 0.0,                                        // 无数据：默认 0.0
  };
});
