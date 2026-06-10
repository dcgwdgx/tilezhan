import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/tz_tile.dart';
import '../../../shared/models/tile_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  static const _totalSteps = 3;

  // Interactive state
  bool _tileTapped = false;
  bool _answerSelected = false;

  final _demoTile = TileModel(
    id: 'm5', suit: TileSuit.man, character: '五', seal: '萬',
    value: 5, label: '5-Man',
    mnemonic: const MnemonicData(
      emoji: '🏖️', name: 'The Lawn Chair', slogan: 'Max relaxation!',
      desc: 'This 5-Man tile looks like a folding lawn chair — perfect for beach vibes.',
      chinese: '沙滩椅', anchor: 'Beach Chair',
    ),
    confusedWith: const ['m4', 'm6'],
  );

  void _nextStep() {
    if (_step < _totalSteps - 1) {
      setState(() {
        _step++;
        _tileTapped = false;
        _answerSelected = false;
      });
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(child: _buildStepContent()),
                _buildBottomNav(),
              ],
            ),
            // Skip button
            Positioned(
              top: 8, right: 16,
              child: TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Skip', style: TextStyle(color: AppColors.jadeWhiteMuted)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0: return _buildStep0();
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      default: return const SizedBox();
    }
  }

  // Step 0: Tap a tile to see its mnemonic
  Widget _buildStep0() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🀄', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Tap the Tile', style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.jadeWhite,
          )),
          const SizedBox(height: 8),
          const Text('Each mahjong tile has a hidden story.\nTap it to reveal the visual mnemonic.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.jadeWhiteDim, height: 1.5),
          ),
          const SizedBox(height: 32),
          // Interactive tile
          GestureDetector(
            onTap: () => setState(() => _tileTapped = true),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  opacity: _tileTapped ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    children: [
                      TzTile(tile: _demoTile, size: TileSize.lg),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.neonGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.neonGold.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('👆 ', style: TextStyle(fontSize: 16)),
                            Text('TAP ME', style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.neonGold,
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Mnemonic overlay
                if (_tileTapped)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.jadeCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.neonGold.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_demoTile.mnemonic.emoji, style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        Text(_demoTile.mnemonic.name, style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.neonGold,
                        )),
                        const SizedBox(height: 4),
                        Text(_demoTile.mnemonic.desc, textAlign: TextAlign.center, style: const TextStyle(
                          fontSize: 13, color: AppColors.jadeWhiteDim,
                        )),
                        const SizedBox(height: 12),
                        const Text('✅ Got it!', style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2CE574),
                        )),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: Flashcard quiz — pick the right answer
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🃏', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Flashcard Quiz', style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.jadeWhite,
          )),
          const SizedBox(height: 8),
          const Text('See a tile → pick its name.\nGreen = correct, Red = wrong.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.jadeWhiteDim, height: 1.5),
          ),
          const SizedBox(height: 24),
          // Mini quiz
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.jadeCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.jadeHover),
            ),
            child: Column(
              children: [
                TzTile(tile: _demoTile, size: TileSize.md),
                const SizedBox(height: 16),
                const Text('Which tile is this?', style: TextStyle(fontSize: 13, color: AppColors.jadeWhiteDim)),
                const SizedBox(height: 12),
                ...['The Lawn Chair', 'The Coat Hanger', 'The Rocket', 'The Volcano'].map((name) {
                  final isCorrect = name == 'The Lawn Chair';
                  final isWrong = _answerSelected && !isCorrect && name != 'The Lawn Chair';
                  Color? bg = _answerSelected
                      ? (isCorrect ? const Color(0xFF2CE574).withOpacity(0.15) : null)
                      : null;
                  if (isWrong) bg = AppColors.vermillion.withOpacity(0.12);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: GestureDetector(
                      onTap: _answerSelected ? null : () => setState(() => _answerSelected = true),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: bg ?? AppColors.jadeHover.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: bg != null
                                ? (isCorrect ? const Color(0xFF2CE574) : AppColors.vermillion)
                                : AppColors.jadeHover,
                          ),
                        ),
                        child: Text(name, style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: bg != null ? Colors.white : AppColors.jadeWhite,
                        )),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Nani-Kiru — discard one tile
  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚔️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Nani-Kiru', style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.jadeWhite,
          )),
          const SizedBox(height: 8),
          const Text('"What to discard?" — The ultimate question.\nPick the tile that gives you the best chance to win.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.jadeWhiteDim, height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.jadeCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.jadeHover),
            ),
            child: Column(
              children: [
                const Text('YOUR HAND (14 tiles)', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2,
                  color: AppColors.jadeWhiteMuted,
                )),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4, runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: ['m1', 'm2', 'm3', 'm5', 'm6', 'm7', 'm9', 'p1', 'p5'].map((id) {
                    return TzTile(
                      tile: TileModel(
                        id: id, suit: TileSuit.man, character: id[1], seal: '萬',
                        value: 1, label: id,
                        mnemonic: const MnemonicData(emoji: '', name: '', slogan: '', desc: '', chinese: '', anchor: ''),
                        confusedWith: const [],
                      ),
                      size: TileSize.sm,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.neonGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.neonGold.withOpacity(0.3)),
                  ),
                  child: const Text('👆 Tap a tile to select it,\ntap again to confirm your discard.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.neonGold, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Row(
        children: [
          // Dots
          Row(
            children: List.generate(_totalSteps, (i) => Container(
              width: i == _step ? 24 : 8, height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i == _step ? AppColors.neonGold : AppColors.jadeHover,
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _step == 0 && !_tileTapped
                ? null
                : _step == 1 && !_answerSelected
                    ? null
                    : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vermillion,
              disabledBackgroundColor: AppColors.jadeHover,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(
              _step == _totalSteps - 1 ? 'GET STARTED' : 'NEXT →',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
