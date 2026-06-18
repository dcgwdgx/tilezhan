/// 全局语言设置 — ChangeNotifier + Hive 持久化。
/// 不依赖 Riverpod，使用 Flutter 原生的 ListenableBuilder 触发重建。
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 支持的语言列表。
const supportedLanguages = [
  ('en', 'English'),
  ('fr', 'Français'),
  ('de', 'Deutsch'),
];

/// 全局语言模型 — ChangeNotifier 触发 UI 重建。
/// 在 main() 中读取 Hive 初始化，Settings 页调用 [switchTo] 切换。
class LocaleModel extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  /// 初始化：从 Hive 读取上次保存的语言。
  void init() {
    try {
      final lang = Hive.box('prefs').get('app_language', defaultValue: 'en');
      _locale = Locale(lang);
    } catch (_) {
      _locale = const Locale('en');
    }
  }

  /// 切换语言并通知 UI 重建。
  void switchTo(String langCode) {
    _locale = Locale(langCode);
    try {
      Hive.box('prefs').put('app_language', langCode);
    } catch (_) { /* 持久化失败不影响切换 */ }
    notifyListeners();
  }
}

/// 全局单例。
final localeModel = LocaleModel();
