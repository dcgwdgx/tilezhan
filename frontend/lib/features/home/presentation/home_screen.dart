import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/hearts/heart_provider.dart';
import '../../../core/iap/iap_provider.dart';
import '../../../shared/widgets/tz_battle_report.dart';
import '../../../shared/widgets/tz_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _shimmerCtrl.repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 12),
              _buildBadgeCard(),
              const SizedBox(height: 16),
              _buildQuestCard(),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('QUICK ACCESS', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5,
                    color: AppColors.jadeWhiteMuted,
                  )),
                ),
              ),
              const SizedBox(height: 8),
              _buildQuickGrid(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomTabBar(),
    );
  }

  Widget _buildTopBar() {
    final hearts = ref.watch(heartServiceProvider).hearts;
    final isPremium = ref.watch(isPremiumProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(children: [
        // Hearts
        Row(children: [
          Text('❤️', style: TextStyle(
            fontSize: 18,
            color: hearts > 0 ? const Color(0xFFFF3B30) : AppColors.jadeWhiteMuted,
          )),
          const SizedBox(width: 4),
          Text('$hearts/10', style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: hearts > 0 ? AppColors.jadeWhite : AppColors.jadeWhiteMuted,
            decoration: hearts == 0 ? TextDecoration.lineThrough : null,
          )),
        ]),
        const Spacer(),
        // Premium badge
        GestureDetector(
          onTap: () => context.push('/premium'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isPremium
                ? AppColors.neonGold.withOpacity(0.2)
                : AppColors.demonPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPremium ? '👑 PRO' : '👑 UPGRADE',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                color: isPremium ? AppColors.neonGold : AppColors.jadeWhiteMuted),
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF103D28), Color(0xFF0D3D26)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neonGold.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: AppColors.neonGold.withOpacity(0.05), blurRadius: 30)],
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.demonPurple, Color(0xFF6C3483)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.demonPurple.withOpacity(0.3), blurRadius: 12)],
              ),
              child: const Center(child: Text('🏆', style: TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Adept · Lv.7', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.jadeWhite)),
                SizedBox(height: 2),
                Text('1248 ELO', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.neonGold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F3526), Color(0xFF0D3D26)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.neonGold.withOpacity(0.25)),
        ),
        child: Column(children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.neonGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('✨ DAILY CHALLENGE', style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: AppColors.neonGold, letterSpacing: 1)),
            ),
            const Spacer(),
            Text('${ref.watch(dailyChallengeRemainingProvider)}/3 free',
              style: const TextStyle(fontSize: 12, color: AppColors.jadeWhiteDim)),
          ]),
          const SizedBox(height: 16),
          const Text('3 puzzles. No stamina cost. Claim your daily reward.',
            style: TextStyle(fontSize: 14, color: AppColors.jadeWhiteDim)),
          const SizedBox(height: 16),
          TzButton(
            label: '⚡ START CHALLENGE',
            style: TzButtonStyle.gold,
            onPressed: () => context.push('/nanikiru'),
          ),
        ]),
      ),
    );
  }

  Widget _buildQuickGrid() {
    final items = [
      ('🃏', 'Flashcards', '/flashcard'), ('⚔️', 'Nani-Kiru', '/nanikiru'),
      ('🔬', 'Scanner', '/scanner'),       ('📚', 'Yaku Guide', '/collection'),
      ('👻', 'Graveyard', '/graveyard'),   ('🔍', 'Tile Browser', '/tiles'),
      ('👤', 'Profile', '/profile'),       ('💎', 'Premium', '/premium'),
      ('⚙️', 'Settings', '/settings'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.2,
        children: items.map((item) {
          return GestureDetector(
            onTap: () => context.push(item.$3),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.jadeCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.jadeHover.withOpacity(0.5)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(item.$1, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 4),
                Text(item.$2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.jadeWhite)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomTabBar() {
    final tabs = [
      ('🏠', 'Home', 0, '/'),
      ('🀄', 'Tiles', 1, '/tiles'),
      ('📚', 'Yaku', 2, '/collection'),
      ('👻', 'Review', 3, '/graveyard'),
    ];
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFF0A2818),
        border: Border(top: BorderSide(color: Color(0xFF1A4A30), width: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, -2))],
      ),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map((t) {
          final active = _activeTab == t.$3;
          return GestureDetector(
            onTap: () {
              setState(() => _activeTab = t.$3);
              context.push(t.$4);
            },
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: active ? 1.15 : 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (_, s, __) => Transform.scale(
                scale: s,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(t.$1, style: TextStyle(fontSize: active ? 22 : 20)),
                  const SizedBox(height: 2),
                  Text(t.$2, style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: active ? AppColors.neonGold : AppColors.jadeWhiteMuted,
                  )),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  final double progress;
  final Color color;
  final AnimationController ctrl;
  const _ShimmerBar({required this.progress, required this.color, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final grad = LinearGradient(
      colors: [Colors.transparent, Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.08), Colors.transparent],
      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      begin: Alignment(-1.0 + ctrl.value * 2, 0),
      end: Alignment(1.0 + ctrl.value * 2, 0),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 6,
        color: AppColors.jadeHover,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress,
          child: ShaderMask(
            shaderCallback: (bounds) => grad.createShader(bounds),
            blendMode: BlendMode.srcATop,
            child: Container(color: color),
          ),
        ),
      ),
    );
  }
}
