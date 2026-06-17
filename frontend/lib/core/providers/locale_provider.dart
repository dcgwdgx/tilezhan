/// 应用语言设置的 Riverpod Provider。
/// 存储在 Hive 'prefs' Box 中，重启后保持选择。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 支持的语言列表，供设置页下拉选择。
const supportedLanguages = [
  ('en', 'English'),
  ('fr', 'Français'),
  ('de', 'Deutsch'),
];

/// 当前选择的 [Locale]。从 Hive 读取，默认英语。
final localeProvider = StateProvider<Locale>((ref) {
  final box = Hive.box('prefs');
  final lang = box.get('app_language', defaultValue: 'en');
  return Locale(lang);
});

/// 切换语言并持久化到 Hive。
void setAppLocale(WidgetRef ref, String langCode) {
  Hive.box('prefs').put('app_language', langCode);
  ref.read(localeProvider.notifier).state = Locale(langCode);
}
