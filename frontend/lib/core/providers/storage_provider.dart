/// 将 [StorageService] 暴露给 widget 树的 Riverpod Provider 定义。
///
/// 这些 Provider 异步处理存储初始化，使得依赖方（repository、view model、UI）
/// 可以直接访问存储层，而无需自行管理其生命周期。
///
/// ## 使用方式
///
/// ```dart
/// // 在 Widget 中读取
/// final storageAsync = ref.watch(storageServiceProvider);
/// storageAsync.when(
///   loading: () => const CircularProgressIndicator(),
///   error: (err, stack) => Text('初始化失败: $err'),
///   data: (storage) => YourWidget(storage: storage),
/// );
/// ```
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';

/// 异步创建并缓存 [StorageService] 实例的 [FutureProvider]。
///
/// 此 Provider 仅调用一次 [StorageService.init]，之后将初始化完成的
/// 存储服务实例提供给整个应用。因为它是 `FutureProvider`，消费者应使用
/// `ref.watch` 配合 `.when` / `.maybeWhen` 模式（或 `AsyncValue` 辅助方法）
/// 来处理加载态、数据态和错误态。
///
/// ## 注意事项
///
/// - 首次访问时触发初始化，结果被 Riverpod 自动缓存；
/// - 初始化失败时，错误会通过 `AsyncValue.error` 向上层传播；
/// - 不要在 `ref.read(storageServiceProvider)` 中同步解包 —— 它返回的是
///   `AsyncValue<StorageService>`，需要显式处理 `loading`/`error` 状态。
final storageServiceProvider = FutureProvider<StorageService>(
  (ref) => StorageService.init(),
);
