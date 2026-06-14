/// HiveService NoSQL 本地存储 — Box 管理/缓存/批量读写.
///
/// 基于 [Hive](https://docs.hivedb.dev/) 的轻量级键值存储服务，提供两个独立 Box:
/// - `cache`: 题库缓存、临时数据，支持批量清空
/// - `settings`: 用户偏好、应用配置，持久化存储
///
/// 使用前必须调用 [HiveService.init] 初始化。
import 'package:hive_flutter/hive_flutter.dart';

/// 基于 Hive 的本地持久化服务，管理 `cache` 与 `settings` 两个 Box。
///
/// 单例模式 — 通过 [HiveService.instance] 访问：
/// ```dart
/// final hive = HiveService.instance;
/// hive.set('theme', 'dark');
/// final theme = hive.get<String>('theme');
/// ```
class HiveService {
  static HiveService? _instance;

  /// 全局单例访问器。
  ///
  /// 需先调用 [HiveService.init] 完成初始化，否则抛出 [StateError]。
  static HiveService get instance =>
      _instance ?? (throw StateError('HiveService not initialized'));

  /// 初始化 Hive 引擎并打开 `cache` 与 `settings` 两个 Box。
  ///
  /// 应在 `main()` 中 `WidgetsFlutterBinding.ensureInitialized()` 之后调用。
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox('cache');
    await Hive.openBox('settings');
    _instance = HiveService();
  }

  /// 缓存 Box，用于存储题库数据、临时计算结果等可丢弃内容。
  Box get cacheBox => Hive.box('cache');

  /// 设置 Box，用于存储用户偏好、应用配置等需持久化的键值对。
  Box get settingsBox => Hive.box('settings');

  /// 从 [settingsBox] 读取指定 [key] 的值。
  ///
  /// 若键不存在返回 [defaultValue]，类型参数 `T` 控制返回类型。
  T? get<T>(String key, {T? defaultValue}) =>
      settingsBox.get(key, defaultValue: defaultValue);

  /// 向 [settingsBox] 写入键值对。
  Future<void> set(String key, dynamic value) =>
      settingsBox.put(key, value);

  /// 从 [cacheBox] 读取缓存的原始数据（无类型约束）。
  dynamic getCached(String key) => cacheBox.get(key);

  /// 向 [cacheBox] 写入缓存数据。
  Future<void> cache(String key, dynamic value) => cacheBox.put(key, value);

  /// 清空 [cacheBox] 中的所有缓存条目。
  Future<void> clearCache() => cacheBox.clear();
}
