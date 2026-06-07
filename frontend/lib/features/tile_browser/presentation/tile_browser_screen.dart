import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/tile_model.dart';
import '../../../core/providers/tile_data_provider.dart';

class TileBrowserScreen extends ConsumerWidget {
  const TileBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tilesAsync = ref.watch(tileDataProvider);

    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      appBar: AppBar(
        backgroundColor: AppColors.jadeDeep,
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
          onTap: () => _showMnemonic(context, tile),
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
                Text(tile.mnemonic.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 2),
                Text(tile.character, style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900,
                  fontFamily: 'Noto Serif SC', color: AppColors.jadeWhite,
                )),
                Text(tile.seal, style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: suitColors[tile.suit] ?? AppColors.jadeWhiteDim,
                )),
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.jadeDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tile.mnemonic.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.celadonBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(tile.mnemonic.anchor, style: const TextStyle(
                fontSize: 10, color: AppColors.celadonBlue,
              )),
            ),
          ],
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
