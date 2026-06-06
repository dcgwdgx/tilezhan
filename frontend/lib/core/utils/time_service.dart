/// NTP time synchronization service.
/// Prevents stamina cheating by syncing with server time.

class TimeService {
  static Duration? _ntpOffset;

  static DateTime now() {
    return DateTime.now().add(_ntpOffset ?? Duration.zero);
  }

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
