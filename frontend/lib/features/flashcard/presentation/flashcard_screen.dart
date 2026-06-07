import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/tile_model.dart';
import '../domain/flashcard_provider.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  final String suite;
  const FlashcardScreen({super.key, this.suite = 'all'});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  Timer? _countdownTimer;
  double _countdownValue = 1.5;
  static const _totalTime = 1.5;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(flashcardQuizProvider.notifier).initQuiz(suite: widget.suite);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownValue = _totalTime;
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _countdownValue -= 0.05;
      if (_countdownValue <= 0) {
        _countdownValue = 0;
        timer.cancel();
        final state = ref.read(flashcardQuizProvider);
        if (!state.isAnswering) {
          _handleTimeout();
        }
      }
      setState(() {});
    });
  }

  void _handleTimeout() {
    ref.read(flashcardQuizProvider.notifier).submitAnswer(false);
  }

  void _handleAnswer(bool isCorrect) {
    ref.read(flashcardQuizProvider.notifier).submitAnswer(isCorrect);
    _countdownTimer?.cancel();
    setState(() {});
  }

  void _showMnemonic() {
    ref.read(flashcardQuizProvider.notifier).showMnemonic();
    setState(() {});
  }

  void _hideMnemonic() {
    ref.read(flashcardQuizProvider.notifier).hideMnemonic();
    _startCountdown();
    Future.delayed(const Duration(milliseconds: 300), () {
      ref.read(flashcardQuizProvider.notifier).nextCard();
      _startCountdown();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flashcardQuizProvider);
    final tile = state.currentTile;

    if (tile == null && state.totalCount == 0) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.isFinished) {
      return _buildFinishedScreen(state);
    }

    _startCountdownIfNeeded();

    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(state),
                const SizedBox(height: 12),
                _buildSuitFilter(state),
                const Spacer(),
                _buildCountdownRing(),
                const SizedBox(height: 16),
                _buildTileDisplay(tile!),
                const SizedBox(height: 24),
                _buildOptions(tile, state),
                const SizedBox(height: 8),
                _buildProgressDots(state),
                const SizedBox(height: 8),
                _buildHint(),
                const Spacer(),
              ],
            ),
            if (state.isShowingMnemonic)
              _buildMnemonicOverlay(tile),
            if (state.isAnswering && state.lastCorrectId != null)
              _buildSuccessBar(tile),
          ],
        ),
      ),
    );
  }

  bool _countdownStarted = false;
  void _startCountdownIfNeeded() {
    final state = ref.read(flashcardQuizProvider);
    if (!state.isAnswering && !_countdownStarted) {
      _countdownStarted = true;
      _startCountdown();
    }
    if (state.isAnswering) {
      _countdownStarted = false;
    }
  }

  Widget _buildTopBar(state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.jadeCard, borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.close, color: AppColors.jadeWhiteDim, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.suite == 'all' ? 'All Tiles' : '${state.suite.toUpperCase()} Flashcards',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.jadeWhite)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: state.progress,
                    backgroundColor: AppColors.jadeHover,
                    color: AppColors.neonGold,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('⚡${state.currentIndex + 1}/${state.totalCount}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.neonGold)),
        ],
      ),
    );
  }

  Widget _buildSuitFilter(state) {
    final suits = [
      ('all', '🎴 All'),
      ('man', '🀇 Man'),
      ('pin', '🀙 Pin'),
      ('sou', '🀐 Sou'),
      ('honor', '🀀 Honor'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: suits.map((s) {
          final isActive = state.suite == s.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ref.read(flashcardQuizProvider.notifier).initQuiz(suite: s.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.neonGold.withValues(alpha: 0.15) : AppColors.jadeCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? AppColors.neonGold.withValues(alpha: 0.4) : Colors.transparent,
                  ),
                ),
                child: Text(s.$2, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.neonGold : AppColors.jadeWhiteDim,
                )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCountdownRing() {
    final progress = _countdownValue / _totalTime;
    return SizedBox(
      width: 60, height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: AppColors.jadeHover,
            color: _countdownValue < 0.3 ? AppColors.vermillion : AppColors.neonGold,
          ),
          Text(_countdownValue.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: _countdownValue < 0.3 ? AppColors.vermillion : AppColors.neonGold,
                fontFamily: 'JetBrains Mono',
              )),
        ],
      ),
    );
  }

  Widget _buildTileDisplay(TileModel tile) {
    final state = ref.read(flashcardQuizProvider);
    return GestureDetector(
      onTap: state.isAnswering ? _showMnemonic : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 150, height: 190,
        decoration: BoxDecoration(
          color: AppColors.jadeCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tile.suitColor.withValues(alpha: 0.4), width: 2),
          boxShadow: [
            BoxShadow(
              color: state.lastCorrectId == tile.id
                  ? const Color(0xFF2CE574).withValues(alpha: 0.3)
                  : Colors.black54,
              blurRadius: state.lastCorrectId == tile.id ? 24 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tile.character, style: const TextStyle(
                    fontSize: 52, fontWeight: FontWeight.w900,
                    color: AppColors.jadeWhite,
                    fontFamily: 'Noto Serif SC',
                  )),
                  const SizedBox(height: 4),
                  Text(tile.seal, style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: tile.suitColor,
                  )),
                ],
              ),
            ),
            Positioned(top: 8, right: 10,
              child: Text(tile.label, style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600,
                color: AppColors.celadonLight,
              ))),
            Positioned(bottom: 8, left: 0, right: 0,
              child: Center(
                child: Text(tile.suit.name.toUpperCase(), style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: tile.suitColor,
                )),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions(TileModel tile, state) {
    final distractors = ref.read(flashcardQuizProvider.notifier).getDistractors(tile);
    final options = [...distractors, tile]..shuffle();
    final letters = ['A', 'B', 'C', 'D'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(4, (i) {
          final opt = options[i];
          final isCorrect = opt.id == tile.id;
          Color? bgColor;
          if (state.isAnswering && state.lastCorrectId == tile.id && isCorrect) {
            bgColor = const Color(0xFF2CE574).withValues(alpha: 0.15);
          } else if (state.isAnswering && state.lastWrongId != null && isCorrect) {
            bgColor = const Color(0xFF2CE574).withValues(alpha: 0.15);
          } else if (state.isAnswering && state.lastWrongId == opt.id && !isCorrect) {
            bgColor = AppColors.vermillion.withValues(alpha: 0.12);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: state.isAnswering ? null : () => _handleAnswer(isCorrect),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: bgColor ?? AppColors.jadeCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: bgColor != null
                        ? (isCorrect ? const Color(0xFF2CE574) : AppColors.vermillion)
                        : AppColors.jadeHover,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: bgColor != null
                            ? (isCorrect ? const Color(0xFF2CE574) : AppColors.vermillion)
                            : AppColors.jadeHover,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(letters[i], style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: bgColor != null ? Colors.white : AppColors.jadeWhite,
                        )),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(opt.mnemonic.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(opt.mnemonic.name, style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: bgColor != null ? Colors.white : AppColors.jadeWhite,
                      )),
                    ),
                    Text(opt.label, style: TextStyle(
                      fontSize: 11, color: AppColors.jadeWhiteMuted,
                    )),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProgressDots(state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(state.totalCount, (i) {
        Color color;
        if (i < state.currentIndex) {
          color = AppColors.neonGold;
        } else if (i == state.currentIndex) {
          color = AppColors.neonGold;
        } else {
          color = AppColors.jadeHover;
        }
        return Container(
          width: 6, height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color, shape: BoxShape.circle,
            boxShadow: i == state.currentIndex
                ? [BoxShadow(color: AppColors.neonGold.withValues(alpha: 0.5), blurRadius: 4)]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildHint() {
    return const Text('💡 Tap the tile to reveal its mnemonic story',
        style: TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted));
  }

  Widget _buildMnemonicOverlay(TileModel tile) {
    return GestureDetector(
      onTap: _hideMnemonic,
      child: Container(
        color: AppColors.jadeDeep.withValues(alpha: 0.97),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tile.mnemonic.emoji, style: const TextStyle(fontSize: 72)),
                const SizedBox(height: 12),
                Text(tile.mnemonic.name, style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.neonGold,
                )),
                const SizedBox(height: 4),
                Text(tile.mnemonic.slogan, style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.jadeWhite,
                )),
                const SizedBox(height: 8),
                Text(tile.mnemonic.desc, textAlign: TextAlign.center, style: const TextStyle(
                  fontSize: 13, color: AppColors.jadeWhiteDim, height: 1.6,
                )),
                const SizedBox(height: 12),
                Text(tile.mnemonic.chinese, style: const TextStyle(
                  fontSize: 12, color: AppColors.jadeWhiteMuted, fontStyle: FontStyle.italic,
                )),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.celadonBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(tile.mnemonic.anchor, style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.celadonBlue,
                  )),
                ),
                const SizedBox(height: 24),
                const Text('Tap anywhere to close',
                    style: TextStyle(fontSize: 12, color: AppColors.jadeWhiteMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessBar(TileModel tile) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        color: const Color(0xFF2CE574),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✨', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('"${tile.mnemonic.slogan}"', style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishedScreen(state) {
    final accuracy = state.totalCount > 0
        ? (state.correctCount / state.totalCount * 100).round()
        : 0;
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              const Text('Round Complete!', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.neonGold,
              )),
              const SizedBox(height: 8),
              Text('✅ ${state.correctCount} correct · ❌ ${state.wrongCount} wrong',
                  style: const TextStyle(fontSize: 15, color: AppColors.jadeWhiteDim)),
              const SizedBox(height: 4),
              Text('Accuracy: $accuracy%',
                  style: const TextStyle(fontSize: 13, color: AppColors.jadeWhiteMuted)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(flashcardQuizProvider.notifier).restart(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('🔄 Play Again', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
