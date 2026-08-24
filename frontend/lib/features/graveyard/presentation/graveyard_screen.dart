/// 错题墓地屏幕 — 展示所有待复习错题列表。
///
/// 每道错题可点击进入复习模式（不耗体力），
/// 按紧急程度排序（SRS errorWeight 降序）。

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/tile_model.dart';
import '../../../shared/widgets/tz_card.dart';
import '../../yaku_quiz/data/static_yaku_quiz_repository.dart';
import '../../yaku_quiz/presentation/yaku_quiz_copy.dart';
import '../domain/graveyard_provider.dart';
import '../../../l10n/generated/app_localizations.dart';

/// 错题墓地 — 复习列表界面
///
/// Displays the user's SRS due queue: a weakness radar summarising error
/// rates across the five mahjong suits, a scrollable list of overdue
/// flashcard, nanikiru and yaku items, and a "Review All" button that walks
/// the exact mixed-type review queue. 所有数据通过 Riverpod providers 驱动。
class GraveyardScreen extends ConsumerWidget {
  /// 构造无状态的错题墓地屏幕实例。
  const GraveyardScreen({
    super.key,
    this.planTarget,
  });

  /// Optional remaining count supplied by the fixed daily plan. The list still
  /// exposes every due item, while Review All stops exactly at this boundary.
  final int? planTarget;

  /// 构建屏幕 UI：顶部导航栏 + 弱点雷达图 + 待复习列表 + 一键复习按钮。
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.jadeWhiteDim),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Row(
          children: [
            Text(l10n.homeGraveyard,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Text(l10n.graveyardSrsReview,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.demonPurple,
                )),
          ],
        ),
      ),
      body: Consumer(
        // 监听 Riverpod provider 状态变化，自动重建 UI。
        builder: (context, ref, _) {
          // dueItems: SRS 到期错题列表；suitRates: 五种牌的加权错误率(man/pin/sou/wind/dragon)。
          final dueItems = ref.watch(graveyardDueProvider);
          final suitRates = ref.watch(suitErrorRatesProvider);
          final reviewCount =
              min(planTarget ?? dueItems.length, dueItems.length);
          return Column(
            children: [
              _buildRadarCard(context, suitRates, l10n),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                      '${l10n.graveyardTodaysReview} · ${l10n.graveyardDueCount(dueItems.length)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.jadeWhiteMuted,
                      )),
                ),
              ),
              const SizedBox(height: 8),
              // 待复习列表（可滚动）；为空时展示庆祝空状态。
              Expanded(child: _buildReviewList(context, dueItems)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // 按队列逐题打开精确复习；用户主动退出时停止后续跳转。
                    onPressed: dueItems.isEmpty
                        ? null
                        : () => _reviewAll(context, dueItems),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(l10n.graveyardReviewAll(reviewCount),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        )),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建弱点雷达卡片。展示五芒星雷达图，标注错误率最高的花色。
  ///
  /// [suitRates] key 为花色名('man'/'pin'/'sou'/'wind'/'dragon')，value 为 0~1 的错误率。
  /// 返回一个 [TzCard] 包裹的雷达图组件（含 CustomPaint 五边形图 + 最弱项高亮文本）。
  Widget _buildRadarCard(BuildContext context, Map<String, double> suitRates,
      AppLocalizations l10n) {
    // 五种麻将花色的内部键名与展示标签。
    final suits = ['man', 'pin', 'sou', 'wind', 'dragon'];
    // TODO: add l10n keys for suit labels (graveyardSuitMan, graveyardSuitPin, etc.)
    final labels = ['Man', 'Pin', 'Sou', 'Wind', 'Dgn'];
    // 找出错误率最高的花色，高亮为"最弱项"。
    final worst = suits
        .reduce((a, b) => (suitRates[a] ?? 0) > (suitRates[b] ?? 0) ? a : b);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: TzCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(l10n.graveyardWeaknessRadar,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.jadeWhiteDim,
                )),
            const SizedBox(height: 12),
            SizedBox(
              width: 140,
              height: 140,
              child: CustomPaint(
                painter: _RadarPainter(
                    data: suits.map((s) => suitRates[s] ?? 0).toList()),
              ),
            ),
            const SizedBox(height: 8),
            Text(
                l10n.graveyardWeakest(labels[suits.indexOf(worst)],
                    ((suitRates[worst] ?? 0) * 100).round()),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.vermillionHover,
                )),
          ],
        ),
      ),
    );
  }

  /// 构建待复习列表。
  ///
  /// [dueItems] 为 SRS 到期项列表，每项为 ([SRS条目数据], [TileModel]?) 的 record。
  /// 列表为空时展示庆祝空状态("🎉 Nothing due!")；否则构建可滚动的错题卡片列表，
  /// 每张卡片显示牌面 emoji、题目名称、类型、错误次数、逾期天数，点击跳转到对应复习页面。
  Widget _buildReviewList(
      BuildContext context, List<(dynamic, TileModel?)> dueItems) {
    final l10n = AppLocalizations.of(context)!;
    // 无待复习项：展示庆祝空状态。
    if (dueItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(l10n.graveyardNothingDue,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.jadeWhiteDim)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: dueItems.length,
      itemBuilder: (_, i) {
        // 解构 SRS 条目：item 为 SRS 元数据(类型/错误数/到期时间)，tile 为关联的牌模型(可为空)。
        final (item, tile) = dueItems[i];
        // 优先使用牌面的助记 emoji，无牌面时降级为万用麻将 emoji。
        final emoji = switch (item.type) {
          'yaku' => '🎓',
          'defense' => '🛡️',
          _ => tile?.mnemonic.emoji ?? '🀄',
        };
        // 优先使用助记名称，降级使用 itemId 作为标题。
        final yakuQuestion = item.type == 'yaku'
            ? const StaticYakuQuizRepository().findById(item.itemId)
            : null;
        final name = switch (item.type) {
          'yaku' =>
            yakuQuestion?.promptKey.localize(l10n) ?? l10n.yakuQuizTitle,
          'defense' => l10n.defenseQuestionPrompt,
          _ => tile?.mnemonic.name ?? item.itemId,
        };
        // 计算逾期天数 = (当前毫秒时间戳 - SRS 预定复习时间戳) / 一天毫秒数，四舍五入取整。
        final daysAgo =
            ((DateTime.now().millisecondsSinceEpoch - item.nextReviewAt) /
                    86400000)
                .round();
        final route = _reviewRoute(item, tile);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Semantics(
            button: true,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => context.push(route),
                borderRadius: BorderRadius.circular(12),
                child: TzCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: 12,
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '$name · ${switch (item.type) {
                                  'flashcard' => l10n.homeFlashcards,
                                  'yaku' => l10n.yakuQuizTitle,
                                  'defense' => l10n.homeDefenseTraining,
                                  _ => l10n.homeNanikiru,
                                }}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  // TODO: homeFlashcards is plural; consider graveyardFlashcard singular key
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: AppColors.jadeWhite,
                                )),
                            const SizedBox(height: 2),
                            Text(
                                l10n.graveyardErrorsOverdue(
                                    '${item.errors}', '$daysAgo'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.jadeWhiteMuted,
                                )),
                          ],
                        ),
                      ),
                      Text('${l10n.navReview} →',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.vermillion,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _reviewAll(
    BuildContext context,
    List<(dynamic, TileModel?)> dueItems,
  ) async {
    final queue = dueItems.take(planTarget ?? dueItems.length).toList();
    for (final (item, tile) in queue) {
      if (!context.mounted) return;
      final completed = await context.push<bool>(_reviewRoute(item, tile));
      if (completed != true) return;
    }
  }

  String _reviewRoute(dynamic item, TileModel? tile) {
    final reviewPath = switch (item.type) {
      'nanikiru' => '/nanikiru',
      'yaku' => '/yaku-quiz',
      'defense' => '/defense-training',
      _ => '/flashcard',
    };
    return Uri(
      path: reviewPath,
      queryParameters: {
        'mode': 'review',
        'contentId': item.itemId,
        if (item.type == 'flashcard') 'suite': tile?.suit.name ?? 'all',
      },
    ).toString();
  }
}

/// 五芒星弱点雷达绘制器。
///
/// 在给定画布上绘制三层同心五边形参考网格、五条轴线，并根据 [data] 的值
/// 绘制填充的弱点数据多边形（红色区域）。data 为 5 个 0~1 的错误率浮点数，
/// 索引 0~4 分别对应 man/pin/sou/wind/dragon。
class _RadarPainter extends CustomPainter {
  /// 五元素的错误率数据列表，每个值在 [0.0, 1.0] 区间，值越大表示该花色错误率越高。
  final List<double> data;
  const _RadarPainter({required this.data});

  /// 绘制雷达图：先画三层参考网格(同心五边形)，再画五条轴线，最后画数据多边形（填充+描边）。
  @override
  void paint(Canvas canvas, Size size) {
    // 画布中心点与绘图半径（减去 8px 边距防止溢出）。
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    // 画笔初始化为描边模式。
    final paint = Paint()..style = PaintingStyle.stroke;

    // 绘制三层同心五边形参考网格（30%/60%/100% 径向刻度），透明度逐层递增。
    for (int i = 1; i <= 3; i++) {
      paint.color = AppColors.jadeHover.withOpacity(0.3 + i * 0.15);
      paint.strokeWidth = 0.5;
      _drawPentagon(canvas, center, radius * i / 3, paint);
    }

    // 绘制五条轴线：从中心指向五边形各顶点，每条间隔 72°（2π/5），起始角度 -90°（正上方）。
    paint.color = AppColors.jadeHover.withOpacity(0.5);
    paint.strokeWidth = 0.5;
    for (int i = 0; i < 5; i++) {
      final angle = -3.14159 / 2 + i * 2 * 3.14159 / 5;
      canvas.drawLine(
          center,
          Offset(
            center.dx + radius * cos(angle),
            center.dy + radius * sin(angle),
          ),
          paint);
    }

    // 绘制弱点数据多边形：根据各花色的错误率按比例确定顶点到中心的距离。
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = -3.14159 / 2 + i * 2 * 3.14159 / 5; // 每条轴线的角度（-90° 起顺时针）。
      // 顶点半径 = 最大半径 × 错误率（clamp 到 [0,1]），数据不足时退化为 0。
      final r = radius * (data.length > i ? data[i].clamp(0.0, 1.0) : 0.0);
      final point =
          Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0)
        path.moveTo(point.dx, point.dy);
      else
        path.lineTo(point.dx, point.dy);
    }
    path.close();
    // 多边形描边：深红色半透明，线宽 2px。
    paint.color = AppColors.vermillion.withOpacity(0.6);
    paint.strokeWidth = 2;
    canvas.drawPath(path, paint);
    // 多边形填充：浅红色半透明覆层。
    paint.color = AppColors.vermillion.withOpacity(0.15);
    paint.style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  /// 绘制正五边形路径。用于雷达图的参考网格层（三层同心五边形）。
  ///
  /// [canvas] 画布，[center] 五边形中心点，[r] 外接圆半径，[paint] 画笔样式。
  void _drawPentagon(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      // 五边形顶点角度：-90° + i * 72°，确保顶点朝上。
      final angle = -3.14159 / 2 + i * 2 * 3.14159 / 5;
      final point =
          Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0)
        path.moveTo(point.dx, point.dy);
      else
        path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  /// 静态雷达图数据不变时无需重绘，始终返回 false 以提升渲染性能。
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
