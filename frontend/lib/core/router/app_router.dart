/// GoRouter 路由配置，定义应用全屏页面的路径映射与转场动画。
///
/// ## 路由架构
///
/// 采用扁平路由结构（无嵌套 ShellRoute），共 14 条顶级路由，每条均通过
/// 统一的 [_page] 工厂构建 [CustomTransitionPage]。
///
/// ## 转场动画
///
/// 页面切换使用统一的"从右向左滑入 + 淡入"效果：
/// - 位移：X 轴从 10% 偏移滑入至原位（[SlideTransition]）
/// - 透明度：从 0 淡入至 1（[FadeTransition]）
/// - 曲线：[Curves.easeOutCubic] 用于位移确保减速收尾自然，
///   [Curves.easeOut] 用于透明度使淡入平滑
/// - 时长：200ms，兼顾视觉反馈与响应速度
///
/// ## 路由表
///
/// | 路径              | 页面              | 说明                     |
/// |-------------------|-------------------|--------------------------|
/// | `/splash`         | SplashScreen      | 启动闪屏 / Logo 展示     |
/// | `/onboarding`     | OnboardingScreen  | 首次使用引导             |
/// | `/`               | HomeScreen        | 主页 / 首页              |
/// | `/flashcard`      | FlashcardScreen   | 闪卡学习（?suite= 牌组）  |
/// | `/nanikiru`       | NanikiruScreen    | 何切练习                 |
/// | `/tiles`          | TileBrowserScreen | 牌览 / 牌谱浏览          |
/// | `/collection`     | CollectionScreen  | 我的收藏                 |
/// | `/graveyard`      | GraveyardScreen   | 牌河 / 弃牌记录          |
/// | `/premium`        | PremiumScreen     | 高级版 / 会员            |
/// | `/scanner`        | ScannerScreen     | 扫码功能                 |
/// | `/profile`        | ProfileScreen     | 个人中心                 |
/// | `/settings`       | SettingsScreen    | 设置页面                 |
/// | `/yaku/:id`       | YakuDetailScreen  | 役种详情（路径参数 id）   |
/// | `/leaderboard`    | LeaderboardScreen | 排行榜                   |
///
/// ## 导航入口
///
/// 初始位置固定为 `/splash`，应用启动后由闪屏页根据业务状态跳转至
/// `/onboarding`（首次使用）或 `/`（已登录）。
///
/// ## 使用示例
///
/// ```dart
/// // 在 MaterialApp.router 中使用
/// MaterialApp.router(
///   routerConfig: appRouter,
/// );
///
/// // 在任意页面内部跳转
/// context.go('/flashcard?suite=yakuman');
/// context.push('/yaku/13_orphans');
/// ```
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ---------- 功能页面导入 ----------
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/flashcard/presentation/flashcard_screen.dart';
import '../../features/nanikiru/presentation/nanikiru_screen.dart';
import '../../features/tile_browser/presentation/tile_browser_screen.dart';
import '../../features/collection/presentation/collection_screen.dart';
import '../../features/graveyard/presentation/graveyard_screen.dart';
import '../../features/premium/presentation/premium_screen.dart';
import '../../features/scanner/presentation/scanner_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/yaku_detail/presentation/yaku_detail_screen.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';

// 将 [child] 包装为统一的 [CustomTransitionPage]，提供从右向左滑入 + 淡入的
// 200ms 转场动画。该函数是所有路由 `pageBuilder` 的统一工厂。
//
// - [child]：目标页面 Widget，由各路由的 `pageBuilder` 传入
// - [state]：GoRouter 的当前路由状态，用于提取 [pageKey] 确保路由键唯一
// - 返回：携带统一转场动画配置的 [CustomTransitionPage]
//
// 内部组成：
// - [SlideTransition]：X 轴 10% → 0，[Curves.easeOutCubic] 实现减速收尾
// - [FadeTransition]：0 → 1，[Curves.easeOut] 使淡入平滑自然
// - 总时长 200ms，兼顾反馈速度与视觉流畅度
CustomTransitionPage _page(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    // 使用 GoRouter 自动生成的 pageKey，确保每次导航时 Widget 树中的 Key 唯一
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        // 构建位移补间：从 X=0.1 (10% 偏移) 到 X=0 (原位)
        position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
            // 使用 easeOutCubic 曲线，先快后慢的减速收尾
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          // 透明度补间：从 0 (全透明) 到 1 (不透明)
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
}

/// 应用全局路由单例，包含 14 条全屏页面的扁平路由映射。
///
/// ## 路由设计
///
/// 所有路由均为顶级 [GoRoute]，未使用 [ShellRoute] 或嵌套路由。
/// 每条路由的 [pageBuilder] 均委托给 [_page] 工厂方法以复用统一的转场动画。
///
/// ## 初始位置
///
/// [initialLocation] 固定为 `/splash`，应用启动后由此页根据业务逻辑
/// 决定下一步跳转目标（引导页或主页）。
///
/// ## 参数传递
///
/// - `/flashcard?suite=<牌组名>` — 通过查询参数 [suite] 指定闪卡牌组，
///   默认值为 `'all'`
/// - `/yaku/:id` — 通过路径参数 [id] 指定役种标识符，如 `/yaku/13_orphans`
///
/// ## 使用方式
///
/// ```dart
/// // 声明式配置
/// MaterialApp.router(routerConfig: appRouter);
///
/// // 命令式导航
/// context.goNamed('flashcard', queryParameters: {'suite': 'kokushi'});
/// ```
final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // 闪屏启动页 —— 显示应用 Logo / 品牌画面，短暂停留后自动跳转
    GoRoute(path: '/splash', pageBuilder: (_, state) => _page(const SplashScreen(), state)),
    // 引导页 —— 首次安装后展示的功能引导 / 新手教学
    GoRoute(path: '/onboarding', pageBuilder: (_, state) => _page(const OnboardingScreen(), state)),
    // 主页 —— 应用核心入口，聚合各功能模块的导航中枢
    GoRoute(path: '/', pageBuilder: (_, state) => _page(const HomeScreen(), state)),
    // 闪卡学习页 —— 以卡片形式学习麻将牌型和役种，支持 ?suite= 参数切换牌组
    GoRoute(path: '/flashcard', pageBuilder: (_, state) => _page(
      FlashcardScreen(suite: state.uri.queryParameters['suite'] ?? 'all'), state)),
    // 何切练习页 —— "何切" 实战训练，给定手牌选择最佳切牌
    GoRoute(path: '/nanikiru', pageBuilder: (_, state) => _page(const NanikiruScreen(), state)),
    // 牌览页 —— 浏览全部麻将牌面，含牌谱和图鉴
    GoRoute(path: '/tiles', pageBuilder: (_, state) => _page(const TileBrowserScreen(), state)),
    // 收藏页 —— 用户收藏的牌型 / 役种 / 牌谱
    GoRoute(path: '/collection', pageBuilder: (_, state) => _page(const CollectionScreen(), state)),
    // 牌河页 —— 弃牌记录与统计，回顾历史弃牌数据
    GoRoute(path: '/graveyard', pageBuilder: (_, state) => _page(const GraveyardScreen(), state)),
    // 高级版页 —— 会员订阅 / 高级功能解锁
    GoRoute(path: '/premium', pageBuilder: (_, state) => _page(const PremiumScreen(), state)),
    // 扫码页 —— 启动相机扫描二维码 / 牌面识别
    GoRoute(path: '/scanner', pageBuilder: (_, state) => _page(const ScannerScreen(), state)),
    // 个人中心 —— 用户头像、昵称、战绩统计等个人资料
    GoRoute(path: '/profile', pageBuilder: (_, state) => _page(const ProfileScreen(), state)),
    // 设置页 —— 全局配置（音效、语言、主题、隐私等）
    GoRoute(path: '/settings', pageBuilder: (_, state) => _page(const SettingsScreen(), state)),
    // 役种详情页 —— 展示单个役种的定义、牌例、番数等详细信息
    // :id 为役种唯一标识（如 13_orphans、big_three_dragons）
    GoRoute(path: '/yaku/:id', pageBuilder: (_, state) => _page(
      YakuDetailScreen(yakuId: state.pathParameters['id']!), state)),
    // 排行榜页 —— 全服或好友间的分数 / 段位排行
    GoRoute(path: '/leaderboard', pageBuilder: (_, state) => _page(const LeaderboardScreen(), state)),
  ],
);
