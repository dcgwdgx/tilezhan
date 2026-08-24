// Battle report modal — shown when free user runs out of hearts.
// 战斗/对局结算弹窗 —— 免费用户爱心耗尽时弹出。
//
// Displays session stats (accuracy, combo, total), mistake review and sharing.
// Sales calls to action are controlled by CommerceAvailability.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/commerce/commerce_availability.dart';
import '../../core/constants/app_colors.dart';
import '../../core/hearts/heart_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/tz_button.dart';

/// 对局结算弹窗组件
///
/// 使用 [ConsumerStatefulWidget] 以便通过 Riverpod 监听结算数据提供者，
/// 同时管理内部 UI 状态。弹窗以底部弹出面板形式展示（圆角顶部），
/// 包含战绩卡片、连击促销横幅、操作按钮和高级版入口。
class TzBattleReport extends ConsumerStatefulWidget {
  const TzBattleReport({super.key});

  @override
  ConsumerState<TzBattleReport> createState() => _TzBattleReportState();
}

/// 对局结算弹窗的 State 类
///
/// 核心职责：
/// - 监听 [battleReportProvider] 获取本轮战绩数据
/// - 监听 [showComboPromoProvider] 决定是否展示连击促销横幅
/// - 提供分享、错题回顾、邀请好友、升级高级版等交互逻辑
class _TzBattleReportState extends ConsumerState<TzBattleReport> {
  /// 以纯文本形式通过系统分享面板分享战绩
  ///
  /// 先关闭弹窗再延迟调用分享 —— 在 iOS 上从模态弹窗内直接调用
  /// share_plus 会失败，因此先 pop 并等待 300ms 动画完成。
  ///
  /// 参数 [report] 为当前结算数据，包含总数、正确率和最大连击数。
  /// 分享文案采用 emoji + 关键数据 + APP 域名格式，简洁易传播。
  Future<void> _shareResults(BattleReport report) async {
    final l10n = AppLocalizations.of(context)!;
    final text = l10n.shareStats(
      report.total,
      (report.accuracy * 100).toInt(),
      report.maxCombo,
    );
    try {
      await Share.share(text);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  /// 构建对局结算弹窗的完整 UI
  ///
  /// 布局结构（从上到下）：
  /// 1. 拖拽手柄条 —— 视觉提示可下拉关闭
  /// 2. 战绩分享卡片 —— 深绿渐变背景 + 霓虹金描边，展示 emoji / 标题 / 三项数据
  /// 3. 连击促销横幅 —— 仅当连击数 ≥ 10 且未购买高级版时显示，引导解锁无限爱心
  /// 4. 操作按钮行 —— 分享、错题回顾、邀请好友，三个图标按钮等距排列
  /// 5. 高级版 CTA 按钮 —— 金色主按钮，跳转 /premium 路由
  @override
  Widget build(BuildContext context) {
    // 获取本地化字符串实例
    final l10n = AppLocalizations.of(context)!;

    // 通过 Riverpod 监听本轮结算数据（total / accuracy / maxCombo）
    final report = ref.watch(battleReportProvider);
    final salesEnabled = ref.watch(commerceAvailabilityProvider).salesEnabled;

    return Container(
      // 内边距：上下左右各 28px，给内容足够呼吸空间
      padding: const EdgeInsets.all(28),

      // 背景与圆角：深翡翠色背景 + 仅顶部圆角（底部弹出面板风格）
      decoration: const BoxDecoration(
        color: AppColors.jadeDeep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),

      // 主列布局：min 高度自适应，内容少时不撑满屏幕
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── 1. 拖拽手柄条 ──
        // 半透明白色小横条，暗示用户可以下拉关闭弹窗（配合 DraggableScrollableSheet 使用）
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.jadeWhiteMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            )),
        const SizedBox(height: 20),

        // ── 2. 战绩分享卡片（可截图分享的视觉模块）──
        Container(
          padding: const EdgeInsets.all(20),

          // 深绿渐变背景 + 霓虹金微光描边，营造赛博国风氛围
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F3526), Color(0xFF0D3D26)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.neonGold.withValues(alpha: 0.2),
            ),
          ),

          child: Column(children: [
            // 靶心 emoji（视觉锚点）
            const Text('🎯', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 4),

            // 标题："今日对局" 或对应本地化文本
            Text(l10n.battleTitle,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.neonGold)),
            const SizedBox(height: 20),

            // 三项核心数据：总题数 / 正确率 / 最大连击
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _stat(l10n.battleTotal, '${report.total}'),
              _stat(l10n.battleAccuracy, '${(report.accuracy * 100).toInt()}%'),
              _stat(l10n.battleMaxCombo, '${report.maxCombo}×'),
            ]),
            const SizedBox(height: 12),

            // APP 域名标识（卡片底部署名）
            Text(l10n.battleDomain,
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.neonGold.withValues(alpha: 0.6))),
          ]),
        ),
        const SizedBox(height: 16),

        // ── 3. 连击促销横幅（条件渲染）──
        // 当连击数 ≥ 10 时触发 showComboPromoProvider 为 true，
        // 显示特殊优惠横幅引导用户升级高级版以保留高连击记录
        if (salesEnabled && ref.watch(showComboPromoProvider))
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 4),

            // 霓虹金半透明底色 + 描边，视觉上与战绩卡片呼应
            decoration: BoxDecoration(
              color: AppColors.neonGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.neonGold.withValues(alpha: 0.3),
              ),
            ),

            // 横向布局：🔥 图标 + 文案区 + 解锁按钮
            child: Row(children: [
              // 火焰 emoji，视觉强调"热度/连击"
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),

              // 促销文案：主标题 + 副标题（垂直排列）
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(l10n.battleComboBanner,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.neonGold)),
                    Text(l10n.battleComboSub,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.jadeWhiteDim)),
                  ])),

              // "立即解锁"按钮：关闭弹窗并导航到高级版页面
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  context.push('/premium');
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.neonGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(l10n.battleComboUnlock,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.black)),
                ),
              ),
            ]),
          ),

        // ── 4. 操作按钮行 ──
        // 三个等距排列的图标按钮：分享战绩、查看错题、邀请好友
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _actionBtn(
              Icons.share, l10n.battleShare, () => _shareResults(report)),
          const SizedBox(width: 24),
          _actionBtn(Icons.auto_fix_high, l10n.battleMistakesBtn, () {
            // 关闭弹窗后跳转到错题本页面（/graveyard 路由）
            Navigator.pop(context);
            context.push('/graveyard');
          }),
          const SizedBox(width: 24),
          _actionBtn(Icons.person_add, l10n.battleInvite, () {
            // 调用邀请分享逻辑
            _shareInviteLink();
          }),
        ]),
        const SizedBox(height: 16),

        // ── 5. 高级版 CTA（Call To Action）──
        // 金色主按钮，全宽度，引导用户升级高级版解锁无限爱心
        if (salesEnabled) ...[
          TzButton(
            label: l10n.battlePremiumCTA,
            style: TzButtonStyle.gold,
            onPressed: () => context.push('/premium'),
          ),
          const SizedBox(height: 16),
        ],
      ]),
    );
  }

  /// 构建单个操作图标按钮
  ///
  /// 由图标 + 文字标签组成，整体可点击。用于分享、错题、邀请三个操作入口。
  ///
  /// 参数：
  /// - [icon]   Material Icons 图标（如 Icons.share）
  /// - [label]  按钮下方文字（本地化字符串）
  /// - [onTap]  点击回调
  ///
  /// 返回一个 [GestureDetector] 包裹的 [Column]，图标在圆角方形容器中展示。
  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        // 图标容器：44×44 圆角方片，深色卡片底色 + 细描边
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.jadeCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.jadeHover),
          ),
          child: Icon(icon, color: AppColors.jadeWhiteDim, size: 20),
        ),
        const SizedBox(height: 4),

        // 文字标签：小号灰色字体，居中对齐
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: AppColors.jadeWhiteMuted)),
      ]),
    );
  }

  /// 分享邀请链接（邀请好友加入 TileZhan）
  ///
  /// 与 [_shareResults] 逻辑相同：先关闭弹窗，延迟 300ms 等待动画完成，
  /// 再调用系统分享面板。分享文案以麻将牌 emoji 开头，包含 APP 介绍和域名。
  ///
  /// 等待系统分享结果；若平台分享不可用，则回退为复制邀请文本。
  Future<void> _shareInviteLink() async {
    final text = AppLocalizations.of(context)!.inviteText;
    try {
      await Share.share(text);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  /// 构建单个统计数据展示组件
  ///
  /// 用于战绩卡片中的三项核心数据（总题数 / 正确率 / 最大连击），
  /// 每项由大号数值 + 小号标签组成，垂直居中排列。
  ///
  /// 参数：
  /// - [label] 底部标签文字（如 "总题数" / "正确率" / "最大连击"）
  /// - [value] 顶部数值文字（如 "12" / "83%" / "5×"）
  ///
  /// 返回一个 [Column]，数值使用粗体大号白色字体，标签使用小号灰色字体。
  Widget _stat(String label, String value) {
    return Column(children: [
      // 数值：24px 粗体白色，醒目展示
      Text(value,
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.jadeWhite)),
      const SizedBox(height: 4),

      // 标签：11px 灰色，居中对齐于数值下方
      Text(label,
          style:
              const TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted)),
    ]);
  }
}
