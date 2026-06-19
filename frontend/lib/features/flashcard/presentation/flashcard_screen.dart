/// 闪卡答题屏幕 — 牌面识别 + SRS 间隔重复。
///
/// 显示一张麻雀牌，用户回答后正确/错误反馈、连击动画、
/// 计费逻辑：每日挑战优先免费，其次扣心，心耗尽弹战绩窗口。

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/elo/elo_provider.dart';
import '../../../core/providers/player_name_provider.dart';
import '../../../core/utils/audio_service.dart';
import '../../../core/srs/srs_provider.dart';
import '../../../core/hearts/heart_provider.dart';
import '../../../core/iap/iap_provider.dart';
import '../../../shared/models/tile_model.dart';
import '../../../shared/widgets/tz_battle_report.dart';
import '../../../shared/widgets/tz_combo_promo.dart';
import '../../../shared/widgets/tz_countdown_ring.dart';
import '../../../shared/widgets/tz_progress_bar.dart';
import '../../../shared/widgets/tz_pulse_painter.dart';
import '../../leaderboard/domain/leaderboard_service.dart';
import '../domain/flashcard_provider.dart';

/// 闪卡答题屏幕入口 Widget。
///
/// 接受可选 [suite] 参数过滤花色（如 'man', 'pin', 'sou', 'honor'），默认为 'all' 全部。
class FlashcardScreen extends ConsumerStatefulWidget {
  final String suite; // 花色过滤参数：'all' | 'man' | 'pin' | 'sou' | 'honor'
  const FlashcardScreen({super.key, this.suite = 'all'});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

/// 闪卡答题屏幕的内部状态管理类。
///
/// 管理倒计时、反馈动画、答题状态机、心数消耗流程。
/// 混入 [SingleTickerProviderStateMixin] 以驱动单个动画控制器。
class _FlashcardScreenState extends ConsumerState<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  Timer? _countdownTimer; // 倒计时定时器，每 50ms 滴答一次
  double _countdownValue = 8.0; // 当前倒计时剩余秒数（8.0 → 0.0）
  late AnimationController _feedbackCtrl; // 答题反馈动画控制器（正确 pulse / 成功条滑入）
  static const _totalTime = 8.0; // 每题总倒计时时长（秒）

  @override
  void initState() {
    super.initState();
    // 初始化答题反馈动画控制器，1000ms 周期驱动 pulse 与 success bar 动画
    _feedbackCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    // 微任务延迟初始化：确保 Widget 树构建完成后才开始 quiz 逻辑
    Future.microtask(() {
      // 免费用户体力/每日挑战耗尽时弹窗，不开始 quiz
      if (!ref.read(canPlayProvider)) {
        _maybeShowBattleReport();
        return;
      }
      ref.read(flashcardQuizProvider.notifier).initQuiz(suite: widget.suite);
    });
  }

  @override
  void dispose() {
    // 释放定时器与动画控制器资源，防止内存泄漏
    _countdownTimer?.cancel();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  // 取消倒计时定时器并重置启动标记。
  // 用于切题、退出、重新开始等需要停止倒计时的场景。
  void _cancelTimer() {
    _countdownTimer?.cancel();
    _countdownStarted = false;
  }

  // 启动 8 秒倒计时。
  //
  // 每 50ms 滴答一次（共 160 步从 8.0 降到 0.0），驱动 [TzCountdownRing] 的平滑动画。
  // [playVoice] 为 true 时播放牌面语音（仅首次显示题目时）。
  // 倒计时归零且未在答题反馈中时自动触发超时处理。
  void _startCountdown({bool playVoice = false}) {
    _countdownTimer?.cancel(); // 先取消旧定时器，防止重复启动导致多个定时器并发
    _countdownValue = _totalTime; // 重置倒计时初值
    if (playVoice) {
      final tile = ref.read(flashcardQuizProvider).currentTile;
      if (tile != null) AudioService.playVoice(tile.id); // 播放牌名语音
    }
    // 每 50ms 滴答，进度递减 0.05 秒
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _countdownValue -= 0.05;
      if (_countdownValue <= 0) {
        _countdownValue = 0;
        timer.cancel(); // 倒计时结束，停止定时器
        final state = ref.read(flashcardQuizProvider);
        if (!state.isAnswering) {
          // 用户未在答题反馈中 → 超时判错
          _handleTimeout();
        }
      }
      setState(() {}); // 触发 UI 刷新（更新倒计时环）
    });
  }

  // 倒计时超时处理：播放错误音效 → 提交错误答案 → SRS 记录（质量 0）→ 展示助记 → 体力服务记错。
  // 超时不扣心，但归零连斩并进错题池。
  void _handleTimeout() {
    AudioService.playWrong();
    ref.read(flashcardQuizProvider.notifier).submitAnswer(false);
    _recordSrs(0); // 质量分 0 = 完全遗忘，SRS 间隔重置为最短
    _showMnemonic();
    final hearts = ref.read(heartServiceProvider);
    hearts.recordWrong();
    ref.read(eloProvider.notifier).recordResult(isCorrect: false, isSkip: false);
    final name = ref.read(playerNameProvider);
    LeaderboardService.reportScore(name: name, elo: ref.read(eloProvider), streak: hearts.allTimeCombo);
  }

  /// 回答提交后的流程：录战绩 → 扣体力 → 弹促销/战绩窗口。
  ///
  /// 费用逻辑：每日挑战 3 题免费 → 心数消耗 → 心耗尽弹窗。
  /// 错误回答不耗心（进错题池），但会归零连斩。
  void _handleAnswer(bool isCorrect) {
    if (_gameOver) return; // 心已耗尽，禁止继续答题
    AnalyticsService.answered('flashcard', isCorrect);
    _feedbackCtrl.forward(from: 0);
    final hearts = ref.read(heartServiceProvider);

    if (isCorrect) {
      AudioService.playCorrect();
      hearts.recordCorrect(); // 更新战绩 + 全时连斩 +1
      ref.read(eloProvider.notifier).recordResult(isCorrect: true, isSkip: false);

      // ── 心数消耗流程（二级计费）──
      // 第一级：每日挑战（每日 3 题免费额度），优先消耗
      // 第二级：心数（IAP 购买或奖励获取），每日挑战耗尽后使用
      bool depleted = false;
      if (!hearts.useDailyChallenge()) {
        // 每日挑战额度已用完 → 消耗 1 颗心
        depleted = hearts.consume();
      }
      if (depleted) {
        // 心已耗尽 → 封锁后续答题 + 弹出战绩/购买窗口
        _gameOver = true;
        _maybeShowBattleReport();
      }
    } else {
      AudioService.playWrong();
      hearts.recordWrong(); // 错误不耗心，但归零连斩
      ref.read(eloProvider.notifier).recordResult(isCorrect: false, isSkip: false);
    }

    // Report ELO to leaderboard (fire-and-forget)
    final name = ref.read(playerNameProvider);
    final elo = ref.read(eloProvider);
    LeaderboardService.reportScore(name: name, elo: elo, streak: hearts.allTimeCombo);

    ref.read(flashcardQuizProvider.notifier).submitAnswer(isCorrect);
    _recordSrs(isCorrect ? 4 : 1); // 正确=质量分4，错误=质量分1
    _countdownTimer?.cancel(); // 答题后立即停止倒计时
    if (isCorrect) {
      // 正确：延迟 800ms 后自动隐藏助记并切换到下一题
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _hideMnemonic();
      });
    } else {
      // 错误：立即展示助记卡片，用户需手动关闭
      _showMnemonic();
    }
    setState(() {});
  }

  /// 弹战绩分享窗口。关闭后留在本页——gate 封堵不让答题。
  void _maybeShowBattleReport() {
    final isPremium = ref.read(isPremiumProvider);
    if (isPremium) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TzBattleReport(),
    );
  }

  // 向 SRS（间隔重复系统）记录本次答题质量分。
  // quality: 0-5，正确=4，错误=1，超时=0。
  // SRS 根据质量分自动计算下次复习间隔。
  void _recordSrs(int quality) {
    final tile = ref.read(flashcardQuizProvider).currentTile;
    if (tile == null) return;
    ref.read(srsNotifierProvider.notifier).recordReview(tile.id, 'flashcard', quality);
  }

  // 显示当前牌面的助记卡片覆盖层。
  // 设置 quiz 状态为"助记展示中"，触发 [_buildMnemonicOverlay] 渲染。
  void _showMnemonic() {
    ref.read(flashcardQuizProvider.notifier).showMnemonic();
    setState(() {});
  }

  // 关闭助记覆盖层 → 重启倒计时 → 延迟 150ms 后切换到下一题。
  //
  // 分两步 [Future.delayed] 是为了让覆盖层关闭动画有时间播放，
  // 同时确保下一题的倒计时在新牌面渲染完成后才开始。
  void _hideMnemonic() {
    ref.read(flashcardQuizProvider.notifier).hideMnemonic();
    _startCountdown(); // 重启当前题倒计时（正确答案查看助记后可继续）
    Future.delayed(const Duration(milliseconds: 150), () {
      ref.read(flashcardQuizProvider.notifier).nextCard(); // 切换到下一张牌
      _startCountdown(); // 新题倒计时
    });
  }

  // 构建闪卡答题屏幕的主 UI。
  //
  // 布局结构（从上到下）：
  // 1. 顶栏（关闭 + 进度条 + 题号）
  // 2. 花色筛选标签
  // 3. 倒计时环
  // 4. 牌面 SVG 展示（带正确/错误反馈动画）
  // 5. 四选项列表（A/B/C/D）
  // 6. 进度圆点
  // 7. 提示文字 / 脉冲提示
  //
  // 条件覆盖层：
  // - 答题正确时：底部滑入成功条（口号）
  // - 展示助记时：全屏半透明覆盖层
  // - 题库完成时：跳转完成页面
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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

    _startCountdownIfNeeded(); // 每次 build 时检查是否需要启动倒计时

    return Scaffold(
      backgroundColor: AppColors.jadeDeep,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(state),
                const SizedBox(height: 8),
                _buildSuitFilter(state),
                const Spacer(),
                _buildCountdownRing(),
                const SizedBox(height: 16),
                _buildTileDisplay(tile),
                const SizedBox(height: 24),
                _buildOptions(tile, state),
                const SizedBox(height: 8),
                _buildProgressDots(state),
                const SizedBox(height: 8),
                _buildHint(state),
                const Spacer(),
              ],
            ),
            if (state.isShowingMnemonic) // 助记卡片全屏覆盖层
              _buildMnemonicOverlay(tile),
            if (state.isAnswering && state.lastCorrectId != null) // 答对时底部滑入 slogan 条
              _buildSuccessBar(tile),
          ],
        ),
      ),
    );
  }

  bool _countdownStarted = false; // 倒计时是否已启动（防止重复启动）
  bool _gameOver = false; // 心耗尽封锁后续答题
  // 条件性倒计时启动：仅在题目就绪且未在反馈中时启动。
  //
  // build() 每次重绘时调用此方法，确保换题后自动开始新的倒计时。
  // 如果正在展示答题反馈（isAnswering=true），则重置标记等待下一帧。
  void _startCountdownIfNeeded() {
    final state = ref.read(flashcardQuizProvider);
    if (!state.isAnswering && !_countdownStarted) {
      _countdownStarted = true;
      _startCountdown(playVoice: true); // 新题播放语音
    }
    if (state.isAnswering) {
      _countdownStarted = false; // 反馈期间暂停倒计时逻辑，等待反馈结束
    }
  }

  // 构建顶部导航栏：关闭按钮 | 标题 + 进度条 | 当前题号。
  // 进度条使用 [TzProgressBar] 组件。
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

  // 构建水平滚动的花色筛选标签栏。
  // 支持 All / Man / Pin / Sou / Honor 五类筛选，点击后重新初始化 quiz。
  // 当前激活标签使用金色高亮样式。
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

  // 构建倒计时环形进度组件。
  // 将内部倒计时值映射到 [TzCountdownRing] 的参数：
  // progress 归一化到 0.0-1.0，urgent 在剩余 < 2 秒时触发红色闪烁。
  Widget _buildCountdownRing() {
    return TzCountdownRing(
      progress: _countdownValue / _totalTime, // 归一化进度 1.0 → 0.0
      secondsLeft: _countdownValue.toInt(), // 剩余整秒数
      urgent: _countdownValue < 2.0, // 少于 2 秒触发紧急红色动画
    );
  }

  // 构建牌面 SVG 展示区域。
  //
  // 答题正确时触发缩放脉冲动画（先放大再回弹），并叠加 [TzPulsePainter] 金色波纹特效。
  // 边框颜色：正确=绿色，其他=牌面对应花色颜色。
  // 答题反馈期间点击牌面可查看助记。
  Widget _buildTileDisplay(TileModel tile) {
    final state = ref.read(flashcardQuizProvider);
    final isCorrect = state.lastCorrectId == tile.id;
    final assetPath = 'assets/tiles/${tile.id}.svg';
    // 缩放动画曲线：前 30% 放大到最大 1.09x，之后缓动回 1.0
    final scale = isCorrect && _feedbackCtrl.isAnimating
        ? 1.0 + (_feedbackCtrl.value < 0.3 ? _feedbackCtrl.value * 0.3 : (1 - _feedbackCtrl.value) * 0.15)
        : 1.0;
    return GestureDetector(
      onTap: state.isAnswering ? _showMnemonic : null,
      child: Transform.scale(
        scale: scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 150, height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCorrect
                ? const Color(0xFF2CE574) // 正确：绿色边框
                : tile.suitColor.withOpacity(0.5), // 默认：牌面对应花色颜色
            width: 2,
          ),
          boxShadow: [
            if (isCorrect)
              BoxShadow(color: const Color(0xFF2CE574).withOpacity(0.3), blurRadius: 24, spreadRadius: 2), // 正确：绿色光晕
            BoxShadow(color: Colors.black54, blurRadius: 12, offset: const Offset(0, 6)), // 底部阴影增加立体感
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SvgPicture.asset(assetPath, fit: BoxFit.contain),
              if (isCorrect && _feedbackCtrl.isAnimating)
                // 正确反馈：叠加金色脉冲波纹动画特效
                CustomPaint(
                  painter: TzPulsePainter(progress: _feedbackCtrl.value),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // 构建四选项列表区域。
  //
  // 正常路径使用 provider 预计算的 4 个选项（含 3 个干扰项 + 正确答案）。
  // Fallback：如果选项数异常（不应发生），现场调用 getDistractors 生成干扰项并随机排列。
  Widget _buildOptions(TileModel tile, state) {
    final options = state.options;
    if (options.length != 4) {
      // Fallback: 防御性代码，正常情况下预计算选项始终为 4
      final distractors = ref.read(flashcardQuizProvider.notifier).getDistractors(tile);
      final fallback = [...distractors, tile]..shuffle();
      return _buildOptionList(tile, state, fallback);
    }
    return _buildOptionList(tile, state, options);
  }

  // 渲染 4 个选项按钮（A/B/C/D），含答题反馈高亮逻辑。
  //
  // 颜色状态机：
  // - 默认：深玉色背景 [AppColors.jadeCard]
  // - 用户答对时：正确选项高亮绿色
  // - 用户答错时：正确选项高亮绿色（揭示答案），用户所选错误选项高亮红色
  // - 答题反馈期间（isAnswering=true）禁用点击
  Widget _buildOptionList(TileModel tile, state, List<TileModel> options) {
    final letters = ['A', 'B', 'C', 'D'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(4, (i) {
          final opt = options[i];
          final isCorrect = opt.id == tile.id;
          Color? bgColor; // null = 默认背景（未激活状态）
          // ── 选项高亮颜色状态机 ──
          if (state.isAnswering && state.lastCorrectId == tile.id && isCorrect) {
            // 用户答对 → 正确项标绿
            bgColor = const Color(0xFF2CE574).withOpacity(0.15);
          } else if (state.isAnswering && state.lastWrongId != null && isCorrect) {
            // 用户答错 → 揭示正确答案（绿色）
            bgColor = const Color(0xFF2CE574).withOpacity(0.15);
          } else if (state.isAnswering && state.lastWrongId == opt.id && !isCorrect) {
            // 用户答错 → 标记用户所选错误项（红色）
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
                    // 选项字母圆形标识（A/B/C/D）
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

  // 构建进度圆点指示器。
  //
  // 已完成题 → 金色实心圆 | 当前题 → 金色带光晕 | 未做题 → 暗灰色圆。
  // 总圆点数 = 本轮题目总数。
  Widget _buildProgressDots(state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(state.totalCount, (i) {
        Color color;
        if (i < state.currentIndex) {
          color = AppColors.neonGold; // 已答题：金色实心
        } else if (i == state.currentIndex) {
          color = AppColors.neonGold; // 当前题：金色（下方另有光晕区分）
        } else {
          color = AppColors.jadeHover; // 未答题：暗灰色
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

  // 构建底部提示区域。
  //
  // 答错时：显示学习助记提示文字。
  // 未答题时：显示脉冲动画提示（👆 点击牌面查看助记）。
  Widget _buildHint(state) {
    if (state.isAnswering && state.lastWrongId != null) {
      return const Text('📖 Study the mnemonic to remember this tile',
          style: TextStyle(fontSize: 12, color: AppColors.jadeWhiteDim));
    }
    // 动画提示 — 脉冲箭头指向牌面，引导用户点击查看助记
    return const _PulsingHint();
  }

  // 构建全屏助记卡片覆盖层。
  //
  // 显示内容：助记 PNG 图片 + 牌名 + slogan + 详细描述 + 中文含义 + "Got it" 确认按钮。
  // 点击覆盖层任意位置或按钮均可关闭。
  // 背景为深玉色 97% 透明度，确保与主界面视觉连贯。
  Widget _buildMnemonicOverlay(TileModel tile) {
    final l10n = AppLocalizations.of(context)!;
    final pngPath = 'assets/mnemonic_png/${tile.id}.png';
    return GestureDetector(
      onTap: _hideMnemonic, // 点击背景任意位置关闭助记覆盖层
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
                Text(tile.mnemonic.name, style: const TextStyle( // 牌名（金色大号）
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.neonGold,
                )),
                const SizedBox(height: 4),
                Text(tile.mnemonic.slogan, style: const TextStyle( // 记忆口号
                  fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.jadeWhite,
                )),
                const SizedBox(height: 8),
                Text(tile.mnemonic.desc, textAlign: TextAlign.center, style: const TextStyle( // 详细描述
                  fontSize: 13, color: AppColors.jadeWhiteDim, height: 1.6,
                )),
                const SizedBox(height: 8),
                Text(tile.mnemonic.chinese, style: const TextStyle( // 中文含义（斜体）
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
                    child: Text(l10n.flashcardGotIt, style: const TextStyle(
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

  // 构建答题正确时的底部成功提示条。
  //
  // 从屏幕底部弹性滑入，显示牌面 slogan。
  // 使用 [AnimatedSlide] + [Curves.elasticOut] 实现弹性动画效果。
  Widget _buildSuccessBar(TileModel tile) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: AnimatedSlide(
        offset: Offset(0, _feedbackCtrl.isAnimating ? 0 : 1), // 动画驱动时滑入（y=0），否则隐藏在屏幕下方（y=1）
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut, // 弹性缓出曲线：到达终点时轻微回弹
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

  // 构建本轮完成页面。
  //
  // 展示：奖杯图标 | 正确/错误数 | 正确率 | "Play Again" 按钮。
  // 点击"Play Again"会取消残留定时器并调用 restart() 重新开始一轮。
  Widget _buildFinishedScreen(state) {
    final l10n = AppLocalizations.of(context)!;
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
              Text(l10n.flashcardCorrect, style: const TextStyle(
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
                  _cancelTimer(); // 清理残留定时器
                  ref.read(flashcardQuizProvider.notifier).restart(); // 重置 quiz 状态
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(l10n.flashcardPlayAgain, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 脉冲提示组件：引导用户点击牌面查看助记卡片 ──

// 内部使用的脉冲动画提示组件。
// 显示 👆 图标 + "Tap tile to see mnemonic" 文字，透明度在 0.6~1.0 之间循环呼吸。
class _PulsingHint extends StatefulWidget {
  const _PulsingHint();
  @override
  State<_PulsingHint> createState() => _PulsingHintState();
}

// [_PulsingHint] 的状态管理类。
// 驱动透明度在 0.6~1.0 之间往返循环（1200ms 周期），形成呼吸/脉冲视觉效果。
class _PulsingHintState extends State<_PulsingHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl; // 透明度脉冲动画控制器

  @override
  void initState() {
    super.initState();
    // 创建往返循环动画控制器：0.0 → 1.0 → 0.0，周期 1200ms，无限循环
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose(); // 释放动画控制器
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 透明度脉冲：0.6（最低）↔ 1.0（最高），产生呼吸效果
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

