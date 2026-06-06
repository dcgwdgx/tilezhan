import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _hearts = 3;
  int _streak = 14;

  void _decreaseHeart() {
    setState(() {
      if (_hearts > 0) _hearts--;
    });
    if (_hearts <= 0) {
      _showPaywall();
    }
  }

  void _showPaywall() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.jadeCard,
        title: const Text('💎 Out of Stamina!', style: TextStyle(color: AppColors.jadeWhite)),
        content: const Text('Hearts recover every 4 hours.\n\nUnlock unlimited with TileZhan Pro.',
            style: TextStyle(color: AppColors.jadeWhiteDim)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Wait', style: TextStyle(color: AppColors.jadeWhiteMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonGold),
            child: const Text('Unlock Pro', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      body: SafeArea(
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
            const Spacer(),
            _buildBottomTabBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Text('🔥 $_streak', style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFFF8A00),
          )),
          const Spacer(),
          Row(
            children: List.generate(3, (i) {
              return GestureDetector(
                onTap: _decreaseHeart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(i < _hearts ? '❤️' : '🖤',
                      style: const TextStyle(fontSize: 18)),
                ),
              );
            }),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showPaywall,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.demonPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('👑 PRO', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.demonPurple,
              )),
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
          gradient: const LinearGradient(colors: [Color(0xFF103D28), Color(0xFF0D3D26)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neonGold.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.demonPurple, Color(0xFF6C3483)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(child: Text('🏆', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Adept · Lv.7', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.jadeWhite)),
                SizedBox(height: 2),
                Text('1248 ELO', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.neonGold)),
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
          gradient: const LinearGradient(colors: [Color(0xFF0F3526), Color(0xFF0D3D26)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.neonGold.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('✦ TODAY\'S QUEST', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2,
              color: AppColors.neonGold,
            )),
            const SizedBox(height: 16),
            _questItem('🃏', 'Tile Flashcards — Manzu Advanced', '8/10', 0.8, AppColors.neonGold),
            const SizedBox(height: 12),
            _questItem('⚔️', 'Nani-Kiru — Two-Sided Waits', '1/3', 0.33, AppColors.neonGold),
            const SizedBox(height: 12),
            _questItem('👻', 'Tile Graveyard Review', '⚠ 12 due', 0.0, AppColors.vermillion),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/flashcard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('⚡ START DAILY QUEST',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questItem(String icon, String label, String count, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.jadeWhite)),
            ]),
            Text(count, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.jadeWhiteDim)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.jadeHover,
            color: color,
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickGrid() {
    final items = [
      ('🃏', 'Flashcards', '/flashcard'),
      ('⚔️', 'Nani-Kiru', '/nanikiru'),
      ('🔍', 'Tile Browser', '/tiles'),
      ('📚', 'Yaku Guide', '/collection'),
      ('👻', 'Graveyard', '/graveyard'),
      ('⚙️', 'Settings', '/'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.3,
        children: items.map((item) {
          return GestureDetector(
            onTap: () => context.go(item.$3),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.jadeCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.jadeHover),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.$1, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(item.$2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: AppColors.jadeWhite)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomTabBar() {
    final tabs = [
      ('🏠', 'Home', true),
      ('🀄', 'Tiles', false),
      ('📚', 'Yaku', false),
      ('👻', 'Review', false),
    ];
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: Color(0xFF0D3D26),
        border: Border(top: BorderSide(color: Color(0xFF1A4A30))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map((t) {
          return GestureDetector(
            onTap: () {
              if (t.$1 == '🀄') context.go('/tiles');
              if (t.$1 == '📚') context.go('/collection');
              if (t.$1 == '👻') context.go('/graveyard');
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(t.$1, style: const TextStyle(fontSize: 20)),
                Text(t.$2, style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: t.$3 ? AppColors.neonGold : AppColors.jadeWhiteMuted,
                )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
