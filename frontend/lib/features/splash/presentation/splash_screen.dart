/// 启动闪屏 —— 应用冷启动时展示的品牌入场动画，含淡入 + 缩放 + 进度条，
/// 动画结束后自动跳转至 onboarding 页面。
///
/// 动画时长约 2 秒（淡入 0.8 s，回弹缩放 1.2 s），额外留 0.4 s 停留后路由跳转。
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_colors.dart';

/// 应用启动闪屏页。
///
/// 2 秒动画后检查 [onboardingComplete] 标志：
/// - 首次启动 → /onboarding（引导页）
/// - 曾经完成引导 → /（首页）
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;

  /// 是否已完成引导（Hive 持久化），跨会话保持。
  static bool get onboardingComplete {
    final box = Hive.box('prefs');
    return box.get('onboarding_complete', defaultValue: false);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _fadeIn = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _scale = Tween(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );
    _controller.forward();

    Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      // 首次启动进引导页，已引导过直接进首页
      final target = onboardingComplete ? '/' : '/onboarding';
      context.go(target);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) => Opacity(
            opacity: _fadeIn.value,
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🀄', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              const Text('TILEZHAN', style: TextStyle(
                fontSize: 34, fontWeight: FontWeight.w800,
                letterSpacing: 4, color: AppColors.jadeWhite,
              )),
              const SizedBox(height: 4),
              const Text('麻 雀 斩', style: TextStyle(
                fontSize: 15, color: AppColors.neonGold, letterSpacing: 8,
                fontWeight: FontWeight.w500,
              )),
              const SizedBox(height: 12),
              const Text('Master Mahjong, One Tile at a Time.',
                  style: TextStyle(fontSize: 12, color: AppColors.jadeWhiteDim)),
              const SizedBox(height: 40),
              SizedBox(
                width: 160, height: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.jadeHover,
                    color: AppColors.vermillion,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
