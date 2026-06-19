/// 役种扫描参考列表 — 展示一副参考手牌可能组成的全部役种。
///
/// MVP 阶段提供一个精选的基础役种列表，每个役种带图标、名称、
/// 英文名、简介以及解锁状态。V2 将加入完整的手牌扫描功能。
///
/// Screen 组成结构（自上而下）：
/// 1. AppBar — 标题 + 搜索图标（占位）
/// 2. 顶部信息卡片 — 说明当前为参考模式，V2 将支持全手牌扫描
/// 3. 章节标题 — "BASIC YAKU"（基础役种）
/// 4. 役种卡片列表 — 10 张 [_YakuCard]，每张展示一个役种及其解锁状态
///
/// 数据源：静态常量 [_yakuList]，MVP 阶段硬编码 10 个基础役种
/// 解锁逻辑：前 6 个默认解锁，后 4 个锁定（V2 将改为动态扫描）
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../yaku_detail/domain/yaku_data.dart';
import '../../yaku_detail/domain/yaku_favorites_provider.dart';

/// 役种扫描器主页面 — 展示基础役种列表供玩家参考。
///
/// 继承 [ConsumerWidget]，可通过 Riverpod 读取全局状态（为 V2 扫描准备好扩展点）。
/// 当前 MVP 阶段仅渲染静态数据，不绑定任何 provider。
class ScannerScreen extends ConsumerWidget {
  /// 常量化构造函数，接受可选的 [Key] 用于 Widget 树中的身份标识。
  const ScannerScreen({super.key});

  /// 役种静态数据列表。
  ///
  /// 每条记录是一个 6 元组：
  ///   - 字段1 (String): emoji  — 役种图标，用于卡片首列展示
  ///   - 字段2 (String): name   — 日文/罗马字役种名（如 Tanyao, Pinfu）
  ///   - 字段3 (String): eng    — 英文译名（如 All Simples, Peace）
  ///   - 字段4 (String): desc   — 一句话中文/英文简介，描述组成条件
  ///   - 字段5 (bool):   unlocked — true=已解锁可点击；false=锁定仅展示
  ///   - 字段6 (String): id     — 路由标识符，用于跳转 `/yaku/$id` 详情页
  ///
  /// 当前 MVP 阶段：
  ///   - 前 6 个役种（Tanyao ~ Honitsu）默认为 unlocked=true
  ///   - 后 4 个役种（Toitoi ~ Chinitsu）默认为 unlocked=false
  /// V2 阶段：unlocked 将由手牌扫描结果动态决定。
  static const _yakuList = [
    ('🥪', 'Tanyao', 'All Simples', 'No terminals or honors. Only tiles 2-8.', true, 'tanyao'),
    ('🛗', 'Pinfu', 'Peace', 'All sequences, pair not a value honor, two-sided wait.', true, 'pinfu'),
    ('🔫', 'Riichi', 'Ready Hand', 'Declare riichi when in tenpai. 1 han + chance for uradora.', true, 'riichi'),
    ('👑', 'Yakuhai', 'Value Honors', 'Triplet of dragons, seat wind, or round wind.', true, 'yakuhai'),
    ('🌀', 'Iipeikou', 'Pure Double Sequence', 'Two identical sequences in the same suit. Closed only.', true, 'iipeiko'),
    ('🎨', 'Honitsu', 'Half Flush', 'All tiles from one suit + honors. Common intermediate yaku.', true, 'honitsu'),
    ('👯', 'Toitoi', 'All Triplets', 'Four triplets + one pair. Open or closed.', false, 'toitoi'),
    ('🚢', 'Chiitoitsu', 'Seven Pairs', 'Seven distinct pairs. Always closed. 2 han.', false, 'chitoitsu'),
    ('🏔️', 'Chanta', 'Terminal in Each Set', 'Every meld and pair contains a terminal or honor.', false, 'chanta'),
    ('🧹', 'Chinitsu', 'Full Flush', 'All tiles from a single suit. 6 han (menzen) or 5 han (open).', false, 'chinitsu'),
  ];

  /// 构建扫描器页面 UI。
  ///
  /// 布局层次：
  /// ```dart
  /// Scaffold
  /// ├─ AppBar（左侧返回按钮 + 标题"Yaku Scanner" + 右侧搜索图标占位）
  /// └─ ListView
  ///     ├─ 顶部信息卡片（"Yaku Reference"说明 + V2预告）
  ///     ├─ 章节标题 "BASIC YAKU"
  ///     └─ 役种卡片列表（遍历 [_yakuList] 生成 [_YakuCard]）
  /// ```
  ///
  /// 交互说明：
  /// - 点击 AppBar 返回按钮 → [context.pop()] 回退到上一页
  /// - 点击已解锁的役种卡片 → [context.push('/yaku/$id')] 跳转详情页
  /// - 已锁定卡片不可点击（[GestureDetector.onTap] 为 null）
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final favorites = ref.watch(yakuFavoritesProvider);

    return Scaffold(
      // 深翡翠底色，与全局 AppBar 风格统一
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        // 左侧返回按钮：调用 GoRouter 的 pop 回退
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.jadeWhiteDim),
          onPressed: () => context.pop(),
        ),
        // 标题
        title: Text(l10n.scannerTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        // 右侧操作区：搜索图标（V2 将实现搜索过滤功能）
        actions: [
          const Text('🔍', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ===== 顶部信息卡片 =====
          // 告知用户当前为参考模式，V2 升级后将支持全手牌扫描
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.jadeCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.neonGold.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Text('📸', style: TextStyle(fontSize: 32)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.scannerTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.jadeWhite)),
                      SizedBox(height: 4),
                      Text(l10n.scannerDesc, style: const TextStyle(fontSize: 12, color: AppColors.jadeWhiteDim)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ===== 收藏分区 =====
          if (favorites.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(l10n.scannerFavorites, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.neonGold)),
            const SizedBox(height: 8),
            ..._buildYakuCards(favorites.toList(), allYaku),
          ],
          const SizedBox(height: 20),
          // ===== 按难度分组 =====
          ..._buildGroupedYaku(allYaku, l10n),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Build difficulty-grouped yaku sections with collapsible expansion tiles.
  ///
  /// Groups yaku into 4 sections: Beginner → Intermediate → Advanced → Yakuman.
  /// Each section uses an [ExpansionTile] with a difficulty-appropriate emoji.
  /// Beginner section is expanded by default.
  List<Widget> _buildGroupedYaku(List<YakuData> source, AppLocalizations l10n) {
    final groups = <String, List<YakuData>>{
      'Beginner': [],
      'Intermediate': [],
      'Advanced': [],
      'Yakuman': [],
    };
    for (final y in source) {
      if (y.han >= 13) {
        groups['Yakuman']!.add(y);
      } else {
        groups[y.difficulty]?.add(y);
      }
    }

    final titles = {
      'Beginner': l10n.scannerBeginner,
      'Intermediate': l10n.scannerIntermediate,
      'Advanced': l10n.scannerAdvanced,
      'Yakuman': l10n.scannerYakuman,
    };
    final icons = {'Beginner': '🌱', 'Intermediate': '🔥', 'Advanced': '💎', 'Yakuman': '👑'};
    final counts = {'Beginner': '1–2 han', 'Intermediate': '2–3 han', 'Advanced': '5–6 han', 'Yakuman': '13+ han'};

    final widgets = <Widget>[];
    bool first = true;
    for (final entry in groups.entries) {
      if (entry.value.isEmpty) continue;
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.jadeCard.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            initiallyExpanded: first,
            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppColors.jadeCard.withOpacity(0.3),
            collapsedBackgroundColor: Colors.transparent,
            leading: Text(icons[entry.key] ?? '🀄', style: const TextStyle(fontSize: 20)),
            title: Text(titles[entry.key] ?? entry.key, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.jadeWhite)),
            subtitle: Text('${l10n.scannerYakuCount(entry.value.length)} · ${counts[entry.key] ?? ''}',
              style: const TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted)),
            children: entry.value.map((y) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _YakuCard(_emojiForYaku(y.id), y.nameEn, y.nameJp, y.description, true, y.id),
            )).toList(),
          ),
        ),
      );
      first = false;
    }
    return widgets;
  }

  /// Build yaku card widgets from a list of yaku IDs, sourcing data from [source].
  List<Widget> _buildYakuCards(List<String> ids, List<YakuData> source) {
    return ids.map((id) {
      final yaku = getYakuById(id);
      if (yaku == null) return const SizedBox.shrink();
      final emoji = _emojiForYaku(id);
      return _YakuCard(emoji, yaku.nameEn, yaku.nameJp, yaku.description, true, yaku.id);
    }).toList();
  }

  /// Map a yaku ID to a representative emoji for the card icon.
  static String _emojiForYaku(String id) {
    const map = {
      'riichi': '🔫', 'tanyao': '🥪', 'pinfu': '🛗', 'yakuhai': '👑',
      'iipeiko': '🌀', 'chanta': '🏔️', 'honitsu': '🎨', 'chitoitsu': '🚢',
      'toitoi': '👯', 'sanshoku': '🌈', 'ikkitsukan': '🚂', 'chinitsu': '🧹',
      'menzen_tsumo': '🤲', 'ippatsu': '⚡', 'haitei': '🌊', 'houtei': '🐟',
      'rinshan_kaihou': '🏔️', 'chankan': '🏴‍☠️', 'double_riichi': '⚡⚡',
      'sanshoku_doukou': '🎲', 'san_kantsu': '📦', 'san_ankou': '🤫',
      'shousangen': '🐉', 'honroutou': '👴', 'junchan': '🧼', 'ryanpeikou': '🪞',
      'kokushi_musou': '👑', 'daisangen': '🐲', 'shousuushi': '🌪️', 'daisuushi': '🌪️🌪️',
      'tsuuiisou': '📜', 'ryuuiisou': '💚', 'chinroutou': '💀',
      'chuuren_poutou': '🚪', 'suu_kantsu': '📚', 'tenhou': '☁️', 'chiihou': '🌍',
      'suu_ankou': '🤐', 'nagashi_mangan': '🌊',
    };
    return map[id] ?? '🀄';
  }
}

/// 役种卡片组件 — 私有 StatelessWidget，展示单个役种的信息。
///
/// 视觉表现：
/// - 已解锁（unlocked=true）：完整不透明度、霓虹金色役种名、可点击跳转
/// - 已锁定（unlocked=false）：半透明降低视觉权重、役种名灰化、末尾显示 🔒 图标
///
/// 交互：已解锁卡片点击后通过 [GoRouter.push] 导航至 `/yaku/$id` 详情页
class _YakuCard extends StatelessWidget {
  /// 役种表情图标，如 '🥪'、'🛗' 等。
  final String emoji;

  /// 役种日文/罗马字名，如 'Tanyao'、'Pinfu'。
  final String name;

  /// 役种英文译名，如 'All Simples'、'Peace'。
  final String eng;

  /// 役种简介，描述组成条件（中英混合）。
  final String desc;

  /// 唯一标识符，用于构造详情页路由 `/yaku/$id`。
  final String id;

  /// 解锁状态：true 表示可查看详情，false 表示锁定，仅可预览基本信息。
  final bool unlocked;

  /// 位置参数构造函数。
  ///
  /// 参数顺序与 [_yakuList] 中每条元组的字段顺序一致：
  /// [emoji] → [name] → [eng] → [desc] → [unlocked] → [id]
  const _YakuCard(this.emoji, this.name, this.eng, this.desc, this.unlocked, this.id);

  /// 构建役种卡片 UI。
  ///
  /// 卡片由一行构成：
  /// ```dart
  /// Row
  /// ├─ emoji 图标（28px，锁定态降低不透明度）
  /// ├─ 12px 间距
  /// ├─ Expanded 列
  /// │   ├─ Row: 役种名（霓虹金/灰化）+ 英文名（锁定态更淡）
  /// │   └─ 简介文字（锁定态极低不透明度）
  /// └─ 若锁定：🔒 图标
  /// ```
  ///
  /// 解锁状态影响：
  /// - 卡片背景：[AppColors.jadeCard] 完整 vs 40% 不透明度
  /// - 卡片边框：[AppColors.jadeHover] 完整 vs 30% 不透明度
  /// - 文字颜色：neonGold/jadeWhiteDim vs jadeWhiteMuted 低不透明度
  /// - 可点击性：[onTap] 设为导航回调 vs null（禁用点击）
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 仅已解锁卡片响应点击，跳转到役种详情页
      onTap: unlocked ? () => context.push('/yaku/$id') : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // 锁定卡片背景降低不透明度，视觉上后退一层
          color: unlocked ? AppColors.jadeCard : AppColors.jadeCard.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          // 锁定卡片边框同样降低不透明度
          border: Border.all(color: unlocked ? AppColors.jadeHover : AppColors.jadeHover.withOpacity(0.3)),
        ),
        child: Row(children: [
          // 首列：役种 emoji 图标，锁定态降低不透明度
          Text(emoji, style: TextStyle(fontSize: 28, color: unlocked ? null : AppColors.jadeWhiteMuted.withOpacity(0.4))),
          const SizedBox(width: 12),
          // 中间列：役种名 + 英文名 + 简介，文字颜色均受解锁状态影响
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // 役种日文名 — 已解锁为霓虹金色醒目标识，锁定为灰色
              Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: unlocked ? AppColors.neonGold : AppColors.jadeWhiteMuted)),
              const SizedBox(width: 8),
              // 役种英文名 — 已解锁为暗白，锁定为进一步淡化的灰色
              Text(eng, style: TextStyle(fontSize: 11, color: unlocked ? AppColors.jadeWhiteDim : AppColors.jadeWhiteMuted.withOpacity(0.4))),
            ]),
            const SizedBox(height: 2),
            // 役种简介 — 锁定态极低不透明度，几乎不可读
            Text(desc, style: TextStyle(fontSize: 11, color: unlocked ? AppColors.jadeWhiteDim : AppColors.jadeWhiteMuted.withOpacity(0.3))),
          ])),
          // 末列：锁定图标，仅锁定卡片显示
          if (!unlocked) const Text('🔒', style: TextStyle(fontSize: 14)),
        ]),
      ),
    );
  }
}
