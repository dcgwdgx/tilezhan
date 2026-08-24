/// 首页 — 体力/每日挑战/快捷入口
///
/// 展示玩家体力状态、段位徽章、每日挑战卡片、快捷功能网格，以及底部导航栏。
/// 体力通过 [heartServiceProvider] 读取，每日挑战剩余次数通过
/// [dailyChallengeRemainingProvider] 读取，快捷入口通过 GridView 布局十二宫格。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/commerce/commerce_availability.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/hearts/heart_provider.dart';
import '../../../core/iap/iap_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../training_plan/presentation/today_training_card.dart';
import '../../training_plan/data/training_plan_store.dart';

/// 首页主屏幕，展示体力、段位、每日挑战和快捷入口。
///
/// 包含以下区域：
/// - 顶栏：体力心数 & 会员徽章
/// - 段位卡片：称号、等级、ELO 分数
/// - 每日挑战：剩余免费次数 & 开始按钮
/// - 快捷入口：十二宫格导航（闪卡、何切、防守、役种、分析、收藏、错题等）
/// - 底部导航：首页 / 牌 / 役 / 回顾
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  // 当前激活的底部导航标签索引 (0=首页, 1=牌, 2=役, 3=回顾)
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future<void>.microtask(_refreshDailyPlan);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshDailyPlan();
  }

  void _refreshDailyPlan() {
    if (!mounted) return;
    ref.read(dailyTrainingPlanProvider.notifier).refreshForToday();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ① 顶栏：体力心数 & 会员徽章
              _buildTopBar(),
              const SizedBox(height: 12),
              // ② 今日训练计划：到期复习、弱项与每日牌效的唯一主路径
              const TodayTrainingCard(),
              const SizedBox(height: 16),
              // ④ 快捷入口分区标题
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.homeQuickAccess,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.jadeWhiteMuted,
                      )),
                ),
              ),
              const SizedBox(height: 8),
              // ⑤ 十二宫格快捷入口导航
              _buildQuickGrid(),
              // 底部留白，避免被导航栏遮挡
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      // ⑥ 底部导航栏：4 标签 (首页/牌/役/回顾)，激活态弹性放大 + 金色高亮
      bottomNavigationBar: _buildBottomTabBar(),
    );
  }

  // 构建顶栏。免费发行默认只展示品牌和个人中心；只有显式启用限制或
  // 销售的构建才展示爱心和 Premium，避免不可购买的付费入口干扰学习。
  Widget _buildTopBar() {
    final l10n = AppLocalizations.of(context)!;
    final availability = ref.watch(commerceAvailabilityProvider);
    final hearts = availability.trainingLimitsEnabled
        ? ref.watch(heartServiceProvider).hearts
        : null;
    final isPremium =
        availability.salesEnabled ? ref.watch(isPremiumProvider) : false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Text(
            l10n.appTitle,
            style: const TextStyle(
              color: AppColors.jadeWhite,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          if (hearts != null) ...[
            const SizedBox(width: 12),
            Semantics(
              label: l10n.homeHeartsRemaining(hearts),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Text(
                      '❤️',
                      style: TextStyle(
                        fontSize: 18,
                        color: hearts > 0
                            ? const Color(0xFFFF3B30)
                            : AppColors.jadeWhiteMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$hearts/10',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: hearts > 0
                            ? AppColors.jadeWhite
                            : AppColors.jadeWhiteMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          if (availability.salesEnabled)
            Semantics(
              button: true,
              label: isPremium ? l10n.homePro : l10n.homeUpgrade,
              child: GestureDetector(
                onTap: () => context.push('/premium'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPremium
                        ? AppColors.neonGold.withOpacity(0.2)
                        : AppColors.demonPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPremium ? '👑 ${l10n.homePro}' : '👑 ${l10n.homeUpgrade}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isPremium
                          ? AppColors.neonGold
                          : AppColors.jadeWhiteMuted,
                    ),
                  ),
                ),
              ),
            )
          else
            IconButton(
              tooltip: l10n.homeProfile,
              onPressed: () => context.push('/profile'),
              icon: const Icon(
                Icons.account_circle_outlined,
                color: AppColors.jadeWhiteDim,
              ),
            ),
        ],
      ),
    );
  }

  // 构建三列快捷入口：闪卡/何切/防守/役种/分析/收藏/错题/牌浏览/个人/会员/段位/设置
  // 每个格子 = GestureDetector 包裹图标 + 文字标签，点击通过 go_router 跳转
  Widget _buildQuickGrid() {
    final l10n = AppLocalizations.of(context)!;
    final availability = ref.watch(commerceAvailabilityProvider);
    // 十二宫格数据源：(图标, 标签, 路由路径)
    final items = [
      ('🃏', l10n.homeFlashcards, '/flashcard'),
      ('⚔️', l10n.homeNanikiru, '/nanikiru'),
      ('🛡️', l10n.homeDefenseTraining, '/defense-training'),
      ('🎓', l10n.yakuQuizTitle, '/yaku-quiz'),
      ('🔬', l10n.homeHandAnalyzer, '/hand-analyzer'),
      ('📚', l10n.homeCollection, '/collection'),
      ('👻', l10n.homeGraveyard, '/graveyard'),
      ('🔍', l10n.homeTileBrowser, '/tiles'),
      ('👤', l10n.homeProfile, '/profile'),
      if (availability.salesEnabled) ('💎', l10n.homePremium, '/premium'),
      ('🏆', l10n.homeRank, '/leaderboard'),
      ('⚙️', l10n.homeSettings, '/settings'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
        children: items.map((item) {
          // item.$1=图标, item.$2=标签, item.$3=路由
          return Semantics(
            button: true,
            label: item.$2,
            excludeSemantics: true,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => context.push(item.$3),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.jadeCard,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppColors.jadeHover.withOpacity(0.5)),
                    // 底部阴影 → 卡片浮起感
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  // 垂直居中：上方 emoji 图标 + 下方文字标签
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.$1, style: const TextStyle(fontSize: 30)),
                        const SizedBox(height: 4),
                        // 单行省略，防止过长文本溢出
                        Text(item.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.jadeWhite)),
                      ]),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 构建底部导航栏：4 个标签 (首页/牌/役/回顾)，激活态图标放大 + 标签金色高亮
  // 导航状态由本地 _activeTab 驱动，路由通过 go_router 跳转
  Widget _buildBottomTabBar() {
    final l10n = AppLocalizations.of(context)!;
    // 底部标签数据源：(图标, 标签文本, 索引, 路由路径)
    final tabs = [
      ('🏠', l10n.navHome, 0, '/'),
      ('🀄', l10n.navTiles, 1, '/tiles'),
      ('📚', l10n.navYaku, 2, '/collection'),
      ('👻', l10n.navReview, 3, '/graveyard'),
    ];
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFF0A2818),
        border: Border(top: BorderSide(color: Color(0xFF1A4A30), width: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, -2))
        ],
      ),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map((t) {
          final active = _activeTab == t.$3;
          return GestureDetector(
            onTap: () {
              // 更新本地激活索引 → 触发弹性动画 & 颜色切换
              setState(() => _activeTab = t.$3);
              // go_router 跳转到目标路由
              context.push(t.$4);
            },
            // 弹性缩放动画：激活标签放大至 1.15x，非激活恢复 1.0x，300ms elasticOut
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: active ? 1.15 : 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (_, s, __) => Transform.scale(
                scale: s,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(t.$1, style: TextStyle(fontSize: active ? 22 : 20)),
                  const SizedBox(height: 2),
                  Text(t.$2,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? AppColors.neonGold
                            : AppColors.jadeWhiteMuted,
                      )),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
