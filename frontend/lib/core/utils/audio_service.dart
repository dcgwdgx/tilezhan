/// Global audio, voice, and haptic feedback service.
/// Combines [HapticFeedback], [SystemSound], and audioplayers WAV playback.
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'haptic_service.dart';

/// Manages all game sound effects, voice playback, and haptic feedback.
/// Togglable via [setEnabled] — respects user preferences for audio/haptics.
class AudioService {
  static final _voicePlayer = AudioPlayer();
  static bool _enabled = true;

  /// Enable or disable all audio and haptic feedback.
  static void setEnabled(bool v) => _enabled = v;
  /// Whether audio and haptic feedback is currently enabled.
  static bool get isEnabled => _enabled;

  /// Play a light tap sound + haptic for generic button presses.
  static void playTap() {
    if (!_enabled) return;
    try { HapticService.lightTap(); } catch (_) {}
    try { SystemSound.play(SystemSoundType.click); } catch (_) {}
  }

  /// Play a correct-answer feedback: light haptic celebration.
  static void playCorrect() {
    if (!_enabled) return;
    try { HapticService.correctAnswer(); } catch (_) {}
    try { HapticFeedback.heavyImpact(); } catch (_) {}
  }

  /// Play a wrong-answer feedback: double heavy haptic pulse + system alert sound.
  static void playWrong() {
    if (!_enabled) return;
    try { HapticService.wrongAnswer(); } catch (_) {}
    try { HapticFeedback.heavyImpact(); } catch (_) {}
    Future.delayed(const Duration(milliseconds: 80), () {
      try { HapticFeedback.heavyImpact(); } catch (_) {}
    });
    try { SystemSound.play(SystemSoundType.alert); } catch (_) {}
  }

  /// Play a completion feedback: heavy haptic impact.
  static void playComplete() {
    if (!_enabled) return;
    try { HapticService.heavyTap(); } catch (_) {}
    try { HapticFeedback.heavyImpact(); } catch (_) {}
  }

  /// Play a discard/slash feedback: medium haptic impact.
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
