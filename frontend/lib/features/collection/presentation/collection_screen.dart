/// 役种收藏册 (Yaku Collection Screen).
///
/// Displays a grid of unlockable Mahjong yaku cards. Unlock progress is driven by
/// SRS review count — every 5 reviews unlocks one additional yaku, up to all 8.
/// Tapping an unlocked card shows a detail dialog with the yaku name, English
/// translation, star mastery rating, and a short description.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/srs/srs_provider.dart';

/// 役种收藏页面 — 展示麻将役种卡片的全屏收藏册。
///
/// 该页面以 3 列网格展示 8 张役种卡片，每张卡片包含 emoji 图标、日文名称、英文译名、
/// 星级评分。未解锁的卡片显示半透明遮罩和锁图标，点击无反应。顶部有一个横向滚动的
/// 分类筛选条（All / Basics / Color / Clone / VIP），当前仅做展示未实现实际筛选逻辑。
/// 解锁进度由 SRS 复习总次数驱动：每 5 次复习解锁一个役种（0~7），进度以 "N/8"
/// 形式显示在 AppBar 右侧。
///
/// 点击已解锁的卡片弹出 [AlertDialog]，展示役种详情：中文名、英文名、熟练掌握度星级、
/// 以及役种说明文字。
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  // ========================================================================
  // 主构建方法
  // ========================================================================

  /// 构建收藏页面整体结构。
  ///
  /// 工作流程：
  /// 1. 从 [srsItemsProvider] 读取所有 SRS 词条，累加每条词的复习次数 `reps + 1`
  ///    （`+1` 表示首次学习也算作一次接触），得到总复习数；
  /// 2. 用 [totalReviews ~/ 5] 计算可解锁数量（每 5 次复习解锁 1 个），
  ///    并通过 `.clamp(0, 7)` 限制在 0~7 之间（共 8 个役种，最后一个永远可见
  ///    但需要前 7 个全部解锁后才能点击）；
  /// 3. 构建 Scaffold，包含自定义的翡翠绿背景、返回箭头、标题、解锁进度文本；
  /// 4. body 为竖向排列：分类筛选条 → 役种网格。
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 读取所有 SRS 卡片数据
    final items = ref.watch(srsItemsProvider);
    // 累加总复习次数：每条词 reps + 1（首次学习也算一次接触）
    final totalReviews = items.values
        .fold(0, (sum, item) => sum + item.reps + 1);
    // 每 5 次复习解锁一个役种，最多 7（共 8 张，索引 0~7）
    final unlocked = (totalReviews ~/ 5).clamp(0, 7);
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        // 左上角返回按钮，调用 GoRouter 的 pop
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.jadeWhiteDim),
          onPressed: () => context.pop(),
        ),
        // 页面标题
        title: const Text('Yaku Collection', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          // 解锁进度指示器：已解锁数 / 总数
          Text('${unlocked + 1}/8', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.neonGold,
          )),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // 顶部分类筛选条
          _buildFilterBar(),
          const SizedBox(height: 8),
          // 役种卡片网格（占满剩余空间）
          Expanded(child: _buildYakuGrid(context, unlocked)),
        ],
      ),
    );
  }

  // ========================================================================
  // 分类筛选条
  // ========================================================================

  /// 构建顶部的横向分类筛选条。
  ///
  /// 筛选条包含 5 个分类标签：[All, ⭐ Basics, 🎨 Color, 👯 Clone, 👑 VIP]。
  /// 当前实现中，只有第一个标签 "All" 处于激活高亮状态（金色半透明背景 +
  /// 金色边框），其余标签为普通卡片样式。暂未接入实际的筛选逻辑，
  /// 标签点击无响应 — 留作后续迭代的扩展点。
  ///
  /// 返回一个可横向滚动的 [SingleChildScrollView]，内嵌水平排列的 [Row]。
  Widget _buildFilterBar() {
    // 分类标签列表，每项包含 emoji 图标前缀作为视觉区分
    final chips = ['All', '⭐ Basics', '🎨 Color', '👯 Clone', '👑 VIP'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: chips.asMap().entries.map((e) {
          // 当前仅第 0 项（All）为激活状态
          final isActive = e.key == 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                // 激活态：金色半透明背景；非激活态：翡翠色卡片背景
                color: isActive ? AppColors.neonGold.withOpacity(0.15) : AppColors.jadeCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  // 激活态：金色半透明边框；非激活态：无边框（透明）
                  color: isActive ? AppColors.neonGold.withOpacity(0.3) : Colors.transparent,
                ),
              ),
              child: Text(e.value, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                // 激活态：金色文字；非激活态：暗白色文字
                color: isActive ? AppColors.neonGold : AppColors.jadeWhiteDim,
              )),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ========================================================================
  // 役种卡片网格
  // ========================================================================

  /// 构建 3 列役种卡片网格。
  ///
  /// 参数 [context] 为 Flutter 构建上下文，用于弹出详情弹窗；
  /// 参数 [unlocked] 为已解锁的役种数量（0~7），索引 ≤ unlocked 的卡片为已解锁状态。
  ///
  /// 网格包含 8 张固定卡片，每张数据为四元组：
  ///   - emoji 图标（视觉标识）
  ///   - 日文役种名（如 Tanyao、Pinfu）
  ///   - 英文译名（如 All Simples、Peace）
  ///   - 星级评分 (1~5)：用于显示掌握熟练度，控制实心星与空心星数量
  ///
  /// 每张卡片的具体行为：
  ///   - 已解锁：显示完整色彩、名称、星级评分，点击弹出详情弹窗
  ///   - 未解锁：显示半透明遮罩、锁图标 (🔒)，点击无反应
  ///
  /// 卡片使用 [AnimatedContainer] 实现背景色平滑过渡（200ms），
  /// 在解锁状态变化时提供视觉动画反馈。
  Widget _buildYakuGrid(BuildContext context, int unlocked) {
    // 役种卡片数据：(emoji, 日文名, 英文译名, 星级评分)
    final yakus = [
      ('🥪', 'Tanyao', 'All Simples', 2),
      ('🛗', 'Pinfu', 'Peace', 3),
      ('🔫', 'Riichi', 'Ready Hand', 2),
      ('🎨', 'Honitsu', 'Half Flush', 3),
      ('🧹', 'Chinitsu', 'Full Flush', 5),
      ('👯', 'Toitoi', 'All Triplets', 4),
      ('🚢', 'Chiitoitsu', 'Seven Pairs', 4),
      ('👑', 'Yakuhai', 'Value Honors', 3),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      // 固定 3 列，间距 10px，宽高比 0.85（卡片略高）
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: yakus.length,
      itemBuilder: (_, i) {
        // 解构当前卡片数据
        final y = yakus[i];
        // 索引 ≤ unlocked 即为已解锁
        final isUnlocked = i <= unlocked;
        return GestureDetector(
          // 已解锁时点击弹出详情弹窗，未解锁时 onTap 为 null（无响应）
          onTap: isUnlocked ? () => _showYakuDetail(context, y.$2, y.$3, y.$4) : null,
          child: AnimatedContainer(
            // 背景色 200ms 平滑过渡，避免状态切换闪烁
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              // 已解锁：正常不透明度卡片；未解锁：40% 透明度
              color: isUnlocked ? AppColors.jadeCard : AppColors.jadeCard.withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                // 已解锁：完整边框色；未解锁：30% 透明度边框
                color: isUnlocked ? AppColors.jadeHover : AppColors.jadeHover.withOpacity(0.3),
              ),
            ),
            // 卡片内容：emoji + 日文名 + 英文名 + (星级 | 锁)
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 役种 emoji 图标，未解锁时呈 40% 透明度
                Text(y.$1, style: TextStyle(
                  fontSize: 32, color: isUnlocked ? null : AppColors.jadeWhiteMuted.withOpacity(0.4),
                )),
                const SizedBox(height: 4),
                // 日文役种名，未解锁时使用 muted 暗色
                Text(y.$2, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: isUnlocked ? AppColors.jadeWhite : AppColors.jadeWhiteMuted,
                )),
                // 英文译名，字号更小，未解锁时更深暗
                Text(y.$3, style: TextStyle(
                  fontSize: 10,
                  color: isUnlocked ? AppColors.jadeWhiteMuted : AppColors.jadeWhiteMuted.withOpacity(0.4),
                )),
                const SizedBox(height: 2),
                // 已解锁：显示星级（实心星 + 空心星）；未解锁：显示锁图标
                if (isUnlocked)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    // 生成 3 颗星，前 star 颗为实心，其余为空心
                    children: List.generate(3, (s) => Icon(
                      s < y.$4 ? Icons.star : Icons.star_border,
                      color: AppColors.neonGold, size: 14,
                    )),
                  )
                else
                  const Text('🔒', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========================================================================
  // 役种详情弹窗
  // ========================================================================

  /// 弹出役种详情对话框。
  ///
  /// 参数说明：
  ///   - [context]: Flutter 构建上下文，用于调用 [showDialog]
  ///   - [name]: 役种日文名（如 "Tanyao"）
  ///   - [engName]: 役种英文译名（如 "All Simples"）
  ///   - [stars]: 掌握熟练度星级 (1~5)，用于生成星标字符串
  ///
  /// 对话框使用 [AlertDialog] 组件，内容包含：
  ///   1. 日文役种名（金色标题）
  ///   2. 英文译名（暗白色副标题）
  ///   3. 熟练掌握度：以 ⭐☆ 组合表示（如 ⭐⭐☆）
  ///   4. 役种说明文字（当前为通用占位文本，后续可为每种役种定制）
  ///   5. "Close" 关闭按钮（金色文字）
  ///
  /// 对话框背景色为 [AppColors.jadeDeep]，与收藏页面整体风格一致。
  void _showYakuDetail(BuildContext context, String name, String engName, int stars) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.jadeDeep,
        // 圆角 20px，与卡片风格统一
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        // 标题：役种日文名，金色粗体
        title: Text(name, style: const TextStyle(
          fontWeight: FontWeight.w800, color: AppColors.neonGold,
        )),
        content: Column(
          // 内容垂直紧凑排列，左对齐
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 英文译名
            Text(engName, style: const TextStyle(color: AppColors.jadeWhiteDim)),
            const SizedBox(height: 8),
            // 熟练掌握度：根据 stars 参数生成 ⭐☆ 组合字符串
            Text('Mastery: ${'⭐' * stars}${'☆' * (3 - stars)}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            // 役种说明（当前为占位通用文本，后续迭代可替换为各役种的实际说明）
            const Text('This Yaku requires all tiles to be within 2-8 range, with no terminals or honor tiles.',
                style: TextStyle(fontSize: 13, color: AppColors.jadeWhiteDim)),
          ],
        ),
        actions: [
          // 关闭按钮
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.neonGold)),
          ),
        ],
      ),
    );
  }
}
