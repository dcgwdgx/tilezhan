/// 启动闪屏页（Splash Screen），展示品牌入场动画后自动跳转。
///
/// 本页是用户打开 App 后看到的第一屏，承担两个核心职责：
/// 1. **品牌展示**：通过错层动画（emoji 缩放淡入 → 标题滑入 → 标语浮现 →
///    底部流光进度条）呈现 TileZhan 品牌形象，给用户留下深刻的第一印象。
/// 2. **路由决策**：动画结束后（约 2.5 秒），读取本地存储中的新手引导完成标志
///    [onboardingComplete]，决定跳转路径：
///    - 已完成引导 → 跳转首页 `/`
///    - 未完成引导 → 跳转新手引导页 `/onboarding`
///
/// 动画时间线（总时长 2200ms）：
/// ```
///   0ms        550ms      880ms      1320ms     2200ms
///   |--emoji--|----------|----------|----------|
///        |-----title-----|
///                    |--tagline--|
/// ```
/// - Emoji（🀄）：0-550ms 弹性缩放 + 淡入，带金色光晕
/// - 标题（TILEZAN）：330-1100ms 从下方 24px 滑入 + 淡入
/// - 标语：660-1320ms 淡入
/// - 流光进度条：全程线性播放，视觉上暗示加载进度
///
/// 架构角色：位于 [Presentation 层]，属于 Splash 特性模块的 UI 入口。
/// 不包含业务逻辑，路由决策通过读取 Hive 本地存储完成。
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_colors.dart';

/// 启动闪屏页的顶层 [StatefulWidget]。
///
/// 本 Widget 是 Splash 模块的对外入口，使用方式极简：
/// ```dart
/// GoRouter(routes: [
///   GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
/// ]);
/// ```
/// 所有动画编排、路由跳转均由内部 [_SplashScreenState] 管理，外部无需传入任何参数。
class SplashScreen extends StatefulWidget {
  /// 创建闪屏页实例。
  ///
  /// 无需传入任何参数——动画时长、路由目标均内置。
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// 闪屏页的内部状态管理类。
///
/// 使用 [SingleTickerProviderStateMixin] 驱动单个 [AnimationController]，
/// 通过 [CurvedAnimation] 的 [Interval] 将一条时间线切分为三层交错的入场动画。
/// 动画结束后通过 [Timer] 延迟约 300ms（总计约 2.5s）执行路由跳转。
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // ── 动画控制器与曲线 ──────────────────────────────────────────────
  // 单一 AnimationController 驱动所有入场动画，总时长 2200ms。
  late AnimationController _ctrl;

  // Emoji（🀄）入场动画：淡入 + 弹性缩放（0–550ms）
  late Animation<double> _emojiFade;   // 透明度 0→1，Interval(0.0, 0.25)
  late Animation<double> _emojiScale;  // 缩放 0.3→1.0，Interval(0.0, 0.35)，弹性曲线

  // 标题（TILEZAN）入场动画：淡入 + 从下方滑入（330–1100ms）
  late Animation<double> _titleFade;   // 透明度 0→1，Interval(0.15, 0.45)
  late Animation<double> _titleSlide;  // 位移 24→0 px，Interval(0.15, 0.5)

  // 标语入场动画：纯淡入（660–1320ms）
  late Animation<double> _tagFade;     // 透明度 0→1，Interval(0.3, 0.6)

  /// 读取本地存储中的新手引导完成标志。
  ///
  /// 从 Hive 存储的 `prefs` box 中读取 `onboarding_complete` 键值，
  /// 决定动画结束后跳转到首页（`/`）还是新手引导页（`/onboarding`）。
  ///
  /// 返回值：
  /// - `true`：用户已完成新手引导，应直接进入首页。
  /// - `false`（默认）：用户尚未完成引导，需要先走引导流程。
  ///
  /// 设计要点：使用静态 getter 而非实例方法，因为该判断逻辑与 Widget 实例
  /// 生命周期无关，在 [initState] 中的 [Timer] 回调里可以直接通过类名调用。
  static bool get onboardingComplete {
    final box = Hive.box('prefs');
    return box.get('onboarding_complete', defaultValue: false);
  }

  /// 初始化动画控制器、动画曲线和路由跳转定时器。
  ///
  /// 执行顺序：
  /// 1. 创建 [AnimationController]，总时长 2200ms，绑定 vsync。
  /// 2. 通过 [CurvedAnimation] 的 [Interval] 将时间线切分为三层动画：
  ///    - Emoji 层（0–770ms）：fade + elastic 缩放弹跳
  ///    - 标题层（330–1100ms）：fade + 从下方 24px 滑入
  ///    - 标语层（660–1320ms）：纯 fade 淡入
  /// 3. 启动动画 [_ctrl.forward()]。
  /// 4. 设置 2500ms 延迟定时器，动画播完后保留 300ms 展示缓冲，
  ///    然后读取 [onboardingComplete] 决定跳转路径。
  ///
  /// 关于 2500ms vs 2200ms：额外保留 300ms 让用户看清完整画面，
  /// 避免动画刚结束就立即跳转造成的突兀感。
  @override
  void initState() {
    super.initState();

    // 创建动画控制器，绑定 vsync 以防止屏幕不可见时浪费资源。
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // ── Emoji 入场动画（🀄）──────────────────────────────────────
    // 时间区间：0–770ms（总进度的 0%–35%）
    // 淡入：easeOut 曲线，0–550ms 内从透明到不透明。
    _emojiFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );
    // 缩放弹跳：elasticOut 曲线，0–770ms 内从 0.3 倍放大到 1.0 倍。
    // elasticOut 会产生轻微的过冲回弹效果，模拟"弹入"感。
    _emojiScale = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.35, curve: Curves.elasticOut),
      ),
    );

    // ── 标题入场动画（TILEZAN）──────────────────────────────────
    // 时间区间：330–1100ms（总进度的 15%–50%）
    // 标题比 emoji 延迟 330ms 出现，形成错层效果。
    _titleFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.15, 0.45, curve: Curves.easeOut),
      ),
    );
    // 从下方 24 逻辑像素滑入到原位，easeOutCubic 产生自然的减速停止。
    _titleSlide = Tween(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    // ── 标语入场动画 ────────────────────────────────────────────
    // 时间区间：660–1320ms（总进度的 30%–60%）
    // 标语最后出现，纯淡入，不位移，保持视觉简洁。
    _tagFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    // 启动动画播放。
    _ctrl.forward();

    // 路由跳转定时器：2500ms 后自动跳转。
    // 比动画总时长（2200ms）多 300ms，作为视觉停留缓冲。
    Timer(const Duration(milliseconds: 2500), () {
      // 安全检查：如果 Widget 已被销毁（例如用户快速关闭），不执行跳转。
      if (!mounted) return;
      // 根据新手引导完成状态决定目标路由。
      final target = onboardingComplete ? '/' : '/onboarding';
      context.go(target);
    });
  }

  /// 释放动画控制器资源。
  ///
  /// 必须调用 [AnimationController.dispose] 以避免内存泄漏。
  /// vsync 绑定会在 dispose 时自动解除。
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// 构建闪屏页 UI。
  ///
  /// 布局结构（垂直居中排列）：
  /// ```
  /// [Scaffold: AppColors.jadeDeep 深翠绿背景]
  ///   └─ [Center]
  ///        └─ [AnimatedBuilder] ← 绑定 _ctrl，动画驱动重建
  ///             └─ [Column(mainAxisSize: min)]
  ///                  ├─ Emoji 区：光晕容器 + 🀄 文字（弹性缩放+淡入）
  ///                  ├─ SizedBox(24px 间距)
  ///                  ├─ 标题区：TILEZAN 文字（滑入+淡入）
  ///                  ├─ SizedBox(6px 间距)
  ///                  ├─ 标语区：英文 slogan（纯淡入）
  ///                  ├─ SizedBox(36px 间距)
  ///                  └─ 流光进度条：LinearProgressIndicator 持续播放
  /// ```
  ///
  /// 关键设计决策：
  /// - 使用 [AnimatedBuilder] 而非 [AnimatedWidget]，因为需要重建整棵子树。
  /// - Emoji 容器预置圆形光晕（[BoxShadow]），随着 _emojiFade 透明度增长，
  ///   光晕从不可见到逐渐亮起，营造"点亮"的视觉感受。
  /// - 每个动画元素独立使用 [Opacity] + [Transform] 组合，
  ///   各元素动画互不耦合，便于单独调整时间线。
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Emoji 区：🀄 麻将牌符号 + 动态金色光晕 ──────────────
              // 两层动画叠加：外层 Opacity 控制可见度，内层 Transform.scale 控制弹性缩放。
              // 光晕透明度 = 0.3 × _emojiFade.value，随动画进度从 0 到 0.3 线性增长，
              // 模拟"点亮"效果——光晕从不可见逐渐亮起。
              Opacity(
                opacity: _emojiFade.value,
                child: Transform.scale(
                  scale: _emojiScale.value,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonGold.withOpacity(0.3 * _emojiFade.value),
                          blurRadius: 40, spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🀄', style: TextStyle(fontSize: 64)),
                    ),
                  ),
                ),
              ),
              // 24px 间距：emoji 与标题之间。
              const SizedBox(height: 24),
              // ── 标题区：TILEZAN ──────────────────────────────────────
              // 标题从下方 24px 滑入原位 + 同时淡入，形成错层入场感。
              // Transform.translate 的 offset.y 随 _titleSlide 从 24→0 递减，
              // 视觉上文字从下方"推"上来。配合 6px 字间距增强品牌气质。
              Opacity(
                opacity: _titleFade.value,
                child: Transform.translate(
                  offset: Offset(0, _titleSlide.value),
                  child: const Text('TILESLASH', style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w900,
                    letterSpacing: 6, color: AppColors.jadeWhite,
                  )),
                ),
              ),
              // 6px 间距：标题与标语之间。
              const SizedBox(height: 6),
              // ── 标语区：英文 Slogan ──────────────────────────────────
              // 纯淡入无位移，金色文字在深翠绿背景上形成品牌色对比。
              // 字间距 1px 保持可读性，字号 13 不抢标题视觉权重。
              Opacity(
                opacity: _tagFade.value,
                child: const Text('Master Mahjong, One Tile at a Time.',
                  style: TextStyle(fontSize: 13, color: AppColors.neonGold,
                    letterSpacing: 1)),
              ),
              // 36px 间距：标语与底部进度条之间，形成视觉"呼吸感"。
              const SizedBox(height: 36),
              // ── 流光进度条 ──────────────────────────────────────────
              // indeterminate 模式（未设 value）的线性进度条，持续流动。
              // 裁切为圆角矩形（radius: 2），配色为朱红流动条 + 深翠绿底色。
              // 固定宽 140px 高 3px，避免与上方文字等宽造成单调感。
              SizedBox(
                width: 140, height: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.jadeHover,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.vermillion.withOpacity(0.8)),
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
