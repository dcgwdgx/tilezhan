/// 个人资料页 — 展示玩家 ELO 评分、连胜记录及段位等级。
///
/// 数据来源为本地持久化存储（[StorageService]），包含三种核心指标：
/// - **ELO** — 对战匹配分，初始值 1000，根据对局胜负浮动。
/// - **Streak** — 连胜/连败计数器，体现近期战绩趋势。
/// - **Level** — 由 ELO 映射的段位（Beginner → Learner → Adept → Expert → Master）。
///
/// 页面同时预留了账号登录、恢复购买、动画速度与每日目标等偏好设置入口（目前为占位状态）。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/storage_provider.dart';
import '../../../core/storage/storage_service.dart';

/// 个人资料 ELO / 战绩屏幕。
///
/// 顶部展示头像与段位，中部以三栏网格显示 ELO / Streak / Level 三项核心数据，
/// 下方依次排列账号与偏好设置分组。
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  /// 构建个人资料页整体 UI。
  ///
  /// 页面布局自上而下依次为：
  /// 1. **头像 + 段位名称** — 中央圆形头像 + 段位中文名 + 等级数字。
  /// 2. **三栏数据卡片** — ELO 分 / Streak 连胜记录 / Level 段位等级。
  /// 3. **账号操作分组** — 登录与恢复购买入口（当前为占位状态）。
  /// 4. **偏好设置分组** — 动画速度与每日目标入口（当前为占位状态）。
  /// 5. **版本号** — 底部居中的应用版本信息。
  ///
  /// 数据源为 [StorageService]，ELO 默认值 1000，Streak 默认值 0。
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider).valueOrNull;
    final elo = storage?.getInt(StorageService.kElo) ?? 1000;
    final streak = storage?.getInt(StorageService.kStreak) ?? 0;
    final level = _levelFromElo(elo);

    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.jadeWhiteDim),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar + level
          Center(
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.demonPurple, Color(0xFF6C3483)]),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [BoxShadow(color: AppColors.demonPurple.withOpacity(0.3), blurRadius: 16)],
                  ),
                  child: const Center(child: Text('🀄', style: TextStyle(fontSize: 36))),
                ),
                const SizedBox(height: 12),
                Text(level.$1, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.neonGold)),
                const SizedBox(height: 4),
                Text('Lv. $level', style: const TextStyle(fontSize: 13, color: AppColors.jadeWhiteDim)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Stats grid
          Row(
            children: [
              _StatCard(emoji: '⚡', value: '$elo', label: 'ELO'),
              const SizedBox(width: 10),
              _StatCard(emoji: '🔥', value: '$streak', label: 'Streak'),
              const SizedBox(width: 10),
              _StatCard(emoji: '🏆', value: '$level', label: 'Level'),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection('Account', [
            _ListTile(icon: Icons.person_outline, title: 'Sign In', subtitle: 'Coming soon — Firebase'),
            _ListTile(icon: Icons.restore, title: 'Restore Purchases', subtitle: 'Coming soon'),
          ]),
          const SizedBox(height: 24),
          _buildSection('Preferences', [
            _ListTile(icon: Icons.speed, title: 'Animation Speed', subtitle: 'Normal', trailing: true),
            _ListTile(icon: Icons.flag, title: 'Daily Goal', subtitle: '10 cards', trailing: true),
          ]),
          const SizedBox(height: 40),
          const Center(child: Text('TileSlash v1.0.0', style: TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// 构建一个带标题的分组区块。
  ///
  /// 由两部分组成：
  /// - **分组标题** — 小号大写字母，左对齐，带字间距。
  /// - **内容容器** — 圆角卡片，内部纵向排列 [items]。
  ///
  /// 适用于"Account"与"Preferences"等设置分组。
  Widget _buildSection(String title, List<Widget> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.jadeWhiteMuted)),
      ),
      Container(
        decoration: BoxDecoration(color: AppColors.jadeCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.jadeHover)),
        child: Column(children: items),
      ),
    ],
  );

  /// 根据 ELO 分数计算段位名称与等级数字。
  ///
  /// 映射规则（所有阈值均为左闭右开区间）：
  /// - **< 900** → Beginner (Lv.1) — 入门初学阶段。
  /// - **900 ~ 1099** → Learner (Lv.2) — 基础学习阶段。
  /// - **1100 ~ 1299** → Adept (Lv.3) — 熟练掌握阶段。
  /// - **1300 ~ 1499** → Expert (Lv.4) — 专家水准阶段。
  /// - **>= 1500** → Master (Lv.5) — 大师顶峰阶段。
  ///
  /// 返回 `(段位名称, 等级数字)` 元组，用于 UI 展示与牌面对局匹配。
  (String, int) _levelFromElo(int elo) {
    // ELO < 900：入门初学，段位 1
    if (elo < 900) return ('Beginner', 1);
    // ELO 900~1099：基础学习，段位 2
    if (elo < 1100) return ('Learner', 2);
    // ELO 1100~1299：熟练掌握，段位 3
    if (elo < 1300) return ('Adept', 3);
    // ELO 1300~1499：专家水准，段位 4
    if (elo < 1500) return ('Expert', 4);
    // ELO >= 1500：大师顶峰，段位 5
    return ('Master', 5);
  }
}

/// 个人资料页三栏数据卡片组件。
///
/// 展示单项统计数据，由三部分组成：
/// - **emoji** — 顶部图标（如 ⚡🔥🏆），视觉化标识数据类别。
/// - **value** — 中部数值文本，高亮白色加粗。
/// - **label** — 底部标签（如 ELO / Streak / Level），小号弱色文本。
///
/// 整个卡片通过 [Expanded] 均分父级 [Row] 的水平空间。
class _StatCard extends StatelessWidget {
  /// 顶部 emoji 图标字符（如 ⚡🔥🏆）。
  final String emoji;
  /// 中部数值文本（ELO 分数 / Streak 计数 / Level 数字）。
  final String value;
  /// 底部数据类别标签。
  final String label;

  /// 创建一个数据卡片。
  ///
  /// 三个参数均为必传，分别对应图标、数值与标签。
  const _StatCard({required this.emoji, required this.value, required this.label});

  /// 构建单个数据卡片的 UI。
  ///
  /// 返回一个 [Expanded] 包裹的圆角容器，内部纵向排列 emoji、value 与 label。
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.jadeCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.jadeHover)),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.jadeWhite)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.jadeWhiteMuted)),
      ]),
    ),
  );
}

/// 个人资料页设置项行组件。
///
/// 封装 [ListTile] 用于展示单项设置入口，支持两种视觉状态：
/// - **可交互（trailing = true）** — 图标金色高亮、标题白色，表示该项可点击进入。
/// - **占位（trailing = false）** — 图标与标题半透明弱化，表示该项尚未实现。
class _ListTile extends StatelessWidget {
  /// 行首 Material 图标。
  final IconData icon;
  /// 设置项标题文本。
  final String title;
  /// 设置项副标题 / 当前值文本。
  final String subtitle;
  /// 是否为可交互状态（true = 金色高亮可点击，false = 半透明占位禁用）。
  final bool trailing;

  /// 创建一个设置项行。
  ///
  /// [icon]、[title]、[subtitle] 为必传参数。
  /// [trailing] 默认为 `false`（占位态），设为 `true` 时启用金色高亮可交互样式。
  const _ListTile({required this.icon, required this.title, required this.subtitle, this.trailing = false});

  /// 构建设置项行的 UI。
  ///
  /// 根据 [trailing] 状态切换颜色方案：
  /// - **trailing = true**：图标 [AppColors.neonGold]，标题 [AppColors.jadeWhite]，[enabled] = true。
  /// - **trailing = false**：图标与标题均为半透明弱色，[enabled] = false（不可点击）。
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: trailing ? AppColors.neonGold : AppColors.jadeWhiteMuted.withOpacity(0.4), size: 22),
    title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: trailing ? AppColors.jadeWhite : AppColors.jadeWhite.withOpacity(0.4))),
    subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted.withOpacity(0.5))),
    enabled: trailing,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
  );
}
