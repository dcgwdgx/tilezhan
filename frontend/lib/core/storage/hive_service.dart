/// Hive key-value cache service.
///
/// Boxes:
///   - 'puzzles': cached daily quest JSON (TTL 24h)
///   - 'settings': user preferences (language, sound, haptic)
///   - 'auth': cached Firebase token
///   - 'ntp': cached NTP offset

class HiveService {
  static HiveService? _instance;
  static HiveService get instance =>
      _instance ?? (throw StateError('HiveService not initialized'));

  static Future<void> initialize() async {
    _instance = HiveService();
  }

  // Puzzle cache
  Future<Map<String, dynamic>?> getCachedQuest() async => null;
  Future<void> cacheQuest(Map<String, dynamic> quest) async {}

  // Settings
  Future<String> getLanguage() async => 'en';
  Future<bool> getSoundEnabled() async => true;
  Future<void> setLanguage(String lang) async {}
  Future<void> setSoundEnabled(bool enabled) async {}
}
