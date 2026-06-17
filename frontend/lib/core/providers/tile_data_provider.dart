/// 题库数据异步加载 Provider — TileZhan 数据层与 UI 层之间的 Riverpod 桥梁。
///
/// ## 架构角色
/// 本文件处于「数据层 → 状态层 → UI 层」的中间环节：
///   - 上游：依赖 [TileRepository]（assets/data/tiles.json → JSON 解析 → [TileModel]）
///   - 下游：被各页面/组件通过 `ref.watch` 订阅，驱动 UI 渲染
///
/// ## 提供的核心 Provider
/// 1. [tileRepositoryProvider] — 同步 Provider，提供 [TileRepository] 单例。
///    供需要直接调用仓库查询方法（如 [TileRepository.getById]、[TileRepository.getBySuit]）
///    的业务逻辑使用，通过 `ref.read` 获取实例。
///
/// 2. [tileDataProvider] — 异步 FutureProvider，加载全量 34 张牌数据。
///    Riverpod 将其包装为 [AsyncValue<List<TileModel>>]，UI 层通过 `ref.watch` 订阅，
///    自动响应 loading / data / error 三种状态，无需手动管理生命周期。
///
/// ## 加载时机与缓存
/// - [tileDataProvider] 在第一个 `ref.watch` 调用时触发加载（懒加载），
///   后续订阅者共享同一 Future，不会重复请求。
/// - [TileRepository] 内部维护 `_cache`，JSON 只解析一次；
///   即使 Provider 因 dispose 重建，再次调用 [loadAllTiles] 也直接命中缓存。
///
/// ## 错误处理
/// - JSON 解析失败时，[TileRepository.loadAllTiles] 抛出异常，
///   Riverpod 自动将其捕获为 `AsyncValue.error(error, stackTrace)`。
/// - UI 层应使用 `ref.watch(tileDataProvider).when(data: ..., loading: ..., error: ...)`
///   统一处理三种状态，避免裸 `try/catch`。
///
/// ## 自动释放
/// - 两个 Provider 均未设置 `keepAlive: true`，当所有监听者移除时自动 dispose，
///   释放内存。新监听者加入时重新创建 Provider。
///
/// ## 依赖关系图
/// ```
/// tileDataProvider ──依赖──▶ tileRepositoryProvider ──创建──▶ TileRepository
///                                               └──读取──▶ assets/data/tiles.json
/// ```
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/tile_model.dart';
import '../../shared/data/tile_repository.dart';

/// 提供 [TileRepository] 单例实例的同步 Provider。
///
/// ## 用途
/// 供业务逻辑层（ViewModel / Controller / Service）通过 `ref.read` 获取仓库实例，
/// 进而调用其查询方法：
/// - [TileRepository.getById] — 按 ID 精确查找某张牌
/// - [TileRepository.getBySuit] — 按花色过滤牌列表
/// - [TileRepository.getDistractors] — 为闪卡测验生成干扰项
///
/// ## 使用示例
/// ```dart
/// // 在另一个 Provider 或 WidgetRef 上下文中：
/// final repo = ref.read(tileRepositoryProvider);
/// final tile = repo.getById('man1', allTiles);
/// ```
///
/// ## 生命周期
/// - 首次 `ref.read` / `ref.watch` 时创建 [TileRepository] 实例。
/// - 所有监听者移除后自动 dispose，下一次访问重新创建（轻量操作，无副作用）。
/// - 如需跨页面保持实例不释放，可在 Provider 声明末尾追加 `; // keepAlive: true`。
///
/// ## 注意事项
/// - 此为同步 Provider，创建 [TileRepository] 本身不触发数据加载；
///   数据加载由下游 [tileDataProvider] 异步触发。
/// - 避免在 Widget build 方法中直接调用 `ref.read(tileRepositoryProvider).loadAllTiles()`，
///   应通过 `ref.watch(tileDataProvider)` 获取已加载的数据。
final tileRepositoryProvider = Provider<TileRepository>((ref) => TileRepository());

/// 异步加载全量 34 张麻雀牌数据的 FutureProvider。
///
/// ## 数据流
/// 1. 依赖注入：通过 [ref.read(tileRepositoryProvider)] 获取仓库实例（不订阅，避免循环依赖）。
/// 2. 触发加载：调用 [TileRepository.loadAllTiles]，内部从 `assets/data/tiles.json` 读取并解析 JSON。
/// 3. 缓存命中：如果 [TileRepository] 已缓存（同一 Provider 实例生命周期内），直接返回缓存数据。
/// 4. 状态暴露：Riverpod 将返回值包装为 [AsyncValue<List<TileModel>>]，
///    自动区分三种状态供 UI 消费。
///
/// ## UI 使用示例
/// ```dart
/// // 在 Widget build 中：
/// final tileAsync = ref.watch(tileDataProvider);
/// return tileAsync.when(
///   data: (tiles) => TileGridView(tiles: tiles),     // 加载成功 → 渲染牌阵
///   loading: () => const CircularProgressIndicator(), // 加载中 → 显示转圈
///   error: (e, st) => ErrorWidget(e.toString()),     // 加载失败 → 错误提示
/// );
/// ```
///
/// ## 三种 AsyncValue 状态
/// | 状态      | 触发条件                         | UI 处理建议                |
/// |-----------|----------------------------------|---------------------------|
/// | loading   | 首次加载中 / [ref.invalidate] 后 | 骨架屏 / 加载动画         |
/// | data      | `loadAllTiles` 成功返回          | 渲染牌面列表 / 网格       |
/// | error     | JSON 解析失败 / 文件缺失 / 异常  | 错误提示 + 重试按钮       |
///
/// ## 依赖关系
/// - 依赖 [tileRepositoryProvider]，但使用 `ref.read`（非 `ref.watch`），
///   因此 [tileRepositoryProvider] 的重建**不会**触发本 Provider 重新加载。
/// - 需要强制重新加载时，应调用 `ref.invalidate(tileDataProvider)`。
///
/// ## 自动释放
/// - 未设置 `keepAlive: true`，所有监听 Widget 卸载后自动 dispose。
/// - dispose 后 [TileRepository] 的 `_cache` 仍在堆内存中（只要 [tileRepositoryProvider] 未被同时 dispose）；
///   如果两者都被 dispose，下次访问会重新加载 JSON 并重建缓存。
///
/// ## 性能说明
/// - 34 张牌的数据量极小（约 5–10 KB），加载耗时通常在 50 ms 以内。
/// - 若未来牌数据量增大，可考虑将 [TileRepository.loadAllTiles] 改为分批加载或增加加载进度回调。
final tileDataProvider = FutureProvider<List<TileModel>>((ref) async {
  // 通过 ref.read 获取仓库实例（只读不订阅，避免不必要的重建）
  // 使用 ref.read 而非 ref.watch 的原因：
  //   tileRepositoryProvider 是同步 Provider 且值永不变化（同一个 TileRepository 实例），
  //   订阅它没有意义，反而会增加不必要的依赖图复杂度
  return ref.read(tileRepositoryProvider).loadAllTiles();
});
