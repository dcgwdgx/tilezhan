/// 役种收藏状态管理 — StateNotifier + Hive 持久化。
///
/// 管理用户收藏的役种 ID 集合，支持星标切换和跨重启持久化。
/// 通过 [yakuFavoritesProvider] 暴露给 UI 层监听状态变化。
///
/// ## 使用示例
///
/// ```dart
/// // 读取收藏状态
/// final favorites = ref.watch(yakuFavoritesProvider);
/// final isFav = favorites.contains('riichi');
///
/// // 切换收藏
/// ref.read(yakuFavoritesProvider.notifier).toggle('riichi');
/// ```
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 全局役种收藏状态提供者。
///
/// 自动释放以节省内存，当所有监听者取消订阅时销毁实例。
/// 每次状态变更自动写回 Hive Box `yaku_favorites`。
final yakuFavoritesProvider =
    StateNotifierProvider<YakuFavoritesNotifier, Set<String>>(
      (ref) => YakuFavoritesNotifier(),
    );

/// 管理收藏役种 ID 集合的状态通知器。
///
/// ## 持久化设计
///
/// - 存储于 Hive Box `yaku_favorites`，键名 `ids`
/// - 保存格式：`List<String>` → 读取后转为 `Set<String>`
/// - 每次 [toggle] 操作后自动写回磁盘
///
/// ## 初始化
///
/// 构造时从 Hive 懒加载已有收藏列表。若 Box 不存在或读取失败，
/// 静默降级为空集合——不影响正常使用，下次收藏操作会创建新 Box。
class YakuFavoritesNotifier extends StateNotifier<Set<String>> {
  static const _boxName = 'yaku_favorites';
  static const _key = 'ids';

  YakuFavoritesNotifier() : super({}) {
    _load();
  }

  /// 从 Hive 加载已保存的收藏 ID 列表。
  ///
  /// 如果 Box 尚未打开（[main] 中未调用 [Hive.openBox]），
  /// 或读取的 key 不存在，返回空集合。
  void _load() {
    try {
      final box = Hive.box(_boxName);
      final list = box.get(_key, defaultValue: <dynamic>[]);
      state = List<String>.from(list).toSet();
    } catch (_) {
      state = {};
    }
  }

  /// 将当前收藏集合持久化到 Hive。
  ///
  /// 失败时静默忽略——下次读取回退到上一次成功写入的状态，
  /// 不影响收藏操作的 UI 反馈（状态已在内存中更新）。
  void _persist() {
    try {
      Hive.box(_boxName).put(_key, state.toList());
    } catch (_) {
      // I/O 错误静默忽略，内存状态不受影响
    }
  }

  /// 判断某个役种 ID 是否已被收藏。
  ///
  /// [yakuId] 役种唯一标识，如 `'riichi'`、`'daisangen'`。
  /// 返回 `true` 表示已收藏，UI 层应显示实心星标。
  bool isFavorite(String yakuId) => state.contains(yakuId);

  /// 切换收藏状态：已收藏 → 取消，未收藏 → 添加。
  ///
  /// [yakuId] 役种唯一标识。
  ///
  /// 立即更新内存状态并触发 UI 重建，随后异步写回 Hive。
  void toggle(String yakuId) {
    final updated = Set<String>.from(state);
    if (updated.contains(yakuId)) {
      updated.remove(yakuId);
    } else {
      updated.add(yakuId);
    }
    state = updated;
    _persist();
  }
}
