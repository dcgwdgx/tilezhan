import 'package:flutter/services.dart';
import 'haptic_service.dart';

/// Audio + haptic feedback. Uses system sounds on iOS, haptic on all platforms.
/// WAV files in assets/sounds/ are reserved for future custom audio engine.
class AudioService {
  static bool _enabled = true;

  static void setEnabled(bool v) => _enabled = v;
  static bool get isEnabled => _enabled;

  static void playTap() {
    if (!_enabled) return;
    HapticService.lightTap();
    SystemSound.play(SystemSoundType.click);
  }

  static void playCorrect() {
    if (!_enabled) return;
    HapticService.correctAnswer();
  }

  static void playWrong() {
    if (!_enabled) return;
    HapticService.wrongAnswer();
    SystemSound.play(SystemSoundType.alert);
  }

  static void playComplete() {
    if (!_enabled) return;
    HapticService.heavyTap();
  }

  static void playSlash() {
    if (!_enabled) return;
    HapticService.discardSlash();
  }

  /// Play Chinese pronunciation of a tile (e.g., "五万", "八条")
  static Future<void> playVoice(String tileId) async {
    if (!_enabled) return;
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }
}
