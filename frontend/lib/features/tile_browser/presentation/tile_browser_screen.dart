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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tilesAsync = ref.watch(tileDataProvider);

    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
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
      body: tilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tiles) => _buildGrid(context, tiles),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<TileModel> tiles) {
    final suitColors = {
      TileSuit.man: AppColors.suitMan,
      TileSuit.pin: AppColors.suitPin,
      TileSuit.sou: AppColors.suitSou,
      TileSuit.wind: AppColors.suitWind,
      TileSuit.dragon: AppColors.suitDragon,
    };

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: tiles.length,
      itemBuilder: (_, i) {
        final tile = tiles[i];
        return GestureDetector(
          onTap: () {
            AudioService.playVoice(tile.id);
            _showMnemonic(context, tile);
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.jadeCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (suitColors[tile.suit] ?? AppColors.jadeHover).withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TzTile(tile: tile, size: TileSize.sm),
                const SizedBox(height: 2),
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

  void _showMnemonic(BuildContext context, TileModel tile) {
    final pngPath = 'assets/mnemonic_png/${tile.id}.png';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.jadeDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(pngPath, height: 280, fit: BoxFit.contain),
                ),
                const SizedBox(height: 12),
                Text(tile.mnemonic.name, style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.neonGold,
                )),
                const SizedBox(height: 4),
                Text(tile.mnemonic.slogan, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.jadeWhite,
                )),
                const SizedBox(height: 8),
                Text(tile.mnemonic.desc, textAlign: TextAlign.center, style: const TextStyle(
                  fontSize: 12, color: AppColors.jadeWhiteDim, height: 1.5,
                )),
                const SizedBox(height: 8),
                Text(tile.mnemonic.chinese, style: const TextStyle(
                  fontSize: 11, color: AppColors.jadeWhiteMuted, fontStyle: FontStyle.italic,
                )),
              ],
            ),
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppColors.neonGold)),
            ),
          ),
        ],
      ),
    );
  }
}
