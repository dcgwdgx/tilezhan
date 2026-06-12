import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'haptic_service.dart';

class AudioService {
  static final _voicePlayer = AudioPlayer();
  static bool _enabled = true;

  static void setEnabled(bool v) => _enabled = v;
  static bool get isEnabled => _enabled;

  static void playTap() {
    if (!_enabled) return;
    try { HapticService.lightTap(); } catch (_) {}
    try { SystemSound.play(SystemSoundType.click); } catch (_) {}
  }

  static void playCorrect() {
    if (!_enabled) return;
    try { HapticService.correctAnswer(); } catch (_) {}
    try { HapticFeedback.heavyImpact(); } catch (_) {}
  }

  static void playWrong() {
    if (!_enabled) return;
    try { HapticService.wrongAnswer(); } catch (_) {}
    try { HapticFeedback.heavyImpact(); } catch (_) {}
    Future.delayed(const Duration(milliseconds: 80), () {
      try { HapticFeedback.heavyImpact(); } catch (_) {}
    });
    try { SystemSound.play(SystemSoundType.alert); } catch (_) {}
  }

  static void playComplete() {
    if (!_enabled) return;
    try { HapticService.heavyTap(); } catch (_) {}
    try { HapticFeedback.heavyImpact(); } catch (_) {}
  }

  static void playSlash() {
    if (!_enabled) return;
    try { HapticService.discardSlash(); } catch (_) {}
    try { HapticFeedback.mediumImpact(); } catch (_) {}
  }

  /// Play Chinese pronunciation of a tile
  static Future<void> playVoice(String tileId) async {
    if (!_enabled) return;
    try {
      await _voicePlayer.stop();
      await _voicePlayer.play(AssetSource('sounds/voice/$tileId.wav'));
    } catch (_) {
      try { SystemSound.play(SystemSoundType.click); } catch (_) {}
    }
  }
}
