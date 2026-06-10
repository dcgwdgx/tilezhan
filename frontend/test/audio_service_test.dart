import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/utils/audio_service.dart';

void main() {
  group('AudioService', () {
    test('enabled by default', () {
      expect(AudioService.isEnabled, true);
    });

    test('setEnabled controls state', () {
      AudioService.setEnabled(false);
      expect(AudioService.isEnabled, false);
      AudioService.setEnabled(true);
      expect(AudioService.isEnabled, true);
    });

    test('disabled state prevents playback', () {
      AudioService.setEnabled(false);
      // Should not throw even without Flutter binding
      AudioService.playTap();
      AudioService.playWrong();
      AudioService.setEnabled(true);
    });
  });
}
