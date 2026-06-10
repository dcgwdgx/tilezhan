import 'package:hive_flutter/hive_flutter.dart';

/// Hive KV storage — puzzle cache, settings, user preferences.
/// Per design spec §2.3 Layer 2: 题库缓存 uses Hive.
class HiveService {
  static HiveService? _instance;
  static HiveService get instance =>
      _instance ?? (throw StateError('HiveService not initialized'));

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox('cache');
    await Hive.openBox('settings');
    _instance = HiveService();
  }

  Box get cacheBox => Hive.box('cache');
  Box get settingsBox => Hive.box('settings');

  T? get<T>(String key, {T? defaultValue}) =>
      settingsBox.get(key, defaultValue: defaultValue);
  Future<void> set(String key, dynamic value) =>
      settingsBox.put(key, value);

  dynamic getCached(String key) => cacheBox.get(key);
  Future<void> cache(String key, dynamic value) => cacheBox.put(key, value);
  Future<void> clearCache() => cacheBox.clear();
}
