/// AudioService 音频服务的单元测试
/// 测试覆盖：默认启用、开关控制、禁用状态下调用不抛异常
import 'package:flutter_test/flutter_test.dart';
import 'package:tilezhan/core/utils/audio_service.dart';

void main() {
  group('AudioService', () {
    // 音频服务默认处于启用状态
    test('enabled by default', () {
      expect(AudioService.isEnabled, true);
    });

    // setEnabled 能正确切换启用/禁用状态
    test('setEnabled controls state', () {
      AudioService.setEnabled(false);
      expect(AudioService.isEnabled, false);
      AudioService.setEnabled(true);
      expect(AudioService.isEnabled, true);
    });

    // 禁用后调用播放方法不应抛异常（安全降级）
    test('disabled state prevents playback', () {
      AudioService.setEnabled(false);
      // Should not throw even without Flutter binding
      AudioService.playTap();
      AudioService.playWrong();
      AudioService.setEnabled(true);
    });
  });
}
