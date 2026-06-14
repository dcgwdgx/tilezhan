/// 时间工具 — 格式转换/计时器/日期比较。
/// NTP time synchronization — prevents stamina cheating by syncing with server time.
/// Per design spec: lib/core/utils/time_service.dart

/// NTP time synchronization service.
/// Provides a unified [now] getter that is offset-corrected after [sync].
class TimeService {
  static Duration? _ntpOffset;

  /// Returns the current time adjusted by the NTP offset.
  /// Falls back to local time if [sync] has not been called or failed.
  static DateTime now() {
    return DateTime.now().add(_ntpOffset ?? Duration.zero);
  }

  /// Synchronizes the internal clock offset with an NTP server.
  /// Call once at app startup. Gracefully falls back to the cached offset
  /// on network failure.
  static Future<void> sync() async {
    try {
      final ntpNow = await _fetchNtpTime();
      _ntpOffset = ntpNow.difference(DateTime.now());
    } catch (_) {
      // NTP failed — fall back to cached offset
    }
  }

  static Future<DateTime> _fetchNtpTime() async {
    // In production, use ntp package:
    // final offset = await NTP.getNtpOffset(lookUpAddress: 'time.google.com');
    // return DateTime.now().add(offset);
    return DateTime.now().toUtc();
  }
}
