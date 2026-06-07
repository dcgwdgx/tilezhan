import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    final progress = _countdownValue / _totalTime;
    final urgent = _countdownValue < 0.3;
    final color = urgent ? AppColors.vermillion : AppColors.neonGold;
    return SizedBox(
      width: 80, height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(80, 80),
            painter: _GlowRingPainter(progress: progress, color: color, urgent: urgent),
          ),
          Text(_countdownValue.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700,
                color: color, fontFamily: 'JetBrains Mono',
              )),
        ],
      ),
    );
  }

  Widget _buildTileDisplay(TileModel tile) {
    final state = ref.read(flashcardQuizProvider);
    final isCorrect = state.lastCorrectId == tile.id;
    final tileSvg = 'assets/tiles/${tile.id}.svg';
    return GestureDetector(
      onTap: state.isAnswering ? _showMnemonic : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160, height: 224,
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
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SvgPicture.asset(tileSvg, fit: BoxFit.fill),
            ),
            if (isCorrect)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CustomPaint(
                    painter: _TileGlowPainter(color: const Color(0xFF2CE574), glowIntensity: 1.0),
                  ),
                ),
              ),
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

  Widget _buildHint() {
    return const Text('💡 Tap the tile to reveal its mnemonic story',
        style: TextStyle(fontSize: 11, color: AppColors.jadeWhiteMuted));
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

// ── Custom Painters ──

class _GlowRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool urgent;

  _GlowRingPainter({required this.progress, required this.color, required this.urgent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background ring
    final bgPaint = Paint()
      ..color = AppColors.jadeHover
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, bgPaint);

    // Glow shadow (neon effect)
    if (progress > 0) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, progress * 2 * math.pi, false, glowPaint,
      );
    }

    // Progress arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, progress * 2 * math.pi, false, arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlowRingPainter old) =>
      old.progress != progress || old.urgent != urgent;
}

class _TileGlowPainter extends CustomPainter {
  final Color color;
  final double glowIntensity;

  _TileGlowPainter({required this.color, required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    if (glowIntensity <= 0) return;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size, const Radius.circular(16),
    );
    final paint = Paint()
      ..color = color.withOpacity(glowIntensity * 0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 12 * glowIntensity);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _TileGlowPainter old) =>
      old.glowIntensity != glowIntensity;
}
