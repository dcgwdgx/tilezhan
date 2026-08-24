/// 排行榜 API 上报服务。
///
/// 在每局游戏结束后异步上报玩家的 ELO 评分到后端排行榜端点。
/// 上报失败时静默忽略（无网络、后端不可用等），不影响本地游戏体验。
///
/// ## 使用示例
///
/// ```dart
/// LeaderboardService.reportScore(name: 'PlayerX', elo: 1200, streak: 5);
/// ```
import 'package:http/http.dart' as http;
import '../../../core/constants/api_endpoints.dart';

class LeaderboardService {
  /// 上报玩家 ELO 评分到后端排行榜。
  ///
  /// [name]   — 玩家显示名称，空字符串时跳过上报。
  /// [elo]    — 当前 ELO 评分。
  /// [streak] — 终身连击数（来自 [HeartService.allTimeCombo]）。
  ///
  /// 返回 `true` 表示上报成功（HTTP 200），`false` 表示失败（网络错误、
  /// 服务器错误等）。调用方通常不关心返回值——失败时静默忽略。
  static Future<bool> reportScore({
    required String name,
    required int elo,
    required int streak,
  }) async {
    if (name.isEmpty) return false;
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}/leaderboard/report')
          .replace(queryParameters: {
        'name': name,
        'elo': elo.toString(),
        'streak': streak.toString(),
      });
      final res = await http.post(uri);
      return res.statusCode == 200;
    } catch (_) {
      // Offline or server unreachable — silently ignore.
      // ELO is still tracked locally and will be reported on the next game.
      return false;
    }
  }
}
