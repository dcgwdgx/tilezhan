import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/audio_service.dart';
import '../../../core/srs/srs_provider.dart';
import '../../../shared/models/tile_model.dart';
import '../../../shared/widgets/tz_countdown_ring.dart';
import '../../../shared/widgets/tz_progress_bar.dart';
import '../../../shared/widgets/tz_pulse_painter.dart';
import '../domain/flashcard_provider.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  final String suite;
  const FlashcardScreen({super.key, this.suite = 'all'});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  Timer? _countdownTimer;
  double _countdownValue = 8.0;
  late AnimationController _feedbackCtrl;
  bool _lastAnswerCorrect = false;
  static const _totalTime = 8.0;

  @override
  void initState() {
    super.initState();
    _feedbackCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    Future.microtask(() {
      ref.read(flashcardQuizProvider.notifier).initQuiz(suite: widget.suite);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    _countdownStarted = false;
  }

  void _startCountdown({bool playVoice = false}) {
    _countdownTimer?.cancel();
    _countdownValue = _totalTime;
    if (playVoice) {
      final tile = ref.read(flashcardQuizProvider).currentTile;
      if (tile != null) AudioService.playVoice(tile.id);
    }
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
    AudioService.playWrong();
    ref.read(flashcardQuizProvider.notifier).submitAnswer(false);
    _recordSrs(0);
    _showMnemonic();
  }

  void _handleAnswer(bool isCorrect) {
    AnalyticsService.answered('flashcard', isCorrect);
    _lastAnswerCorrect = isCorrect;
    _feedbackCtrl.forward(from: 0);
    if (isCorrect) {
      AudioService.playCorrect();
    } else {
      AudioService.playWrong();
    }
    ref.read(flashcardQuizProvider.notifier).submitAnswer(isCorrect);
    _recordSrs(isCorrect ? 4 : 1);
    _countdownTimer?.cancel();
    if (isCorrect) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _hideMnemonic();
      });
    } else {
      _showMnemonic();
    }
    setState(() {});
  }

  void _recordSrs(int quality) {
    final tile = ref.read(flashcardQuizProvider).currentTile;
    if (tile == null) return;
    ref.read(srsNotifierProvider.notifier).recordReview(tile.id, 'flashcard', quality);
  }

  void _showMnemonic() {
    ref.read(flashcardQuizProvider.notifier).showMnemonic();
    setState(() {});
  }

  void _hideMnemonic() {
    ref.read(flashcardQuizProvider.notifier).hideMnemonic();
    _startCountdown();
    Future.delayed(const Duration(milliseconds: 150), () {
      ref.read(flashcardQuizProvider.notifier).nextCard();
      _startCountdown();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flashcardQuizProvider);
    final tile = state.currentTile;

    if (state.isFinished) {
      return _buildFinishedScreen(state);
    }

    if (tile == null || state.totalCount == 0) {
      return const Scaffold(
        backgroundColor: AppColors.jadeDeep,
        body: Center(child: CircularProgressIndicator(color: AppColors.neonGold)),
      );
    }

    _startCountdownIfNeeded();

    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildTopBar(state),
                  const SizedBox(height: 12),
                  _buildSuitFilter(state),
                  const SizedBox(height: 16),
                  _buildCountdownRing(),
                  const SizedBox(height: 16),
                  _buildTileDisplay(tile),
                  const SizedBox(height: 24),
                  _buildOptions(tile, state),
                  const SizedBox(height: 8),
                  _buildProgressDots(state),
                  const SizedBox(height: 8),
                  _buildHint(state),
                  const SizedBox(height: 16),
                ],
              ),
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
      _startCountdown(playVoice: true);
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
            onTap: () => context.pop(),
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
                TzProgressBar(value: state.progress),
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
                  color: isActive ? AppColors.neonGold.withOpacity(0.15) : AppColors.jadeCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? AppColors.neonGold.withOpacity(0.4) : Colors.transparent,
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
    return TzCountdownRing(
      progress: _countdownValue / _totalTime,
      secondsLeft: _countdownValue.toInt(),
      urgent: _countdownValue < 2.0,
    );
  }

  Widget _buildTileDisplay(TileModel tile) {
    final state = ref.read(flashcardQuizProvider);
    final isCorrect = state.lastCorrectId == tile.id;
    final assetPath = 'assets/tiles/${tile.id}.svg';
    return GestureDetector(
      onTap: state.isAnswering ? _showMnemonic : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 150, height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCorrect
                ? const Color(0xFF2CE574)
                : tile.suitColor.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            if (isCorrect)
              BoxShadow(color: const Color(0xFF2CE574).withOpacity(0.3), blurRadius: 24, spreadRadius: 2),
            BoxShadow(color: Colors.black54, blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SvgPicture.asset(assetPath, fit: BoxFit.contain),
              if (isCorrect && _feedbackCtrl.isAnimating)
                CustomPaint(
                  painter: TzPulsePainter(progress: _feedbackCtrl.value),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptions(TileModel tile, state) {
    final options = state.options;
    if (options.length != 4) {
      // Fallback: should never happen with precomputed options
      final distractors = ref.read(flashcardQuizProvider.notifier).getDistractors(tile);
      final fallback = [...distractors, tile]..shuffle();
      return _buildOptionList(tile, state, fallback);
    }
    return _buildOptionList(tile, state, options);
  }

  Widget _buildOptionList(TileModel tile, state, List<TileModel> options) {
    final letters = ['A', 'B', 'C', 'D'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(4, (i) {
          final opt = options[i];
          final isCorrect = opt.id == tile.id;
          Color? bgColor;
          if (state.isAnswering && state.lastCorrectId == tile.id && isCorrect) {
            bgColor = const Color(0xFF2CE574).withOpacity(0.15);
          } else if (state.isAnswering && state.lastWrongId != null && isCorrect) {
            bgColor = const Color(0xFF2CE574).withOpacity(0.15);
          } else if (state.isAnswering && state.lastWrongId == opt.id && !isCorrect) {
            bgColor = AppColors.vermillion.withOpacity(0.12);
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
                ? [BoxShadow(color: AppColors.neonGold.withOpacity(0.5), blurRadius: 4)]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildHint(state) {
    if (state.isAnswering && state.lastWrongId != null) {
      return const Text('📖 Study the mnemonic to remember this tile',
          style: TextStyle(fontSize: 12, color: AppColors.jadeWhiteDim));
    }
    // Animated hint — pulsing arrow pointing at the tile
    return const _PulsingHint();
  }

  Widget _buildMnemonicOverlay(TileModel tile) {
    final pngPath = 'assets/mnemonic_png/${tile.id}.png';
    return GestureDetector(
      onTap: _hideMnemonic,
      child: Container(
        color: AppColors.jadeDeep.withOpacity(0.97),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(pngPath, width: 280, height: 350, fit: BoxFit.contain),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 8),
                Text(tile.mnemonic.chinese, style: const TextStyle(
                  fontSize: 12, color: AppColors.jadeWhiteMuted, fontStyle: FontStyle.italic,
                )),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _hideMnemonic,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.neonGold,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text('Got it ✓', style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black,
                    )),
                  ),
                ),
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
      child: AnimatedSlide(
        offset: Offset(0, _feedbackCtrl.isAnimating ? 0 : 1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
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
                onPressed: () {
                  _cancelTimer();
                  ref.read(flashcardQuizProvider.notifier).restart();
                },
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

// ── Pulsing hint widget ──

class _PulsingHint extends StatefulWidget {
  const _PulsingHint();
  @override
  State<_PulsingHint> createState() => _PulsingHintState();
}

class _PulsingHintState extends State<_PulsingHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: 0.6 + _ctrl.value * 0.4,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.neonGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.neonGold.withOpacity(0.25)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('👆', style: TextStyle(fontSize: 16)),
            SizedBox(width: 6),
            Text('Tap tile to see mnemonic',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.neonGold)),
          ],
        ),
      ),
    );
  }
}

