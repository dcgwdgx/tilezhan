/// 全牌浏览 34 牌 + 助记
///
/// 展示 34 张麻将牌的网格视图，每张牌附带其助记词（名称、标语、描述、中文）。
/// 点击牌面可播放语音并弹出详细助记对话框。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/audio_service.dart';
import '../../../shared/models/tile_model.dart';
import '../../../shared/widgets/tz_tile.dart';
import '../../../core/providers/tile_data_provider.dart';

/// 全牌浏览页面，34 张麻将牌网格展示，支持点击查看助记详情。
class TileBrowserScreen extends ConsumerWidget {
  const TileBrowserScreen({super.key});

  /// 构建全牌浏览页面主体结构。
  ///
  /// 通过 [tileDataProvider] 异步加载全部 34 张牌数据，渲染 Scaffold：
  /// 顶部导航栏（返回按钮 + 标题 + 牌数统计）+ 主体内容区。
  /// 主体根据异步状态三态切换：加载中转圈、出错显示错误信息、数据就绪渲染网格。
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听牌数据提供者，异步获取全部 34 张牌的模型数据
    final tilesAsync = ref.watch(tileDataProvider);

    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      // 顶部导航栏：返回按钮（go_router pop）+ 标题 + 34 牌金色计数徽章
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
        // 左侧返回按钮，点击调用 go_router 的 pop 返回上一页
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.jadeWhiteDim),
          onPressed: () => context.pop(),
        ),
        title: const Text('Tile Browser', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Text('🀄 34 Tiles', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.neonGold,
          )),
          const SizedBox(width: 16),
        ],
      ),
      // 主体内容区：根据异步加载状态三态切换
      //   loading → 居中转圈指示器
      //   error   → 居中显示错误信息文本
      //   data    → 委托 _buildGrid 渲染 4 列牌面网格
      body: tilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tiles) => _buildGrid(context, tiles),
      ),
    );
  }

  /// 构建 34 张牌的网格滚动视图。
  ///
  /// 使用 [GridView.builder] 以固定 4 列网格排列所有牌面。每张牌的卡片包含：
  /// - [TzTile] 小尺寸牌面组件（含图案和点数）
  /// - 助记名称文本（单行溢出省略）
  ///
  /// 卡片边框颜色根据牌的 [TileSuit] 从 [suitColors] 映射表动态匹配，
  /// 实现万/筒/索/风/箭五种花色的视觉区分。点击卡片触发语音播放和助记弹窗。
  Widget _buildGrid(BuildContext context, List<TileModel> tiles) {
    // 花色 → 边框颜色映射表：万=红, 筒=蓝, 索=绿, 风=青, 箭=紫
    final suitColors = {
      TileSuit.man: AppColors.suitMan,
      TileSuit.pin: AppColors.suitPin,
      TileSuit.sou: AppColors.suitSou,
      TileSuit.wind: AppColors.suitWind,
      TileSuit.dragon: AppColors.suitDragon,
    };

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      // 固定 4 列网格布局：横纵间距各 8px，宽高比 0.72 适配竖长牌型
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      // 牌总数由数据源决定（预期 34 张）
      itemCount: tiles.length,
      itemBuilder: (_, i) {
        final tile = tiles[i];
        // 每张牌卡片：点击 → 播放语音 + 弹出助记详情
        return GestureDetector(
          onTap: () {
            // 播放牌对应的语音助记音频
            AudioService.playVoice(tile.id);
            // 弹出该牌的详细助记对话框
            _showMnemonic(context, tile);
          },
          // 牌卡片容器：玉色背景 + 圆角 + 花色半透明边框
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.jadeCard,
              borderRadius: BorderRadius.circular(10),
              // 花色边框颜色：从映射表按 suit 取值，未匹配时回退到 jadeHover
              border: Border.all(
                color: (suitColors[tile.suit] ?? AppColors.jadeHover).withOpacity(0.3),
              ),
            ),
            // 纵向居中排列：牌面组件在上，助记名称在下
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 小尺寸牌面组件（含麻将图案和点数）
                TzTile(tile: tile, size: TileSize.sm),
                const SizedBox(height: 2),
                // 助记名称：9px 小字，单行溢出省略号
                Text(tile.mnemonic.name, textAlign: TextAlign.center,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, color: AppColors.jadeWhiteMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 弹出助记详情对话框。
  ///
  /// 展示单张牌的完整助记信息，从上到下依次为：
  /// 1. 助记 PNG 图片（圆角裁剪，280px 高度等比缩放）
  /// 2. 助记名称（金色粗体大字）
  /// 3. 助记标语（白色半粗体）
  /// 4. 助记描述（多行居中文本，1.5 倍行高）
  /// 5. 中文释义（斜体淡化小字）
  ///
  /// 对话框使用大圆角玉色背景，内容可滚动以适配不同屏幕高度，
  /// 底部提供居中金色关闭按钮。
  void _showMnemonic(BuildContext context, TileModel tile) {
    // 拼接助记图片资源路径，命名规则：assets/mnemonic_png/{牌ID}.png
    final pngPath = 'assets/mnemonic_png/${tile.id}.png';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.jadeDeep,
        // 大圆角对话框外形（20px 圆角半径）
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        // 内容区宽度固定 300px
        content: SizedBox(
          width: 300,
          // 纵向可滚动，适配小屏设备防止内容溢出
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 助记图片：圆角裁剪，280px 高度等比缩放
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(pngPath, height: 280, fit: BoxFit.contain),
                ),
                const SizedBox(height: 12),
                // 助记名称：金色 20px 超粗体
                Text(tile.mnemonic.name, style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.neonGold,
                )),
                const SizedBox(height: 4),
                // 助记标语：14px 白色半粗体
                Text(tile.mnemonic.slogan, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.jadeWhite,
                )),
                const SizedBox(height: 8),
                // 助记描述：12px 居中多行文本，行高 1.5 倍提升可读性
                Text(tile.mnemonic.desc, textAlign: TextAlign.center, style: const TextStyle(
                  fontSize: 12, color: AppColors.jadeWhiteDim, height: 1.5,
                )),
                const SizedBox(height: 8),
                // 中文释义：11px 斜体淡化，视觉层级最低
                Text(tile.mnemonic.chinese, style: const TextStyle(
                  fontSize: 11, color: AppColors.jadeWhiteMuted, fontStyle: FontStyle.italic,
                )),
              ],
            ),
          ),
        ),
        // 底部操作区：居中金色"Close"关闭按钮
        actions: [
          Center(
            child: TextButton(
              // 点击关闭对话框，返回牌面浏览网格
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppColors.neonGold)),
            ),
          ),
        ],
      ),
    );
  }
}
