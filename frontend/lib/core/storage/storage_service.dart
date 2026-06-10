import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// Pure-Dart file-based persistence. No SPM/CocoaPods risk.
/// Uses path_provider for app directory access.
class StorageService {
  late final Directory _dir;
  bool _init = false;

  StorageService._();

  static Future<StorageService> init() async {
    final s = StorageService._();
    if (!kIsWeb) {
      s._dir = await getApplicationDocumentsDirectory();
    }
    s._init = true;
    return s;
  }

  File _file(String key) => File('${_dir.path}/$key.json');

  // ── Simple values (stored in a single prefs.json) ──

  int getInt(String key) {
    final all = _readJson('prefs');
    return all[key] as int? ?? 0;
  }

  Future<void> setInt(String key, int value) async {
    final all = _readJson('prefs');
    all[key] = value;
    await _writeJson('prefs', all);
  }

  String getString(String key) {
    final all = _readJson('prefs');
    return all[key] as String? ?? '';
  }

  Future<void> setString(String key, String value) async {
    final all = _readJson('prefs');
    all[key] = value;
    await _writeJson('prefs', all);
  }

  // ── JSON map ──

  Map<String, dynamic> getJson(String key) {
    return _readJson(key);
  }

  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await _writeJson(key, value);
  }

  // ── Internals ──

  Map<String, dynamic> _readJson(String key) {
    if (!_init) return {};
    try {
      final f = _file(key);
      if (!f.existsSync()) return {};
      return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeJson(String key, Map<String, dynamic> value) async {
    if (!_init) return;
    try {
      final f = _file(key);
      await f.writeAsString(jsonEncode(value));
    } catch (_) {}
  }

  static const kSrsItems = 'srs_items';
  static const kHearts = 'hearts';
  static const kStreak = 'streak';
  static const kElo = 'elo';
}
