import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;
  StorageService._(this._prefs);

  static Future<StorageService> init() async {
    return StorageService._(await SharedPreferences.getInstance());
  }

  int getInt(String k) => _prefs.getInt(k) ?? 0;
  Future<bool> setInt(String k, int v) => _prefs.setInt(k, v);

  Map<String, dynamic> getJson(String k) {
    final s = _prefs.getString(k);
    if (s == null || s.isEmpty) return {};
    try { return jsonDecode(s); } catch (_) { return {}; }
  }

  Future<bool> setJson(String k, Map<String, dynamic> v) =>
      _prefs.setString(k, jsonEncode(v));

  static const kSrsItems = 'srs_items';
  static const kHearts = 'hearts';
  static const kStreak = 'streak';
  static const kElo = 'elo';
}
