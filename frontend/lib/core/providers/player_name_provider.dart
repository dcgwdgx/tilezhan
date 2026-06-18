/// 玩家显示名称管理 — 读写 StorageService 持久化。
///
/// 在排行榜上报和 My Rank 显示中使用。首次访问时若未设置，
/// 排行榜页面将弹出 BottomSheet 要求输入名字。
///
/// ## 使用示例
///
/// ```dart
/// final name = ref.watch(playerNameProvider);
/// final hasSetName = ref.watch(playerNameSetProvider);
/// ```
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';
import 'storage_provider.dart';

/// 玩家显示名称提供者，持久化到 [StorageService] 键 `player_name`。
///
/// 默认值为空字符串 `''`，表示玩家尚未设置名字。
final playerNameProvider = StateProvider<String>((ref) {
  final storage = ref.watch(storageServiceProvider).valueOrNull;
  return storage?.getString('player_name') ?? '';
});

/// 玩家是否已设置名字的标志提供者。
///
/// 衍生自 [playerNameProvider]，当名字非空时返回 `true`。
/// UI 层用于判断是否需要弹出名字输入框。
final playerNameSetProvider = Provider<bool>((ref) {
  return ref.watch(playerNameProvider).isNotEmpty;
});
