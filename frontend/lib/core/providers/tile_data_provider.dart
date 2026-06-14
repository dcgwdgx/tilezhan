/// 题库数据异步加载 Provider。
///
/// 提供两个核心 Provider：
/// - [tileRepositoryProvider]：单例 [TileRepository] 实例，负责数据访问。
/// - [tileDataProvider]：异步加载全部牌面数据，供 UI 层通过 `ref.watch` 订阅。
///
/// 加载失败时会自动抛出异常，UI 层可通过 `AsyncValue.error` 统一处理。
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/tile_model.dart';
import '../../shared/data/tile_repository.dart';

/// 提供 [TileRepository] 单例实例的 Provider。
///
/// 使用 `ref.read(tileRepositoryProvider)` 获取仓库实例以执行数据操作。
final tileRepositoryProvider = Provider<TileRepository>((ref) => TileRepository());

/// 异步加载全部牌面数据的 FutureProvider。
///
/// 依赖 [tileRepositoryProvider] 获取数据源，调用 [TileRepository.loadAllTiles]
/// 返回 `List<TileModel>`。UI 层使用 `ref.watch(tileDataProvider)` 即可获取
/// 加载状态（loading / error / data）。
final tileDataProvider = FutureProvider<List<TileModel>>((ref) async {
  return ref.read(tileRepositoryProvider).loadAllTiles();
});
