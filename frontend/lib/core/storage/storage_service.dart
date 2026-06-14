import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// StorageService — SharedPreferences-style KV persistence wrapper.
///
/// Stores simple key–value pairs (int, String) in a single `prefs.json` file,
/// and arbitrary JSON maps in per-key `{key}.json` files. Used for persisting
/// hearts, streak, SRS items, Elo rating, and other app settings.
///
/// Pure-Dart file-based persistence. No SPM/CocoaPods risk.
/// Uses path_provider for app directory access.
class StorageService {
  late final Directory _dir;
  bool _init = false;

  StorageService._();

  /// Initialises the storage service by resolving the app documents directory.
  ///
  /// On non-web platforms this uses [getApplicationDocumentsDirectory] from
  /// path_provider. Must be awaited before any read/write calls are made.
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

  /// Returns the int stored under [key], or `0` if not present.
  int getInt(String key) {
    final all = _readJson('prefs');
    return all[key] as int? ?? 0;
  }

  /// Persists an int [value] under [key] into the prefs store.
  Future<void> setInt(String key, int value) async {
    final all = _readJson('prefs');
    all[key] = value;
    await _writeJson('prefs', all);
  }

  /// Returns the String stored under [key], or `''` if not present.
  String getString(String key) {
    final all = _readJson('prefs');
    return all[key] as String? ?? '';
  }

  /// Persists a String [value] under [key] into the prefs store.
  Future<void> setString(String key, String value) async {
    final all = _readJson('prefs');
    all[key] = value;
    await _writeJson('prefs', all);
  }

  // ── JSON map ──

  /// Returns the full JSON map stored under [key], or `{}` if not present.
  /// Each key maps to its own `{key}.json` file on disk.
  Map<String, dynamic> getJson(String key) {
    return _readJson(key);
  }

  /// Writes a full JSON map [value] to its own `{key}.json` file on disk.
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await _writeJson(key, value);
  }

  // ── Internals ──

  /// Synchronous JSON read from `{key}.json`. Returns `{}` on any failure.
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

  /// Asynchronous JSON write to `{key}.json`. Silently swallows errors.
  Future<void> _writeJson(String key, Map<String, dynamic> value) async {
    if (!_init) return;
    try {
      final f = _file(key);
      await f.writeAsString(jsonEncode(value));
    } catch (_) {}
  }

  /// Key for the SRS items JSON store.
  static const kSrsItems = 'srs_items';
  /// Key for the hearts/energy state int store.
  static const kHearts = 'hearts';
  /// Key for the daily streak counter.
  static const kStreak = 'streak';
  /// Key for the Elo rating int store.
  static const kElo = 'elo';
}
