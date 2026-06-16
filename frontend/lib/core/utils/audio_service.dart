/// Global audio + haptic feedback service.
///
/// Plays WAV sound effects via [audioplayers] and triggers haptic vibrations
/// on supported devices. All methods respect [_enabled] flag for user preferences.
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'haptic_service.dart';

/// Manages game SFX + haptics. Togglable via [setEnabled].
class AudioService {
  static final _player = AudioPlayer();
  static bool _enabled = true;

  static void setEnabled(bool v) => _enabled = v;
  static bool get isEnabled => _enabled;

  /// Light tap: UI button press.
  static void playTap() {
    if (!_enabled) return;
    _playSfx('tap.wav');
    try { HapticService.lightTap(); } catch (_) {}
  }

  /// Correct answer: celebration SFX + haptic.
  static void playCorrect() {
    if (!_enabled) return;
    _playSfx('correct.wav');
    try { HapticService.correctAnswer(); } catch (_) {}
    try { HapticFeedback.heavyImpact(); } catch (_) {}
  }

  /// Wrong answer: alert SFX + double pulse haptic.
  static void playWrong() {
    if (!_enabled) return;
    _playSfx('wrong.wav');
    try { HapticService.wrongAnswer(); } catch (_) {}
    try { HapticFeedback.heavyImpact(); } catch (_) {}
    Future.delayed(const Duration(milliseconds: 80), () {
      try { HapticFeedback.heavyImpact(); } catch (_) {}
    });
  }

  /// Quiz completed: completion fanfare.
  static void playComplete() {
    if (!_enabled) return;
    _playSfx('complete.wav');
    try { HapticService.heavyTap(); } catch (_) {}
    try { HapticFeedback.heavyImpact(); } catch (_) {}
  }

  /// Discard/slash: blade SFX + medium haptic.
  static void playSlash() {
    if (!_enabled) return;
    _playSfx('slash.wav');
    try { HapticService.discardSlash(); } catch (_) {}
    try { HapticFeedback.mediumImpact(); } catch (_) {}
  }

  /// Chinese TTS voice for a tile.
  static Future<void> playVoice(String tileId) async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/voice/$tileId.wav'));
    } catch (_) {
      try { SystemSound.play(SystemSoundType.click); } catch (_) {}
    }
  }

  // ---- internals ----

  /// Play a WAV sound effect from assets/sounds/.
  static void _playSfx(String filename) {
    try {
      _player.play(AssetSource('sounds/$filename'));
    } catch (_) { /* SFX failure shouldn't crash */ }
  }
}
