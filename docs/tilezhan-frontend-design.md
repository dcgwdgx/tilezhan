# TileZhan (麻雀斩) — 前端详细设计文档 v1.1

> 目标读者: Flutter 开发工程师
> 前置阅读: `tilezhan-architecture.md` (CTO 架构), `tilezhan-design-spec.md` (UI/UX 规范), `tilezhan-prototype.html` (v0.6 原型)
> 日期: 2026-06-06
> 修订: 2026-06-10 — CI 实测后更新依赖状态

---

## 目录

1. [项目初始化](#一项目初始化)
2. [设计系统实现](#二设计系统实现)
3. [路由设计](#三路由设计)
4. [状态管理](#四状态管理)
5. [数据层](#五数据层)
6. [核心组件库](#六核心组件库)
7. [页面详细设计](#七页面详细设计)
8. [动效与音效](#八动效与音效)
9. [离线同步](#九离线同步)
10. [错误处理](#十错误处理)
11. [测试矩阵](#十一测试矩阵)

---

## 一、项目初始化

### 1.1 环境要求

```yaml
# pubspec.yaml — CI 实测后更新 (2026-06-10)
name: tilezhan
description: Master Mahjong, One Tile at a Time.
version: 1.0.0+1

environment:
  sdk: ">=3.2.0 <4.0.0"
  flutter: ">=3.24.0"

dependencies:
  flutter:
    sdk: flutter

  # ── 状态管理 ──
  flutter_riverpod: ^2.5.1      # ✅ CI 通过

  # ── 路由 ──
  go_router: ^14.2.0             # ✅ CI 通过

  # ── 本地存储 ──
  hive: ^2.2.3                   # ✅ CI 通过 (CocoaPods)
  hive_flutter: ^1.1.0           # ✅ CI 通过 (CocoaPods)
  path_provider: ^2.1.0          # ✅ CI 通过 (CocoaPods) — 替代 shared_preferences
  # ⚠️ isar: 未在 CI 验证，待 Sprint 3 单独测试
  # ❌ shared_preferences: v2.3+ 使用 SPM，与手动 provisioning 冲突，已替换

  # ── 网络 ──
  dio: ^5.4.3+1                  # ✅ CI 通过 (纯 Dart)
  # ⚠️ connectivity_plus: 未验证，按需添加

  # ── Firebase ──
  # ❌ 全家桶: CocoaPods 版本冲突，CI 验证失败
  #    等 Apple SPM 生态成熟后再尝试，或使用 REST API

  # ── 支付 ──
  # ⚠️ purchases_flutter: Sprint 3 接入，待 CI 验证

  # ── 动效 ──
  flutter_svg: ^2.0.10+1         # ✅ CI 通过 (纯 Dart) — 牌面 SVG 渲染
  # ❌ flame: CocoaPods 原生依赖重，已移除，改用 CustomPainter
  # ❌ rive: 原生渲染引擎，已移除，改用 AnimationController
  # ⚠️ lottie / confetti: 按需添加

  # ── 工具 ──
  # ⚠️ 以下未在 CI 验证，按需添加:
  # ntp, encrypt, cached_network_image, haptic_feedback, audioplayers

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.9
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  mockito: ^5.4.4                # ✅ CI 通过 (纯 Dart)
  flutter_lints: ^4.0.0
```

### 1.1.1 依赖 CI 兼容性规则

> **策略**: 优先纯 Dart → 其次 CocoaPods → 避免 SPM（Swift Package Manager）

| 规则 | 原因 |
|------|------|
| 纯 Dart 包 | 零原生代码，永远不会破坏 iOS 构建 |
| CocoaPods 插件 | 成熟稳定，CI 已验证通过（hive, path_provider） |
| SPM 包 | 与 xcargs 手动 provisioning 冲突，构建失败 |
| Firebase | CocoaPods 版本冲突，待 SPM 生态稳定后重试 |
| Flame/Rive | 包体积大、CI 构建时间长，MVP 阶段用 CustomPainter 替代 |

### 1.2 入口文件

```dart
// lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase 初始化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. 本地数据库初始化
  await Isar.initializeIsar();

  // 3. NTP 时间同步
  await TimeService.sync();

  // 4. 启动 App
  runApp(
    const ProviderScope(
      child: TileZhanApp(),
    ),
  );
}
```

### 1.3 App 根组件

```dart
// lib/app.dart
class TileZhanApp extends ConsumerWidget {
  const TileZhanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TileZhan',
      debugShowCheckedModeBanner: false,
      theme: TileZhanTheme.darkTheme,    // 赛博国风暗黑主题
      routerConfig: router,
    );
  }
}
```

---

## 二、设计系统实现

### 2.1 色彩 Token

```dart
// lib/core/constants/app_colors.dart
class AppColors {
  // ── 底色 ──
  static const jadeDeep    = Color(0xFF0A2F1D);  // 主背景
  static const jadeCard    = Color(0xFF0D3D26);  // 卡片底色
  static const jadeHover   = Color(0xFF124D31);  // 悬停态

  // ── 强调色 ──
  static const vermillion  = Color(0xFFFF3B30);  // 主 CTA / 错误
  static const vermillionHover = Color(0xFFFF6B6B);
  static const neonGold    = Color(0xFFFFD700);  // Perfect / 胡牌特效
  static const neonGoldHover = Color(0xFFFFE44D);
  static const neonGoldDim = Color(0xFFFFC107);  // Good 判定

  // ── 文字色 ──
  static const jadeWhite   = Color(0xFFF5F0E8);  // 主文字
  static const jadeWhiteDim   = Color(0xFFD5CFC6);  // 次要文字
  static const jadeWhiteMuted = Color(0xFF8A847C);  // 禁用文字

  // ── 辅助色 ──
  static const celadonBlue = Color(0xFF4A90D9);  // 链接 / 助记标注
  static const demonPurple = Color(0xFF9B59B6);  // Pro / 传说徽章

  // ── 牌面花色编码 ──
  static const suitMan    = Color(0xFFE74C3C);  // 万子 - 朱红
  static const suitPin    = Color(0xFF3498DB);  // 筒子 - 宝蓝
  static const suitSou    = Color(0xFF2ECC71);  // 条子 - 翠绿
  static const suitWind   = Color(0xFFF39C12);  // 风牌 - 琥珀
  static const suitDragon = Color(0xFF9B59B6);  // 三元 - 妖紫
}
```

### 2.2 字体层级

```dart
// lib/core/constants/app_typography.dart
class AppTypography {
  static const _baseFamily = 'Poppins';
  static const _monoFamily = 'JetBrains Mono';
  static const _tileFamily = 'Noto Serif SC';  // 牌面汉字

  static const h1 = TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.25);
  static const h2 = TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.33);
  static const h3 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4);
  static const body = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static const bodySmall = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.43);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.33);
  static const tileChar = TextStyle(fontSize: 48, fontWeight: FontWeight.w700,
                                    fontFamily: _tileFamily);
  static const monoNumber = TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                                      fontFamily: _monoFamily);
}
```

### 2.3 主题配置

```dart
// lib/core/theme/tilezhan_theme.dart
class TileZhanTheme {
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.jadeDeep,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.vermillion,
      secondary: AppColors.neonGold,
      surface: AppColors.jadeCard,
      error: AppColors.vermillion,
    ),
    fontFamily: 'Poppins',
    cardTheme: CardTheme(
      color: AppColors.jadeCard,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.vermillion,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    // ... 更多覆盖
  );
}
```

---

## 三、路由设计

### 3.1 路由表

```dart
// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      // ── 启动 ──
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      // ── 新手引导 (仅首次) ──
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      // ── 首页 ──
      GoRoute(
        path: '/',
        builder: (_, __) => const HomeScreen(),
      ),
      // ── 闪卡训练 (可带花色参数) ──
      GoRoute(
        path: '/flashcard',
        builder: (_, state) => FlashcardScreen(
          suite: state.uri.queryParameters['suite'] ?? 'all',
        ),
      ),
      // ── 何切实战 ──
      GoRoute(
        path: '/nanikiru',
        builder: (_, state) => NaniKiruScreen(
          difficulty: state.uri.queryParameters['difficulty'] ?? 'beginner',
        ),
      ),
      // ── 牌浏览器 ──
      GoRoute(
        path: '/tiles',
        builder: (_, __) => const TileBrowserScreen(),
      ),
      // ── 番型图鉴 ──
      GoRoute(
        path: '/collection',
        builder: (_, __) => const CollectionScreen(),
        routes: [
          GoRoute(
            path: ':yakuId',
            builder: (_, state) => YakuDetailScreen(
              yakuId: state.pathParameters['yakuId']!,
            ),
          ),
        ],
      ),
      // ── 错题本 ──
      GoRoute(
        path: '/graveyard',
        builder: (_, __) => const GraveyardScreen(),
      ),
      // ── 付费墙 ──
      GoRoute(
        path: '/premium',
        builder: (_, __) => const PremiumScreen(),
      ),
      // ── 个人中心 ──
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
    ],
  );
});
```

### 3.2 导航守卫

```dart
// 在 GoRouter 中配置 redirect
redirect: (context, state) {
  final ref = ProviderScope.containerOf(context);
  final isFirstLaunch = ref.read(onboardingProvider);

  // 首次启动 → 引导页
  if (isFirstLaunch && state.matchedLocation != '/onboarding') {
    return '/onboarding';
  }
  // 已登录 → 正常路由
  return null;
},
```

---

## 四、状态管理

### 4.1 Provider 全景

```
Provider Tree
│
├── Global (app-level)
│   ├── authProvider              # 用户认证状态
│   ├── staminaProvider           # 体力值 (❤️❤️❤️)
│   ├── userProgressProvider      # 全局学习进度
│   ├── subscriptionProvider      # Pro 订阅状态
│   ├── syncProvider              # 离线同步管理器
│   └── settingsProvider          # 音效/震动/语言
│
├── Flashcard Module
│   ├── flashcardQuizProvider     # 本轮答题状态 (currentCard, queue, score)
│   ├── flashcardCountdownProvider # 1.5s 倒计时
│   └── tileDataProvider          # 34 张牌数据 (全量, 只读)
│
├── Nani-Kiru Module
│   ├── nanikiruQuizProvider      # 本轮何切状态
│   ├── nanikiruCountdownProvider # 5s 倒计时
│   └── selectedTileProvider      # 当前选中的牌 (null | tileId)
│
├── SRS Module
│   ├── srsDueProvider            # 到期复习题列表
│   └── srsStatsProvider          # 弱点雷达图数据
│
└── Tile Browser
    └── tileBrowserFilterProvider  # 当前花色筛选 (all | man | pin | sou | honor)
```

### 4.2 关键 Provider 实现

```dart
// ── 体力值 Provider ──
@riverpod
class Stamina extends _$Stamina {
  @override
  StaminaState build() {
    // 从本地 Isar 恢复 + 服务端同步
    _restoreAndSync();
    return StaminaState(current: 3, max: 3, nextRecoveryAt: null);
  }

  void decrease() {
    if (state.current <= 0) return;
    state = state.copyWith(current: state.current - 1);
    if (state.current == 0) {
      state = state.copyWith(
        nextRecoveryAt: TimeService.now().add(const Duration(hours: 4)),
      );
    }
    _persistAndReport();
  }

  void recover() {
    final now = TimeService.now();
    if (state.nextRecoveryAt != null && now.isAfter(state.nextRecoveryAt!)) {
      final recovered = ((now.difference(state.lastRecoveryAt!).inHours) ~/ 4)
          .clamp(0, state.max - state.current);
      state = state.copyWith(
        current: state.current + recovered,
        nextRecoveryAt: recovered < state.max - state.current
            ? now.add(const Duration(hours: 4))
            : null,
      );
    }
  }

  /// UI 层通过 Timer.periodic 每 30s 调用一次,
  /// 惰性计算剩余恢复时间 (避免频繁轮询服务端)
  Duration? refreshRecoveryTimer() {
    final now = TimeService.now();
    if (state.nextRecoveryAt == null) return null;
    if (now.isAfter(state.nextRecoveryAt!)) {
      recover();
      return null;
    }
    return state.nextRecoveryAt!.difference(now);
  }
}

// ── 闪卡答题 Provider ──
@riverpod
class FlashcardQuiz extends _$FlashcardQuiz {
  @override
  FlashcardQuizState build(String suite) {
    _loadQuiz(suite);
    return FlashcardQuizState.initial();
  }

  void _loadQuiz(String suite) {
    final tiles = _filterBySuite(suite);
    final quiz = tiles.take(10).toList();
    state = state.copyWith(queue: quiz, currentIndex: 0, score: 0);
  }

  void submitAnswer(String chosenTileId) {
    final current = state.queue[state.currentIndex];
    final isCorrect = chosenTileId == current.id;

    state = state.copyWith(
      lastAnswerCorrect: isCorrect,
      score: isCorrect ? state.score + 1 : state.score,
    );

    if (isCorrect) {
      ref.read(srsProvider.notifier).reportCorrect(current.id);
    } else {
      ref.read(srsProvider.notifier).reportWrong(current.id, chosenTileId);
      ref.read(staminaProvider.notifier).decrease();
    }
  }

  void nextCard() {
    if (state.currentIndex + 1 >= state.queue.length) {
      _loadQuiz(suite); // 重新出题
    } else {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  List<TileModel> _filterBySuite(String suite) {
    // 读取 tileDataProvider, 按花色过滤, 按 ELO 排序, 随机扰动
  }
}
```

### 4.3 状态模型 (Freezed)

```dart
// lib/features/flashcard/domain/flashcard_state.dart
@freezed
class FlashcardQuizState with _$FlashcardQuizState {
  const factory FlashcardQuizState({
    @Default([]) List<TileModel> queue,
    @Default(0) int currentIndex,
    @Default(0) int score,
    @Default(false) bool lastAnswerCorrect,
    @Default(false) bool isAnswering,    // 答题中 (锁定选项)
    @Default(false) bool isShowingMnemonic, // 展示助记翻转中
  }) = _FlashcardQuizState;
}

// lib/shared/models/tile_model.dart
@freezed
class TileModel with _$TileModel {
  const factory TileModel({
    required String id,           // "m1"~"m9", "p1"~"p9" ...
    required TileSuit suit,       // man | pin | sou | wind | dragon
    required String character,    // 汉字 "一"~"九", "東"~"白"
    required String seal,         // 紅色印章 "萬"/"筒"/"条"/"風"/"龍"
    required int value,           // 1-9 or special code
    required String label,        // "1-Man", "East" ...
    required MnemonicData mnemonic,
    required List<String> confusedWith,
  }) = _TileModel;
}

@freezed
class MnemonicData with _$MnemonicData {
  const factory MnemonicData({
    required String emoji,
    required String name,
    required String slogan,
    required String desc,
    required String chinese,
    required String anchor,
  }) = _MnemonicData;
}
```

---

## 五、数据层

### 5.1 数据源架构

```
┌─────────────────────────────────────────┐
│              Data Layer                   │
├─────────────────────────────────────────┤
│                                          │
│  ┌──────────────┐  ┌──────────────┐     │
│  │ TileRepository│  │PuzzleRepo    │     │
│  │  · 34张牌数据 │  │ · 每日题目    │     │
│  │  · 所有页面   │  │ · 预计算结果  │     │
│  │    共享       │  │              │     │
│  └──────┬───────┘  └──────┬───────┘     │
│         │                 │              │
│  ┌──────┴─────────────────┴───────┐     │
│  │        Data Sources            │     │
│  │  ┌────────┐ ┌────────┐ ┌─────┐│     │
│  │  │ Remote │ │ Local  │ │Cache││     │
│  │  │(API)   │ │(Isar)  │ │(Hive)│    │
│  │  └────────┘ └────────┘ └─────┘│     │
│  └────────────────────────────────┘     │
│                                          │
└─────────────────────────────────────────┘
```

### 5.2 TileRepository (34 张牌数据)

```dart
// lib/features/flashcard/data/tile_repository.dart
class TileRepository {
  // 34 张牌数据来源:
  //   开发阶段: 硬编码 JSON (lib/assets/data/tiles.json)
  //   生产阶段: 首次启动从 CDN 下载 → Isar 缓存

  final Isar _isar;

  /// 获取全量 34 张牌 (带助记数据)
  List<TileModel> getAllTiles() { ... }

  /// 按花色筛选
  List<TileModel> getBySuit(TileSuit suit) { ... }

  /// 按 ID 获取单张牌
  TileModel? getById(String id) { ... }

  /// 获取某张牌的易混淆牌列表
  List<TileModel> getConfusableTiles(String tileId) { ... }

  /// 获取指定数量的随机牌 (优先选易混淆的)
  List<TileModel> getRandomDistractors(String correctId, int count) { ... }
}
```

### 5.3 34 张牌 JSON 结构

```json
// lib/assets/data/tiles.json
[
  {
    "id": "m5",
    "suit": "man",
    "character": "五",
    "seal": "萬",
    "value": 5,
    "label": "5-Man",
    "mnemonic": {
      "emoji": "🏖️",
      "name": "The Lawn Chair",
      "slogan": "Max relaxation!",
      "desc": "Lounging on a 5-shaped folding beach chair while the Wand-Scooter cruises at 50,000 mph!",
      "chinese": "外卖小哥在车座上焊接了一张\"五\"字形的折叠沙滩椅，正躺在上面悠闲地喝可乐。",
      "anchor": "🧹 Wand-Scooter (Magic Scooter)"
    },
    "confusedWith": ["m4", "m6", "p5"]
  }
  // ... 其余 33 张
]
```

### 5.4 PuzzleRepository (题目数据)

```dart
// lib/core/network/puzzle_repository.dart
class PuzzleRepository {
  final Dio _dio;
  final Isar _isar;

  /// 获取今日卡包 (远程 → 本地缓存)
  Future<DailyQuest> fetchDailyQuest() async {
    try {
      final response = await _dio.get('/puzzles/daily');
      final quest = DailyQuest.fromJson(response.data);
      await _cacheQuest(quest);
      return quest;
    } on DioException {
      // 离线 → 使用本地缓存
      return _getCachedQuest();
    }
  }

  /// 提交答题结果
  Future<void> submitAnswer(AnswerReport report) async {
    try {
      await _dio.post('/puzzles/evaluate', data: report.toJson());
    } on DioException {
      // 离线 → 加入同步队列
      await _isar.syncQueue.put(SyncOperation(
        endpoint: '/puzzles/evaluate',
        payload: report.toJson(),
        createdAt: TimeService.now(),
      ));
    }
  }
}
```

### 5.5 SRS Repository

```dart
// lib/core/network/srs_repository.dart
class SrsRepository {
  /// SM-2 算法核心 (客户端执行)
  static SrsUpdateResult applySM2({
    required double easinessFactor,  // 初始 2.5
    required int repetitions,        // 初始 0
    required int intervalDays,       // 初始 1
    required int quality,            // 0-5
  }) {
    if (quality < 3) {
      return SrsUpdateResult(easinessFactor, 0, 1);
    }
    final ef = (easinessFactor +
        (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
        .clamp(1.3, double.infinity);
    final reps = repetitions + 1;
    final interval = reps == 1 ? 1 : reps == 2 ? 6 : (intervalDays * ef).round();
    return SrsUpdateResult(ef, reps, interval);
  }

  /// 获取到期复习题
  Future<List<SrsItem>> getDueReviews() async { ... }

  /// 上报答题结果并更新 SM-2 参数
  Future<void> reportAnswer(String tileId, int quality) async { ... }
}
```

---

## 六、核心组件库

### 6.1 TzTile (牌面组件)

```dart
// lib/shared/widgets/tz_tile.dart

enum TileSize { sm, md, lg }
enum TileState { normal, selected, floating, discarded, dimmed }

class TzTile extends StatelessWidget {
  final String tileId;
  final TileSize size;
  final TileState state;
  final bool showMnemonic;
  final double mnemonicOpacity;
  final bool isNewDraw;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  // ── 尺寸映射 ──
  static const _sizeMap = {
    TileSize.sm: Size(36, 52),
    TileSize.md: Size(52, 74),
    TileSize.lg: Size(64, 90),
  };

  // ── 构建 ──
  @override
  Widget build(BuildContext context) {
    final tile = context.read(tileDataProvider).getById(tileId)!;
    final tileSize = _sizeMap[size]!;
    final suitColor = _suitBorderColor(tile.suit);

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: tileSize.width,
        height: tileSize.height,
        decoration: BoxDecoration(
          color: _bgColor(state),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: state == TileState.selected
                ? AppColors.neonGold
                : suitColor.withOpacity(0.3),
            width: state == TileState.selected ? 2 : 1,
          ),
          boxShadow: _boxShadow(state, suitColor),
        ),
        transform: Matrix4.identity()
          ..translate(0.0, state == TileState.selected ? -6.0 : 0.0),
        child: Stack(
          children: [
            // 牌面汉字
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tile.character, style: _charStyle(size)),
                  const SizedBox(height: 2),
                  Text(tile.seal, style: _sealStyle(size, suitColor)),
                ],
              ),
            ),
            // 四角微标注
            if (showMnemonic)
              Positioned(
                top: 4, right: 6,
                child: Opacity(
                  opacity: mnemonicOpacity,
                  child: Text(tile.label,
                    style: const TextStyle(fontSize: 10, color: AppColors.celadonLight)),
                ),
              ),
            // 新摸牌虚线框
            if (isNewDraw)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.neonGold,
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _suitBorderColor(TileSuit suit) => switch (suit) {
    TileSuit.man    => AppColors.suitMan,
    TileSuit.pin    => AppColors.suitPin,
    TileSuit.sou    => AppColors.suitSou,
    TileSuit.wind   => AppColors.suitWind,
    TileSuit.dragon => AppColors.suitDragon,
  };

  Color _bgColor(TileState s) => switch (s) {
    TileState.dimmed => AppColors.jadeDeep.withOpacity(0.5),
    _ => AppColors.jadeCard,
  };

  List<BoxShadow> _boxShadow(TileState s, Color color) => switch (s) {
    TileState.selected => [
      BoxShadow(color: color.withOpacity(0.4), blurRadius: 16, spreadRadius: 2),
      BoxShadow(color: Colors.black54, blurRadius: 8, offset: const Offset(0, 4)),
    ],
    _ => [
      BoxShadow(color: Colors.black54, blurRadius: 8, offset: const Offset(0, 2)),
    ],
  };
}
```

### 6.2 TzButton (通用按钮)

```dart
// lib/shared/widgets/tz_button.dart

enum TzButtonVariant { primary, gold, ghost, outline }

class TzButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final TzButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: _buttonStyle(variant),
        child: _buildChild(),
      ),
    );
  }

  ButtonStyle _buttonStyle(TzButtonVariant v) => switch (v) {
    TzButtonVariant.primary => _primaryStyle,
    TzButtonVariant.gold    => _goldStyle,
    TzButtonVariant.ghost   => _ghostStyle,
    TzButtonVariant.outline => _outlineStyle,
  };

  Widget _buildChild() {
    if (isLoading) return const SizedBox(
      width: 20, height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[ Icon(icon, size: 18), const SizedBox(width: 8) ],
        Text(label),
      ],
    );
  }

  // 各 variant 的 ButtonStyle 定义...
}
```

### 6.3 TzCountdownRing (倒计时环)

```dart
// lib/shared/widgets/tz_countdown_ring.dart
class TzCountdownRing extends StatefulWidget {
  final double totalSeconds;
  final VoidCallback onTimeout;

  @override
  State<TzCountdownRing> createState() => _TzCountdownRingState();
}

class _TzCountdownRingState extends State<TzCountdownRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.totalSeconds * 1000).round()),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onTimeout();
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        size: const Size(70, 70),
        painter: _CountdownPainter(
          progress: _controller.value,
          color: _controller.value < 0.2 ? AppColors.vermillion : AppColors.neonGold,
        ),
      ),
    );
  }
}
```

### 6.4 TzFeedbackSheet (反馈抽屉)

```dart
// lib/shared/widgets/tz_feedback_sheet.dart
class TzFeedbackSheet extends StatelessWidget {
  final FeedbackType type;  // perfect | blunder
  final int ukeireCount;
  final int ukeireTypes;
  final List<String>? ukeireTiles;
  final String? tipText;

  @override
  Widget build(BuildContext context) {
    final isPerfect = type == FeedbackType.perfect;
    return Container(
      decoration: BoxDecoration(
        color: isPerfect
            ? AppColors.jadeCard.withGreenTint()   // 墨绿偏绿
            : AppColors.jadeCard.withRedTint(),    // 墨绿偏红
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 判定文字
          Text(
            isPerfect ? '🎯 PERFECT!' : '💥 BLUNDER!',
            style: TextStyle(
              fontSize: 36, fontWeight: FontWeight.w900,
              color: isPerfect ? AppColors.neonGold : AppColors.vermillion,
            ),
          ),
          const SizedBox(height: 12),
          // 统计数据行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(value: ukeireCount.toString(), label: 'Acceptance Tiles'),
              _StatItem(value: ukeireTypes.toString(), label: 'Types'),
              _StatItem(value: isPerfect ? 'Tenpai!' : '-7 tiles', label: 'Shanten'),
            ],
          ),
          if (ukeireTiles != null) ...[
            const SizedBox(height: 16),
            // 进张牌高亮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ukeireTiles!.map((t) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TzTile(tileId: t, size: TileSize.sm, ...),
              )).toList(),
            ),
          ],
          if (tipText != null) ...[
            const SizedBox(height: 12),
            Text(tipText!, style: AppTypography.bodySmall.copyWith(
              color: AppColors.jadeWhiteDim,
            )),
          ],
          const SizedBox(height: 20),
          TzButton(
            label: isPerfect ? 'Next Question →' : 'Got It',
            variant: isPerfect ? TzButtonVariant.gold : TzButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
```

---

## 七、页面详细设计

### 7.1 Splash → Home 跳转逻辑

```dart
// lib/features/splash/splash_screen.dart
class SplashScreen extends ConsumerStatefulWidget { ... }

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // 并行初始化
    Future.wait([
      _animController.forward(),
      _initApp(),
    ]).then((_) {
      final isFirstLaunch = ref.read(onboardingProvider);
      final route = isFirstLaunch ? '/onboarding' : '/';
      context.go(route);
    });
  }

  Future<void> _initApp() async {
    await ref.read(tileDataProvider.future);     // 加载 34 张牌
    await ref.read(staminaProvider.future);       // 恢复体力值
    await ref.read(syncProvider.notifier).sync(); // 离线同步
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo 旋转动画
            RotationTransition(
              turns: Tween(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
              ),
              child: const Text('🀄', style: TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _animController,
              child: const Text('TILEZHAN', style: ...),
            ),
            const SizedBox(height: 40),
            // 进度条
            LinearProgressIndicator(...),
          ],
        ),
      ),
    );
  }
}
```

### 7.2 Home Dashboard

```
Widget Tree:
HomeScreen
├── StatusBar (🔥 streak · ❤️❤️❤️ · 👑 PRO)
├── BadgeCard (Adept Lv.7 · 1248 ELO)
├── QuestCard                      ← 核心区域
│   ├── "✦ Today's Quest"
│   ├── FlashcardTask (进度条 + 8/10)
│   ├── NaniKiruTask (进度条 + 1/3)
│   ├── SrsReviewBadge (⚠ 12 due)
│   └── TzButton "⚡ START DAILY QUEST"
├── QuickGrid (2×3)
│   ├── Flashcards  ├── Nani-Kiru
│   ├── Tile Browser├── Yaku Guide
│   ├── Graveyard   └── Settings
└── BottomTabBar
    ├── 🏠 Home  ├── 🀄 Tiles  ├── 📚 Yaku  └── 👻 Review
```

```dart
// lib/features/home/presentation/home_screen.dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stamina = ref.watch(staminaProvider);
    final quest = ref.watch(dailyQuestProvider);
    final streak = ref.watch(streakProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _StatusBar(streak: streak, stamina: stamina),
              const SizedBox(height: 8),
              _BadgeCard(elo: ref.watch(eloProvider)),
              const SizedBox(height: 16),
              _QuestCard(quest: quest, onStart: () => context.go('/flashcard')),
              const SizedBox(height: 16),
              _QuickGrid(onNavigate: (route) => context.go(route)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomTabBar(...),
    );
  }
}
```

### 7.3 Flashcard Screen (核心)

```
Widget Tree:
FlashcardScreen
├── AppBar
│   ├── CloseButton (✕, 二次确认: "放弃将丢失进度")
│   ├── SuitFilterChips (All · Manzu · Pinzu · Souzu · Honors)
│   └── ProgressText "⚡3/10"
│
├── Body (Center)
│   ├── TzCountdownRing (1.5s)
│   ├── TzTile (240×320, suitBorderColor 生效)
│   ├── ProgressDots (⚫⚫🟡⚪⚪⚪⚪⚪⚪⚪)
│   ├── OptionGrid (4 选项)
│   │   ├── OptionBtn "A · 50,000 · (5-Man)"          ← 万子: 数值
│   │   ├── OptionBtn "B · 🔥 The Volcano · (8-Man)"  ← 其他: mnemonic
│   │   ├── OptionBtn "C · 🚀 Rocket · (6-Man)"
│   │   └── OptionBtn "D · 🪝 Crane · (7-Man)"
│   └── HintText "💡 Tap the tile to reveal mnemonic"
│
├── MnemonicOverlay (Stack overlay)
│   ├── Emoji (80px, bounceIn 动画)
│   ├── Name (The Lawn Chair)
│   ├── Slogan ("Max relaxation!")
│   ├── Desc (英文视觉描述)
│   ├── Chinese (中文记忆法, 小字灰色)
│   ├── Anchor (🧹 Wand-Scooter)
│   └── TzButton "Continue →"
│
└── SuccessBar (底部滑入, 绿色, 1.5s 后自动消失)
    └── "✨ 'Max relaxation!' ✨"
```

**状态流转**:

```
State Machine:
  idle → answering → correct_feedback → next_card
                   → wrong_feedback → mnemonic_flip → user_ack → next_card
  timeout → same as wrong_feedback

idle:
  - countdown 计时中
  - 4 个选项可点击
  - TzTile 可点击 (展示助记, 不扣分)

answering (点击选项后):
  - 倒计时暂停
  - 所有选项锁定 (pointerEvents: none)
  - 正确选项亮绿色 (border + glow)
  - 错误选项亮红色 (如果选错)
  - TzTile shake 动画 (如果答错)

correct_feedback (300ms):
  - 正确选项绿色脉冲
  - TzTile pulseGreen 动画
  - 粒子爆发 (Canvas overlay)
  - 800ms 后自动 → next_card

wrong_feedback (600ms):
  - 错误选项红色震动
  - 正确选项同时绿色高亮
  - TzTile shake 动画
  - → mnemonic_flip

mnemonic_flip:
  - MnemonicOverlay 从 TzTile 位置 3D 翻转展开
  - 展示完整助记数据
  - "Got it" 按钮 → user_ack → next_card

next_card:
  - currentIndex++
  - 倒计时重置
  - TzTile + 选项重新渲染
  - 或 → finishQuiz (如果 currentIndex == queue.length)
```

### 7.4 Nani-Kiru Screen (核心)

```
Widget Tree:
NaniKiruScreen
├── AppBar
│   └── "Nani-Kiru · Beginner" · "⚔️2/3"
│
├── PromptCard
│   ├── "You just drew:"
│   └── TzTile (新摸的牌, isNewDraw=true, 金色虚线框)
│       "7-Bam ← NEW!"
│
├── CountdownBar (10s, 最后 3s 变红 + 急促闪烁)
│
├── HandArea
│   ├── "Your Hand · 14 Tiles"
│   └── Wrap (flex-direction: row, gap: 6)
│       └── TzTile ×14
│           ├── normal: 翡翠绿底 + suitBorder
│           ├── selected: ↑15px + goldBorder + shadowFloating
│           └── newDraw: dashedGoldBorder + glowPulse
│
├── ToolBar
│   ├── TzButton("📐 Sort", ghost)
│   ├── TzButton("💡 Hint (-1❤️)", ghost)
│   └── TzButton("🏳️ Give Up", ghost)
│
├── [Stack] SlashCanvas (GameWidget<FlameGame>)
│   └── 刀光粒子特效 (用户打出牌时触发)
│
└── TzFeedbackSheet (bottomSheet, 滑入)
    ├── Perfect: 绿色底, "🎯 PERFECT!", 进张统计, 高亮牌, "Next →"
    └── Blunder: 红色底, "💥 BLUNDER!", 对比柱状图, 最优解高亮, "Got It"
```

**状态机** (Phase 枚举):

```dart
// lib/features/nanikiru/domain/nanikiru_phase.dart
enum NaniKiruPhase {
  ready,      // 等待用户操作
  selecting,  // 用户已选中一张牌 (浮起)
  animating,  // 斩击特效播放中 (锁定交互)
  feedback,   // 展示 FeedbackSheet
}
```

**交互流**:

```
Tap 1 (选中):
  selectedTileId = tileId
  TzTile.setState(selected) → Y轴上移 15px, 金色边框, 浮动阴影

Tap 2 (确认打出, 同一张牌):
  executeDiscard(tileId)

executeDiscard:
  1. 锁定所有 TzTile (pointerEvents: none)
  2. Flame slashEffect(tile.position) → 刀光 + 粒子
  3. 判定: correctId === tileId ?
       → Perfect: 延迟 400ms → showFeedbackSheet(perfect)
       → Blunder: 延迟 400ms → showFeedbackSheet(blunder)
                     → 同时: 最优解 TzTile 亮绿色高亮
                     → ref.read(staminaProvider).decrease()

Hint (-1❤️):
  1. 消耗 1 体力
  2. 最优解 TzTile 短暂高亮 1.5s (绿色 glow → 恢复)
  3. 不自动打出, 用户仍需手动选择

Give Up:
  1. 弹出确认 "Skip this question? (-1❤️)"
  2. 确认 → showFeedbackSheet(blunder) + 展示最优解
```

**Slash Effect (Flame 实现)**:

```dart
// lib/features/nanikiru/presentation/widgets/slash_effect.dart
class SlashEffect extends FlameGame {
  late final ParticleSystemComponent _sparks;
  bool _played = false;
  late Sprite _slashTrailSprite;

  @override
  Future<void> onLoad() async {
    // 预加载刀光贴图与金色粒子 — 避免首次播放卡顿
    await images.loadAll(['slash_trail.png', 'gold_particle.png']);
    _slashTrailSprite = Sprite(images.fromCache('slash_trail.png'));

    _sparks = ParticleSystemComponent(
      particle: Particle.generate(
        count: 40,
        generator: (i) => AcceleratedParticle(
          child: MovingParticle(
            to: Vector2.random() * 200 - 100,
            child: SpriteParticle(
              sprite: Sprite(images.fromCache('gold_particle.png')),
            ),
          ),
        ),
      ),
    );
    add(_sparks);
  }

  void play(Vector2 position) {
    if (_played) return;
    _played = true;
    _sparks.position = position;
    _sparks.particle?.reset();
    // 刀光轨迹: 左下→右上 对角线
    add(_SlashLine(position));
  }
}
```

### 7.5 Tile Browser

```
Widget Tree:
TileBrowserScreen
├── SuitFilterChips (All · Manzu · Pinzu · Souzu · Honors)
└── GridView.builder (4 columns, gap: 8)
    └── TileMiniCard × N
        ├── Emoji (24px)
        ├── Character (汉字, 22px)
        ├── Seal (红色, suitColor)
        └── Name ("The Lawn Chair", 10px)
            └── onTap → showBrowserMnemonic(tileId)
                └── MnemonicOverlay (同闪卡模块的 overlay)
```

### 7.6 Collection (Yaku Guide)

```dart
// lib/features/collection/presentation/collection_screen.dart
class CollectionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yakuList = ref.watch(yakuListProvider);

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: yakuList.length,
      itemBuilder: (_, i) => _YakuCard(yaku: yakuList[i]),
    );
  }

  Widget _YakuCard({required YakuModel yaku}) {
    if (yaku.isLocked) return _LockedCard();
    return GestureDetector(
      onTap: () => context.go('/collection/${yaku.id}'),
      child: Card(
        child: Column(
          children: [
            Text(yaku.emoji, style: const TextStyle(fontSize: 36)),
            Text(yaku.name, style: ...),
            Text(yaku.engName, style: ...),
            _Stars(yaku.mastery),
          ],
        ),
      ),
    );
  }
}
```

### 7.7 Graveyard (错题本)

```
Widget Tree:
GraveyardScreen
├── RadarChart (弱点雷达: Manzu/Pinzu/Souzu/Nani-Kiru)
│   └── CustomPaint + Path (5边形 + 数据填充)
├── "Today's Review · 12 due"
└── ListView
    └── GraveyardItem × N
        ├── TzTile (被答错的牌, sm 尺寸)
        ├── ErrorInfo
        │   ├── "5-Man · Mistook for 6-Man"
        │   └── "5 errors · 3 days ago"
        └── "Review →" (点击直接跳转该牌的闪卡复习)
```

### 7.8 Premium (付费墙)

```
Widget Tree:
PremiumScreen
├── CloseButton (✕, 右上角)
├── 💎 TILEZHAN PRO
├── FeatureList
│   ├── ✅ Unlimited Hearts
│   ├── ✅ All Mnemonic Illustrations
│   ├── ✅ Advanced Puzzle Packs
│   ├── ✅ AI Hand Diagnosis (V2)
│   └── ✅ Full Yaku Collection
├── PricingCards (垂直排列)
│   ├── 🌟 MOST POPULAR
│   │   └── Yearly · $29.99/year · $2.50/month · 50% OFF
│   ├── Monthly · $4.99/month
│   └── Weekly · $1.49/week
├── TzButton("Start Free Trial", gold, fullWidth)
└── Footer: "Restore Purchases" · "Terms" · "Privacy"
```

---

## 八、动效与音效

### 8.1 动效参数表

| 动效 | 引擎 | 时长 | 缓动 | 触发条件 |
|---|---|---|---|---|
| `cardSwipeOut` | 原生 Animation | 300ms | easeOutCubic | 闪卡下一张 |
| `cardEnter` | 原生 Animation | 250ms | easeOutBack | 闪卡新卡入 |
| `slashEffect` | Flame | 800ms | - | 何切打出牌 |
| `particleBurst` | Flame PS | 600ms | - | Perfect/胡牌/Combo |
| `cardFlip3D` | 原生 Transform | 400ms | easeInOutQuad | 错题翻转 |
| `shakeError` | 原生 Animation | 300ms | - | 答错震动 |
| `pulseGlow` | 原生 Animation | 1000ms | easeInOutSine | 正确选中 (循环) |
| `staminaBreak` | Rive | 500ms | - | 爱心碎裂 |
| `levelUp` | Rive | 1500ms | - | 升级庆祝 |
| `mnemonicIdle` | Rive | 循环 | - | 助记插画待机 (呼吸) |
| `mnemonicReveal` | Rive | 600ms | easeOutBack | 助记插画翻转揭示 |

**Rive 状态机控制模式**:

```dart
// 34 张牌的助记动效统一使用 Rive StateMachine
// 状态: idle (循环呼吸) → reveal (一次性揭示) → idle

class MnemonicRiveWidget extends StatefulWidget {
  final String riveAsset;  // 如 'assets/animations/m5_lawn_chair.riv'

  @override
  State<MnemonicRiveWidget> createState() => _MnemonicRiveWidgetState();
}

class _MnemonicRiveWidgetState extends State<MnemonicRiveWidget> {
  late RiveAnimationController _controller;
  SMITrigger? _revealTrigger;

  @override
  void initState() {
    super.initState();
    _controller = StateMachineController.fromArtboard(
      // 从 .riv 文件加载 artboard, 绑定 idle→reveal 状态机
    );
  }

  void reveal() {
    _revealTrigger?.fire();  // 触发 reveal 动画
  }

  @override
  Widget build(BuildContext context) {
    return RiveAnimation.asset(
      widget.riveAsset,
      controllers: [_controller],
    );
  }
}
```
| `countdownRing` | 原生 CustomPainter | 连续 | linear | 闪卡/何切倒计时 |

### 8.2 音效资产

| 文件 | 触发 | 格式 | 时长 |
|---|---|---|---|
| `tap.wav` | 普通点击 | WAV | 50ms |
| `correct.wav` | 答对 | WAV | 150ms |
| `wrong.wav` | 答错 | WAV | 300ms |
| `complete.wav` | 一轮完成 | WAV | 500ms |
| `slash.wav` | 切牌 | WAV | 200ms |

> **v1.1 新增**: 34 张牌中文 TTS 语音播报 (`assets/sounds/voice/{tileId}.wav`)
> 每张牌出现时自动播放其中文名称（如"五万"、"八条"、"東"），帮助非中文用户建立音形关联。由 Windows SAPI TTS 引擎生成。

### 8.3 Haptic 触觉

```dart
// lib/core/utils/haptic_service.dart
class HapticService {
  static void lightTap() => HapticFeedback.lightImpact();
  static void mediumTap() => HapticFeedback.mediumImpact();
  static void heavyError() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), HapticFeedback.heavyImpact);
  }
}
```

---

## 九、离线同步

### 9.1 SyncManager

```dart
// lib/core/sync/sync_manager.dart
class SyncManager {
  final Isar _isar;
  final Dio _dio;

  /// 监听网络状态变化, 自动触发同步
  void startListening() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.mobile)) {
        syncPendingOperations();
      }
    });
  }

  /// 将本地离线操作队列同步到服务端
  Future<void> syncPendingOperations() async {
    final pendingOps = await _isar.syncQueue
        .where()
        .sortByCreatedAt()
        .findAll();

    for (final op in pendingOps) {
      try {
        await _dio.post(op.endpoint, data: op.payload);

        // 服务端返回最终状态 (如 SRS 参数), 更新本地
        await _isar.syncQueue.delete(op.id);
      } on DioException catch (e) {
        if (e.response?.statusCode == 409) {
          // 冲突: 服务端数据更新
          await _resolveConflict(op, e.response!.data);
        }
        // 网络错误: 保留在队列, 下次重试
      }
    }
  }

  Future<void> _resolveConflict(SyncOperation op, Map<String, dynamic> serverData) async {
    // Last-Write-Wins: 以服务端 timestamp 为准
    if (serverData['timestamp'] > op.createdAt.millisecondsSinceEpoch) {
      // 服务端更新 → 覆盖本地
      await _applyServerState(serverData);
    }
    // 否则保留本地 (丢弃服务端)
    await _isar.syncQueue.delete(op.id);
  }
}
```

---

## 十、错误处理

### 10.1 全局错误边界

```dart
// lib/app.dart
MaterialApp.router(
  builder: (context, child) {
    // 全局错误捕获
    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack);
      return true;
    };
    return child!;
  },
);
```

### 10.2 错误状态 UI

```dart
// 通用错误 Widget (各页面复用)
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon('😵', size: 64),
          const SizedBox(height: 16),
          Text(message, style: AppTypography.body),
          const SizedBox(height: 16),
          TzButton(label: 'Retry', variant: TzButtonVariant.outline, onPressed: onRetry),
        ],
      ),
    );
  }
}
```

### 10.3 各 Provider 错误处理模式

```dart
@riverpod
Future<DailyQuest> dailyQuest(DailyQuestRef ref) async {
  try {
    return await ref.read(puzzleRepositoryProvider).fetchDailyQuest();
  } catch (e, stack) {
    // 1. 记录 Crashlytics
    FirebaseCrashlytics.instance.recordError(e, stack);

    // 2. 返回缓存 (如果有)
    final cached = await ref.read(cachedQuestProvider.future);
    if (cached != null) return cached;

    // 3. 无法恢复 → 抛出给 UI 层展示 ErrorStateWidget
    rethrow;
  }
}
```

---

## 十一、测试矩阵

### 11.1 测试金字塔

```
         ┌──────┐
         │ E2E  │ 5%   — integration_test/ (关键流程)
         ├──────┤
         │Widget│ 15%  — test/features/ (组件交互 + 状态)
         ├──────┤
         │ Unit │ 80%  — test/core/ (算法 + 数据 + Providers)
         └──────┘
```

### 11.2 关键测试用例

| 类别 | 测试项 | 文件 |
|---|---|---|
| **Unit** | SM-2 算法: quality=3 → interval 正确递增 | `test/core/srs/sm2_test.dart` |
| **Unit** | Shanten Calculator: 标准听牌 → 返回 0 | `test/core/shanten/shanten_test.dart` |
| **Unit** | TileRepository: 按花色筛选返回正确数量 | `test/features/flashcard/tile_repo_test.dart` |
| **Unit** | Stamina Provider: 扣减后 nextRecoveryAt 正确 | `test/core/stamina_test.dart` |
| **Widget** | TzTile: selected 态上浮 15px + 金色边框 | `test/shared/tz_tile_test.dart` |
| **Widget** | FlashcardScreen: 答对 → 绿色脉冲 + 自动跳转 | `test/features/flashcard/flashcard_test.dart` |
| **Widget** | NaniKiruScreen: 双重点击确认打出 | `test/features/nanikiru/nanikiru_test.dart` |
| **Widget** | FeedbackSheet: Perfect 显示绿色背景 + 进张统计 | `test/shared/feedback_sheet_test.dart` |
| **Integration** | 完整闪卡流程: Splash → Home → Flashcard → 答题 → 结算 | `integration_test/flashcard_flow_test.dart` |
| **Integration** | 离线答题 → 联网 → 数据同步 | `integration_test/offline_sync_test.dart` |

### 11.3 Widget 测试示例

```dart
// test/features/flashcard/flashcard_test.dart
void main() {
  testWidgets('答对后正确选项变绿, 1s 后自动跳转下一张', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tileDataProvider.overrideWith((_) => mockTiles)],
        child: const TileZhanApp(),
      ),
    );

    await tester.tap(find.text('A')); // 选正确选项
    await tester.pump();

    // 验证: 选项 A 的 borderColor = successGreen
    final optionA = tester.widget<Container>(find.byKey(const Key('option-A')));
    expect(
      (optionA.decoration as BoxDecoration).border!.top.color,
      AppColors.neonGold,
    );

    // 验证: 1s 后自动加载下一张
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('六'), findsOneWidget); // 下一张牌
  });
}
```

---

> 📐 本文档面向 Flutter 前端工程师。配合 `tilezhan-architecture.md` (后端视角) 和 `tilezhan-design-spec.md` (UI/UX 视角) 阅读，覆盖开发的全部维度。
> 修订: v1.0 (2026-06-06) — 初始前端详细设计。
