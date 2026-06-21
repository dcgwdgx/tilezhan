/// 排行榜数据上传同意管理。
///
/// 在首次上报排行榜前征得用户同意（App Store Guideline 5.1.2 要求）。
/// 同意状态存储在 Hive `prefs` box 键 `leaderboard_consent`。
/// 一旦同意，后续所有上报静默执行；拒绝后每次会话再次询问。
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../features/leaderboard/domain/leaderboard_service.dart';
import '../constants/app_colors.dart';

/// Hive 存储键名。
const _kConsentKey = 'leaderboard_consent';

/// 检查用户是否同意上传排行榜数据。
bool hasLeaderboardConsent() {
  try {
    return Hive.box('prefs').get(_kConsentKey, defaultValue: false);
  } catch (_) {
    return false;
  }
}

/// 持久化同意状态。
void setLeaderboardConsent(bool value) {
  try {
    Hive.box('prefs').put(_kConsentKey, value);
  } catch (_) {}
}

/// 征得同意后上报排行榜。
///
/// [context] — 当前 BuildContext，用于弹出同意对话框。
/// [name]   — 玩家显示名称。
/// [elo]    — 当前 ELO 评分。
/// [streak] — 终身连击数。
///
/// 如果已同意则直接上报；未同意则弹出对话框，用户同意后上报。
void reportWithConsent(BuildContext context, String name, int elo, int streak) {
  if (hasLeaderboardConsent()) {
    LeaderboardService.reportScore(name: name, elo: elo, streak: streak);
  } else {
    showLeaderboardConsentDialog(context, (agreed) {
      if (agreed) {
        LeaderboardService.reportScore(name: name, elo: elo, streak: streak);
      }
    });
  }
}

/// 弹出排行榜上传同意对话框。
///
/// [context] — 当前 [BuildContext]。
/// [onResult] — 用户做出选择后的回调：`true`=同意，`false`=拒绝。
Future<void> showLeaderboardConsentDialog(
  BuildContext context,
  void Function(bool agreed) onResult,
) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      return AlertDialog(
        backgroundColor: AppColors.jadeCard,
        title: Row(children: [
          const Icon(Icons.public, color: AppColors.neonGold, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(l10n.consentTitle, style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.jadeWhite))),
        ]),
        content: Text(l10n.consentBody,
          style: const TextStyle(fontSize: 14, color: AppColors.jadeWhiteDim, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () {
              setLeaderboardConsent(false);
              Navigator.pop(context);
              onResult(false);
            },
            child: Text(l10n.consentNotNow, style: const TextStyle(color: AppColors.jadeWhiteMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonGold),
            onPressed: () {
              setLeaderboardConsent(true);
              Navigator.pop(context);
              onResult(true);
            },
            child: Text(l10n.consentAllow, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
          ),
        ],
      );
    },
  );
}
