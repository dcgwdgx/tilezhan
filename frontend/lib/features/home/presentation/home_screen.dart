/// 首页 — 体力/每日挑战/快捷入口
///
/// 展示玩家体力状态、段位徽章、每日挑战卡片、快捷功能网格，以及底部导航栏。
/// 体力通过 [heartServiceProvider] 读取，每日挑战剩余次数通过
/// [dailyChallengeRemainingProvider] 读取，快捷入口通过 GridView 布局九宫格。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/hearts/heart_provider.dart';
import '../../../core/iap/iap_provider.dart';
import '../../../core/srs/srs_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/tz_battle_report.dart';
import '../../../shared/widgets/tz_button.dart';

/// 首页主屏幕，展示体力、段位、每日挑战和快捷入口。
///
/// 包含以下区域：
/// - 顶栏：体力心数 & 会员徽章
/// - 段位卡片：称号、等级、ELO 分数
/// - 每日挑战：剩余免费次数 & 开始按钮
/// - 快捷入口：九宫格导航（闪卡、何切、扫描、役种、牌谱、牌浏览、个人、会员、设置）
/// - 底部导航：首页 / 牌 / 役 / 回顾
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // 闪烁动画控制器 — 驱动加载态流光效果 (_ShimmerBar 使用)
  late AnimationController _shimmerCtrl;
  // 当前激活的底部导航标签索引 (0=首页, 1=牌, 2=役, 3=回顾)
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    // 初始化闪烁动画: 1.5s 周期循环播放，驱动 _ShimmerBar 流光效果
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _shimmerCtrl.repeat();
  }

  @override
  void dispose() {
    // 销毁动画控制器，释放 vsync 资源避免内存泄漏
    _shimmerCtrl.dispose();
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
              // ② 段位徽章卡片：称号、等级、复习次数
              _buildBadgeCard(),
              const SizedBox(height: 16),
              // ③ 每日挑战卡片：剩余免费次数 & 开始按钮
              _buildQuestCard(),
              const SizedBox(height: 16),
              // ④ 快捷入口分区标题
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.homeQuickAccess, style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5,
                    color: AppColors.jadeWhiteMuted,
                  )),
                ),
              ),
              const SizedBox(height: 8),
              // ⑤ 九宫格快捷入口导航
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

  // 构建顶栏：左侧体力心数 (❤️ + X/10)，右侧会员徽章按钮
  // 体力为 0 时图标置灰 + 数字加删除线，会员已购显示 "Pro" 金色否则 "升级" 紫色
  Widget _buildTopBar() {
    final l10n = AppLocalizations.of(context)!;
    // 监听 Riverpod 体力服务 → 当前体力值
    final hearts = ref.watch(heartServiceProvider).hearts;
    // 监听 Riverpod IAP 服务 → 是否已购会员
    final isPremium = ref.watch(isPremiumProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(children: [
        // 左侧体力区域：心形图标 + 当前体力 / 最大体力 (10)
        Row(children: [
          Text('❤️', style: TextStyle(
            fontSize: 18,
            // 体力耗尽 → 图标置灰
            color: hearts > 0 ? const Color(0xFFFF3B30) : AppColors.jadeWhiteMuted,
          )),
          const SizedBox(width: 4),
          Text('$hearts/10', style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            // 体力耗尽 → 文字置灰 + 删除线
            color: hearts > 0 ? AppColors.jadeWhite : AppColors.jadeWhiteMuted,
            decoration: hearts == 0 ? TextDecoration.lineThrough : null,
          )),
        ]),
        const Spacer(),
        // 右侧会员徽章按钮：点击跳转 /premium 页面
        GestureDetector(
          onTap: () => context.push('/premium'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              // 已购 → 半透明金色背景；未购 → 半透明紫色背景
              color: isPremium
                ? AppColors.neonGold.withOpacity(0.2)
                : AppColors.demonPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPremium ? '👑 ${l10n.homePro}' : '👑 ${l10n.homeUpgrade}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                color: isPremium ? AppColors.neonGold : AppColors.jadeWhiteMuted),
            ),
          ),
          ),
        ],
      ),
    );
  }

  /// 从 SRS 数据推算段位名称——根据总复习次数递进。
  String _rankName(WidgetRef ref) {
    final srs = ref.watch(srsItemsProvider);
    final total = srs.values.fold<int>(0, (s, i) => s + i.reps);
    final l10n = AppLocalizations.of(context)!;
    if (total < 5) return l10n.rankNovice;
    if (total < 20) return l10n.rankApprentice;
    if (total < 50) return l10n.rankAdept;
    if (total < 100) return l10n.rankExpert;
    return l10n.rankMaster;
  }

  /// SRS 总复习次数。
  int _totalReviews(WidgetRef ref) {
    final srs = ref.watch(srsItemsProvider);
    return srs.values.fold<int>(0, (s, i) => s + i.reps);
  }

  // 构建段位徽章卡片：左侧 trophy 图标 + 右侧段位名称 & ELO 复习统计
  // 卡片背景为深绿到暗绿渐变，带微弱金色描边和辉光阴影
  Widget _buildBadgeCard() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // 深绿渐变背景 + 微弱金色描边 + 金色辉光阴影
          gradient: const LinearGradient(
            colors: [Color(0xFF103D28), Color(0xFF0D3D26)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neonGold.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: AppColors.neonGold.withOpacity(0.05), blurRadius: 30)],
        ),
        child: Row(
          children: [
            // 左侧段位图标容器：紫色渐变方形 + 🏆 表情
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.demonPurple, Color(0xFF6C3483)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.demonPurple.withOpacity(0.3), blurRadius: 12)],
              ),
              child: const Center(child: Text('🏆', style: TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 16),
            // 右侧文字区域：段位名称 + 复习次数
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // 段位从 SRS 总复习次数推算
              Text(_rankName(ref), style: const TextStyle(fontSize: 18,
                fontWeight: FontWeight.w700, color: AppColors.jadeWhite)),
              const SizedBox(height: 2),
              // 金色复习次数文本 (如 "128 reviews")
              Text(l10n.rankReviews(_totalReviews(ref)),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.neonGold)),
            ]),
          ],
        ),
      ),
    );
  }

  // 构建每日挑战卡片：顶部标签栏 (挑战名称 + 剩余次数)，中部描述文本，底部黄金开始按钮
  Widget _buildQuestCard() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F3526), Color(0xFF0D3D26)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.neonGold.withOpacity(0.25)),
        ),
        child: Column(children: [
          // 顶部标签栏：左侧金色挑战标签 + 右侧剩余免费次数
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.neonGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(l10n.homeDailyChallenge, style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: AppColors.neonGold, letterSpacing: 1)),
            ),
            const Spacer(),
            // 监听每日挑战剩余次数 (如 "2/3 free")
            Text(l10n.homeFreeCount(ref.watch(dailyChallengeRemainingProvider)),
              style: const TextStyle(fontSize: 12, color: AppColors.jadeWhiteDim)),
          ]),
          const SizedBox(height: 16),
          // 每日挑战描述文本 (本地化)
          Text(l10n.homeDailyDesc,
            style: TextStyle(fontSize: 14, color: AppColors.jadeWhiteDim)),
          const SizedBox(height: 16),
          // 黄金风格开始按钮，点击跳转 /nanikiru 何切页面
          TzButton(
            label: l10n.homeStartChallenge,
            style: TzButtonStyle.gold,
            onPressed: () => context.push('/nanikiru'),
          ),
        ]),
      ),
    );
  }

  // 构建 3×3 九宫格快捷入口：闪卡/何切/扫描/役种/牌谱/牌浏览/个人/会员/段位/设置
  // 每个格子 = GestureDetector 包裹图标 + 文字标签，点击通过 go_router 跳转
  Widget _buildQuickGrid() {
    final l10n = AppLocalizations.of(context)!;
    // 九宫格数据源：(图标, 标签, 路由路径)
    final items = [
      ('🃏', l10n.homeFlashcards, '/flashcard'), ('⚔️', l10n.homeNanikiru, '/nanikiru'),
      ('🔬', l10n.homeScanner, '/scanner'),       ('📚', l10n.homeCollection, '/collection'),
      ('👻', l10n.homeGraveyard, '/graveyard'),   ('🔍', l10n.homeTileBrowser, '/tiles'),
      ('👤', l10n.homeProfile, '/profile'),       ('💎', l10n.homePremium, '/premium'),
      ('🏆', l10n.homeRank, '/leaderboard'),       ('⚙️', l10n.homeSettings, '/settings'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.2,
        children: items.map((item) {
          // item.$1=图标, item.$2=标签, item.$3=路由
          return GestureDetector(
            onTap: () => context.push(item.$3),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.jadeCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.jadeHover.withOpacity(0.5)),
                // 底部阴影 → 卡片浮起感
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              // 垂直居中：上方 emoji 图标 + 下方文字标签
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(item.$1, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 4),
                // 单行省略，防止过长文本溢出
                Text(item.$2, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.jadeWhite)),
              ]),
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
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, -2))],
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
                  Text(t.$2, style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: active ? AppColors.neonGold : AppColors.jadeWhiteMuted,
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

/// 闪烁流光进度条组件。
///
/// 渲染一个水平进度条，表面叠加由 [AnimationController] 驱动的白色光泽流光效果。
/// 核心原理：通过 [ShaderMask] + 平移的 [LinearGradient] 在彩色进度条上
/// 叠加一道白色半透明光带，模拟加载中的闪烁动画。
class _ShimmerBar extends StatelessWidget {
  // 进度填充比例 0.0~1.0，控制进度条实际填充宽度
  final double progress;
  // 进度条填充颜色 (如金色、绿色等)
  final Color color;
  // 驱动流光位移动画的控制器，value 在 0.0~1.0 间循环
  final AnimationController ctrl;
  const _ShimmerBar({required this.progress, required this.color, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    // 5 段渐变：透明 → 微弱白 → 亮白 (峰值) → 微弱白 → 透明，模拟光泽条
    // begin/end 随 ctrl.value 平移 → 光泽从左到右持续移动
    final grad = LinearGradient(
      colors: [Colors.transparent, Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.08), Colors.transparent],
      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      // 动画值映射到 [-1, 3] 区间，确保光泽带始终覆盖可见区域
      begin: Alignment(-1.0 + ctrl.value * 2, 0),
      end: Alignment(1.0 + ctrl.value * 2, 0),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 6,
        // 底色：深色背景槽
        color: AppColors.jadeHover,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          // 按 progress 比例裁剪左侧填充区域
          widthFactor: progress,
          child: ShaderMask(
            // 将渐变作为着色器应用到填充区域
            shaderCallback: (bounds) => grad.createShader(bounds),
            // srcATop: 渐变只覆盖在彩色条上方，透明区域显示彩色条本色
            blendMode: BlendMode.srcATop,
            child: Container(color: color),
          ),
        ),
      ),
    );
  }
}
