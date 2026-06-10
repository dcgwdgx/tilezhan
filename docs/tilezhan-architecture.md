# TileZhan (麻雀斩) — CTO 架构设计文档 v1.1

> 作者: CTO
> 日期: 2026-06-06
> 修订: 2026-06-10 — CI 实测后更新 ADR 状态
> 基线版本: v0.6 (赛博国风原型)
> 状态: Sprint 1+2 完成，CI 构建通过

---

## 目录

1. [架构总览](#一架构总览)
2. [前端架构 (Flutter)](#二前端架构-flutter)
3. [后端架构 (Python FastAPI + Firebase)](#三后端架构-python-fastapi--firebase)
4. [麻将算番引擎](#四麻将算番引擎)
5. [数据架构](#五数据架构)
6. [SRS 错题沉淀系统](#六srs-错题沉淀系统)
7. [安全架构](#七安全架构)
8. [基础设施与部署](#八基础设施与部署)
9. [可观测性](#九可观测性)
10. [MVP 交付范围与 Sprint 拆解](#十mvp-交付范围与-sprint-拆解)

---

## 一、架构总览

### 1.1 系统分层

```
┌──────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                            │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              Flutter App (iOS / Android)             │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐            │ │
│  │  │ Flashcard│ │ Nani-Kiru│ │Yaku Guide│  ...       │ │
│  │  │ Module   │ │ Module   │ │ Module   │            │ │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘            │ │
│  │       └──────────────┼──────────────┘               │ │
│  │               ┌──────┴──────┐                       │ │
│  │               │  Core Layer │                       │ │
│  │               │  (Domain)   │                       │ │
│  │               └──────┬──────┘                       │ │
│  │         ┌────────────┼────────────┐                 │ │
│  │    ┌────┴────┐  ┌────┴────┐  ┌───┴────┐            │ │
│  │    │File JSON│  │  Hive   │  │Shanten │            │ │
│  │    │(Struct) │  │(Cache)  │  │ Calc   │            │ │
│  │    └─────────┘  └─────────┘  └────────┘            │ │
│  └─────────────────────────────────────────────────────┘ │
└──────────────────────┬───────────────────────────────────┘
                       │ HTTPS / WSS
┌──────────────────────┴───────────────────────────────────┐
│                   API GATEWAY LAYER                        │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              Cloudflare CDN / DNS                    │ │
│  │         (Static Assets + DDoS Protection)            │ │
│  └──────────────────────┬──────────────────────────────┘ │
│                         │                                  │
│  ┌──────────────────────┴──────────────────────────────┐ │
│  │           FastAPI (GCP Cloud Run / Railway)          │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐    │ │
│  │  │ Auth     │ │ Puzzle   │ │  Mahjong Engine   │    │ │
│  │  │ Proxy    │ │ Service  │ │  (Python/C++)     │    │ │
│  │  └──────────┘ └──────────┘ └──────────────────┘    │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐    │ │
│  │  │ SRS      │ │ IAP      │ │  Analytics Proxy  │    │ │
│  │  │ Scheduler│ │ Validator│ │                   │    │ │
│  │  └──────────┘ └──────────┘ └──────────────────┘    │ │
│  └──────────────────────┬──────────────────────────────┘ │
└──────────────────────┬───────────────────────────────────┘
                       │
┌──────────────────────┴───────────────────────────────────┐
│                   DATA LAYER                               │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────┐ │
│  │Firestore │ │  Firebase│ │  Cloud   │ │  RevenueCat │ │
│  │(User/Game│ │  Auth    │ │  Storage │ │  (IAP)      │ │
│  │  Data)   │ │          │ │(Screenshots)│ │            │ │
│  └──────────┘ └──────────┘ └──────────┘ └────────────┘ │
└──────────────────────────────────────────────────────────┘
```

### 1.2 核心架构决策 (ADR)

| # | 决策 | 选择 | CI 实测 |
|---|---|---|---|
| ADR-1 | 客户端框架 | Flutter ≥3.24 | ✅ |
| ADR-2 | 后端计算层 | Python FastAPI | ✅ 代码完成，未部署 |
| ADR-3 | BaaS 数据层 | Firebase ❌→ REST API | ❌ CocoaPods 冲突，改用纯 Dart 文件存储 |
| ADR-4 | 算番策略 | 95%预计算 + 5%端侧 | ✅ Dart ShantenCalculator |
| ADR-5 | SRS 算法 | SM-2 (MVP) → FSRS (V2) | ✅ SM-2 已实现并测试 |
| ADR-6 | 规则体系 | 日麻 Riichi (MVP) | ✅ |
| ADR-7 | 支付 | RevenueCat | ⚠️ Sprint 3，待 CI 验证 |
| ADR-8 | 动效 | ~~Flame+Rive~~ → 原生 Animation + CustomPainter | ❌ Flame/Rive CI 失败，已替换 |

---

## 二、前端架构 (Flutter)

### 2.1 项目结构

```
tilezhan/
├── lib/
│   ├── main.dart                         # App 入口, 初始化 Firebase/Rive/Isar
│   ├── app.dart                          # MaterialApp.router + ThemeData
│   │
│   ├── core/                             # ── 基础设施层 (不依赖任何 feature)
│   │   ├── constants/
│   │   │   ├── app_colors.dart           # 赛博国风色彩 Token
│   │   │   ├── app_typography.dart       # 字体层级 (Poppins + Noto Serif SC)
│   │   │   ├── app_spacing.dart          # 8px Grid 间距
│   │   │   └── api_endpoints.dart        # API 端点常量
│   │   ├── theme/
│   │   │   └── tilezhan_theme.dart       # ThemeData: 暗黑翡翠绿底 + 霓虹金 accent
│   │   ├── storage/
│   │   │   ├── isar_service.dart         # Isar 结构化数据 (用户进度/SRS状态)
│   │   │   └── hive_service.dart         # Hive KV 缓存 (题库/设置)
│   │   ├── network/
│   │   │   ├── dio_client.dart           # Dio HTTP 客户端 (Base URL, 拦截器, 重试)
│   │   │   └── api_repository.dart       # API 调用封装
│   │   ├── router/
│   │   │   └── app_router.dart           # GoRouter 路由配置
│   │   ├── analytics/
│   │   │   └── analytics_service.dart    # Firebase Analytics + Amplitude 封装
│   │   └── utils/
│   │       ├── shanten_calculator.dart   # 客户端向听数计算器 (Dart)
│   │       └── sm2_algorithm.dart        # SM-2 间隔重复算法
│   │
│   ├── shared/                           # ── 共享层
│   │   ├── widgets/
│   │   │   ├── tz_button.dart            # 通用按钮 (primary/gold/ghost)
│   │   │   ├── tz_card.dart              # 通用卡片
│   │   │   ├── tz_progress_bar.dart      # 进度条
│   │   │   ├── tz_countdown_ring.dart    # 倒计时环
│   │   │   └── tz_tile.dart              # ⭐ 核心牌面组件
│   │   └── models/
│   │       ├── tile_model.dart            # 牌数据模型 (34张)
│   │       ├── puzzle_model.dart          # 题目模型
│   │       ├── srs_item_model.dart        # SRS 条目模型
│   │       └── user_progress_model.dart   # 用户进度模型
│   │
│   ├── features/                         # ── 功能模块层
│   │   ├── splash/                       # 启动页
│   │   ├── onboarding/                   # 新手引导 (3-Step)
│   │   ├── home/                         # 首页 Dashboard
│   │   │   ├── presentation/
│   │   │   │   ├── home_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── badge_card.dart
│   │   │   │       ├── quest_card.dart
│   │   │   │       └── quick_grid.dart
│   │   │   └── domain/
│   │   │       └── home_state.dart
│   │   │
│   │   ├── flashcard/                    # ⭐ 闪卡训练 (核心)
│   │   │   ├── presentation/
│   │   │   │   ├── flashcard_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── tile_display.dart      # 牌面展示 (含边框颜色编码)
│   │   │   │       ├── option_grid.dart       # 四选一选项网格
│   │   │   │       ├── mnemonic_overlay.dart   # 助记插画翻转层
│   │   │   │       └── countdown_ring.dart     # 1.5s 倒计时
│   │   │   ├── domain/
│   │   │   │   ├── flashcard_state.dart
│   │   │   │   └── quiz_engine.dart           # 出题逻辑 (花色筛选+易混淆优先)
│   │   │   └── data/
│   │   │       ├── tile_repository.dart        # 34张牌数据源
│   │   │       └── flashcard_repository.dart
│   │   │
│   │   ├── nanikiru/                    # ⭐ 何切实战 (核心)
│   │   │   ├── presentation/
│   │   │   │   ├── nanikiru_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── hand_area.dart          # 14张手牌渲染区
│   │   │   │       ├── prompt_card.dart        # 题目提示卡
│   │   │   │       ├── feedback_sheet.dart     # Perfect/Blunder 反馈抽屉
│   │   │   │       └── slash_effect.dart       # Flame 刀光特效组件
│   │   │   ├── domain/
│   │   │   │   ├── nanikiru_state.dart
│   │   │   │   └── discard_evaluator.dart      # 打牌判定逻辑
│   │   │   └── data/
│   │   │       └── nanikiru_repository.dart
│   │   │
│   │   ├── tile_browser/                # 牌浏览器 (34张网格)
│   │   ├── collection/                   # 番型图鉴
│   │   ├── graveyard/                    # 错题本 (Tile Graveyard)
│   │   ├── scanner/                      # Yaku Scanner (X-Ray 扫描)
│   │   ├── premium/                      # 付费墙 + IAP
│   │   └── profile/                      # 个人中心
│   │
│   └── l10n/                            # 多语言 (P0: EN, P1: JA, P2: FR/DE)
│       ├── app_en.arb
│       └── app_ja.arb
│
├── assets/
│   ├── tiles/                           # 34张牌 SVG 矢量
│   ├── mnemonic/                         # 34张助记插画 (PNG/WebP)
│   ├── animations/                       # Rive 动效文件 (.riv)
│   ├── sounds/                           # 音效 (slash.mp3, correct.mp3, error.mp3)
│   └── fonts/                            # Poppins + JetBrains Mono
│
├── test/                                 # 单元测试 + Widget 测试
├── integration_test/                     # 集成测试
└── pubspec.yaml
```

### 2.2 状态管理

**选择**: Riverpod (推荐) 或 flutter_bloc

| 模块 | 状态管理方案 | 理由 |
|---|---|---|
| Flashcard | `StateNotifierProvider` | 高频状态变化 (倒计时+选项锁定+翻转) |
| Nani-Kiru | `StateNotifierProvider` | 复杂多状态 (选中/确认/反馈) |
| Home Dashboard | `FutureProvider` | 异步加载每日任务 |
| Tile Browser | `Provider` | 简单筛选状态 |
| SRS/Graveyard | `FutureProvider` + `StreamProvider` | 离线优先 + Firestore 同步 |

### 2.3 离线架构

```
┌─────────────────────────────────────────┐
│            Offline-First Strategy        │
├─────────────────────────────────────────┤
│                                          │
│  Layer 1: 静态资产 (打包进 APK/IPA)      │
│  ├─ 34 张牌 SVG                          │
│  ├─ 34 张助记插画 WebP                   │
│  ├─ Rive 动效文件                        │
│  └─ 音效文件                             │
│                                          │
│  Layer 2: 题库缓存 (Hive)                │
│  ├─ 每日卡包 → 本地缓存                  │
│  ├─ 预计算结果 (14种打法的进张数)         │
│  └─ TTL 24h, 联网静默刷新                │
│                                          │
│  Layer 3: 用户数据 (File JSON / Hive)    │
│  ├─ File JSON: SRS 条目 + 进度 (dart:io) │
│  ├─ Hive: KV 缓存 (设置 / 题库)          │
│  ├─ Isar: 待 CI 验证后接入 (结构化数据)   │
│  └─ 冲突: Last-Write-Wins (进度数据)      │
│                                          │
│  Layer 4: 离线降级                        │
│  ├─ 无网: 使用本地缓存题库, 进度存 Isar   │
│  ├─ 恢复网络: WorkManager 触发 SyncManager│
│  └─ UI: 底部 Banner "Syncing..."         │
│                                          │
└─────────────────────────────────────────┘
```

### 2.4 核心组件: `<TzTile/>`

```dart
/// 最底层麻将牌组件 — 所有页面复用
class TzTile extends StatelessWidget {
  final String tileId;        // "m1"~"m9", "p1"~"p9", "s1"~"s9", "z1"~"z7"
  final TileSize size;        // sm(36) | md(48) | lg(64)
  final TileState state;      // normal | selected | floating | discarded | dimmed
  final bool showMnemonic;    // 是否显示四角微标注 (随用户等级渐进淡出)
  final double mnemonicOpacity; // 标注透明度 (Lv.1=1.0 → Lv.10=0.0)
  final bool isNewDraw;       // 刚摸的牌 → 金色虚线框
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap; // 二次确认打出

  // ... build method
}
```

### 2.5 动效引擎分层

| 层 | 引擎 | 场景 | 性能要求 |
|---|---|---|---|
| Layer 1 | 原生 Animation | 按钮状态 / 卡片选中 / 进度条 / 页面转场 | 60fps |
| Layer 2 | Rive | 34张牌 Mnemonic 微动效 / 付费墙庆祝 / 爱心碎裂 | 60fps |
| Layer 3 | Flame Engine | 何切刀光斩击 + 粒子爆发 (核心爽点) | 60fps, 独立 GameWidget |
| Layer 4 | Canvas | Confetti 撒花 / 进度粒子 | 不阻断底层交互 |

### 2.6 性能指标

| 指标 | 目标 | 测量方式 |
|---|---|---|
| 闪卡页帧率 | ≥60fps (iPhone 11+) | Flutter DevTools Performance |
| 何切反馈延迟 | <150ms (点击→Perfect/Blunder 出现) | Firebase Performance |
| 冷启动时间 | <2s | Firebase Performance |
| 包体积 (Android) | <25MB | CI 构建报告 |
| 离线可用 | 当日卡包完全离线 | 飞行模式测试 |

---

## 三、后端架构 (Python FastAPI + Firebase)

### 3.1 API 端点全景

```
BASE: https://api.tilezhan.app/v1

┌─────────────────────────────────────────────────────────┐
│                     AUTH (Firebase)                      │
│  POST   /auth/register          # 注册                   │
│  POST   /auth/login             # 登录 (返回 Firebase Token)│
│  POST   /auth/refresh           # Token 刷新              │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                     USER & PROGRESS                       │
│  GET    /user/profile            # 用户信息 + 统计        │
│  PATCH  /user/settings          # 更新设置               │
│  GET    /user/progress           # 各模块通关进度         │
│  POST   /user/progress           # 上报进度              │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                     PUZZLE SERVICE                        │
│  GET    /puzzles/daily           # 获取今日卡包 (含预计算结果) │
│  GET    /puzzles/flashcards?suite=man&count=10  # 闪卡题目│
│  GET    /puzzles/nanikiru?difficulty=beginner    # 何切题目│
│  POST   /puzzles/evaluate        # 提交答案 → 获取反馈    │
│  GET    /puzzles/:id/mnemonic    # 获取单题助记数据       │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                   MAHJONG ENGINE (付费)                    │
│  POST   /mahjong/calculate       # 完整算番 (14张 → Yaku列表)│
│  POST   /mahjong/shanten         # 向听数计算              │
│  POST   /mahjong/ukeire          # 进张数计算 (打某张后的进张)│
│  POST   /mahjong/analyze         # AI 牌局诊断 (V2, OCR截图)│
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                     SRS SYSTEM                            │
│  GET    /srs/review_due           # 获取到期复习题         │
│  POST   /srs/report              # 上报答题结果 → 更新 SM-2 │
│  GET    /srs/stats               # 用户记忆统计 (雷达图)   │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                   SUBSCRIPTION                            │
│  POST   /subscription/verify      # 服务端二次验证 Receipt │
│  GET    /subscription/status      # 查询订阅状态           │
│  POST   /webhooks/revenuecat     # RevenueCat Webhook     │
└─────────────────────────────────────────────────────────┘
```

### 3.2 FastAPI 项目结构

```
backend/
├── app/
│   ├── main.py                    # FastAPI app + CORS + 中间件
│   ├── config.py                  # 环境变量 / 配置
│   │
│   ├── api/
│   │   ├── __init__.py
│   │   ├── deps.py                # 依赖注入 (DB session, Auth)
│   │   └── v1/
│   │       ├── router.py          # 聚合所有路由
│   │       ├── auth.py
│   │       ├── user.py
│   │       ├── puzzles.py
│   │       ├── mahjong.py
│   │       ├── srs.py
│   │       └── subscription.py
│   │
│   ├── core/
│   │   ├── security.py            # JWT 验证 / Firebase Auth
│   │   ├── firebase.py            # Firestore 客户端
│   │   └── revenuecat.py          # RevenueCat REST API 封装
│   │
│   ├── domain/
│   │   ├── models/
│   │   │   ├── user.py
│   │   │   ├── puzzle.py
│   │   │   ├── tile.py            # 34张牌定义 (ID, suit, value)
│   │   │   └── srs_item.py
│   │   └── services/
│   │       ├── puzzle_service.py  # 题库生成 + 预计算
│   │       ├── srs_service.py     # SM-2 调度
│   │       └── subscription_service.py
│   │
│   ├── engine/                    # ⭐ 麻将算番引擎
│   │   ├── __init__.py
│   │   ├── shanten.py             # 向听数计算 (Python)
│   │   ├── hand_calculator.py     # 完整手牌估值 (集成 mahjong 库)
│   │   ├── ukeire.py              # 进张数计算
│   │   └── yaku_registry.py       # 役种注册表 (40种日麻役)
│   │
│   └── workers/
│       ├── puzzle_generator.py    # 离线题库生成 (Celery/Cloud Tasks)
│       └── srs_scheduler.py       # SRS 定期调度
│
├── tests/
│   ├── test_shanten.py
│   ├── test_hand_calculator.py
│   └── test_api.py
│
├── requirements.txt
├── Dockerfile
└── .env.example
```

### 3.3 题目预计算 Pipeline

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│ 题目模板库   │────▶│  Mahjong Engine  │────▶│  JSON 预计算结果  │
│ (1000+ 牌姿) │     │  批量计算         │     │  (每道题含:       │
│              │     │  · 14种打法的    │     │   14 种打法的     │
│              │     │    进张数/向听数  │     │   进张数/向听数)  │
└─────────────┘     └──────────────────┘     └────────┬────────┘
                                                       │
                                              ┌────────┴────────┐
                                              │   Firestore     │
                                              │   puzzles/{id}  │
                                              │   + CDN 缓存    │
                                              └─────────────────┘
```

**预计算覆盖**：
- MVP 题库: 500 道闪卡题 + 300 道何切题
- 每道何切题预计算 14 种打法的 `ukeire` (进张数) + `shanten` (向听数)
- 客户端查表延迟 <1ms

---

## 四、麻将算番引擎

### 4.1 引擎架构

```
┌──────────────────────────────────────────────┐
│           TileZhan Mahjong Engine             │
├──────────────────────────────────────────────┤
│                                               │
│  ┌─────────────────┐  ┌───────────────────┐  │
│  │  Shanten Calc   │  │   Ukeire Calc     │  │
│  │  (向听数计算)    │  │   (进张数计算)     │  │
│  │                 │  │                   │  │
│  │  · 标准 4面1雀  │  │  · 遍历34种牌      │  │
│  │  · 七对子专用   │  │  · 每种计算向听数   │  │
│  │  · 国士无双专用  │  │  · 取减少向听的牌   │  │
│  └────────┬────────┘  └────────┬──────────┘  │
│           └──────────┬──────────┘              │
│                      ▼                         │
│  ┌───────────────────────────────────────┐    │
│  │         Hand Calculator               │    │
│  │         (完整手牌估值)                  │    │
│  │                                       │    │
│  │  · 输入: 14张牌 (34维数组)             │    │
│  │  · 输出: { han, fu, yaku[], cost }    │    │
│  │  · 基于: mahjong-py (C++ binding)     │    │
│  └───────────────────────────────────────┘    │
│                                               │
└──────────────────────────────────────────────┘
```

### 4.2 Shanten Calculator (Dart 客户端)

```dart
/// 客户端向听数计算器
/// 算法: 回溯 + 剪枝
/// 时间复杂度: O(面子的组合数) ≈ O(3^n) with pruning
/// 实测性能: ~3-8ms (Release AOT)
class ShantenCalculator {
  // 34维数组: 0-8=万, 9-17=饼, 18-26=条, 27-33=字
  final List<int> tiles34;

  int calculate() {
    int best = 999;

    // 1. 检查特殊牌型 (七对子 / 国士无双)
    int chiitoi = _chiitoiShanten();   // 6 - 对子数
    int kokushi = _kokushiShanten();   // 13 - 幺九牌种数
    best = min(best, min(chiitoi, kokushi));

    // 2. 标准 4面子 + 1雀头
    best = min(best, _standardShanten(4, 1));

    return best;
  }

  int _standardShanten(int mentsu, int jantou) {
    // 剪枝: 如果已经不可能比 best 好, 提前返回
    // 回溯遍历所有面子分组方式
    // ...
  }
}
```

### 4.3 引擎部署策略

| 场景 | 计算位置 | 延迟 | 离线 |
|---|---|---|---|
| 95% 何切题 | 客户端查表 (预计算 JSON 打包) | <1ms | ✅ |
| 5% 自定义牌姿 | 客户端 ShantenCalc (Dart) | <8ms | ✅ |
| 完整算番 (付费) | 服务端 FastAPI + mahjong-py | <200ms | ❌ |
| 题库批量生成 | 服务端 Worker | 异步 | ❌ |

---

## 五、数据架构

### 5.1 Firestore 数据模型

```
Collection: users/{uid}
├── display_name:          string
├── email:                 string
├── created_at:            timestamp
├── settings: {
│     language:            "en" | "ja" | "fr" | "de"
│     sound_enabled:       bool
│     haptic_enabled:      bool
│     mnemonic_visible:    bool          // 助记标注开关
│     mnemonic_opacity:    float         // 0.0-1.0 渐进淡出
│   }
├── stats: {
│     total_cards_swiped:  int
│     total_nanikiru:      int
│     current_streak:      int
│     longest_streak:      int
│     elo_rating:          int           // 默认 1000
│   }
├── subscription_tier:    "free" | "premium"
├── subscription_expiry:   timestamp
│
├── Sub-collection: progress/{module_id}
│   ├── module:            "manzu_flashcards" | "nanikiru_beginner" | ...
│   ├── cards_completed:   [string]       // tile IDs
│   ├── cards_correct:     {tile_id: count}
│   ├── cards_errors:      {tile_id: count}
│   └── last_activity:     timestamp
│
├── Sub-collection: srs_items/{srs_item_id}
│   ├── tile_id:           string
│   ├── puzzle_type:       "flashcard" | "nanikiru"
│   ├── easiness_factor:   float          // SM-2 EF, 默认 2.5
│   ├── interval_days:     int
│   ├── repetitions:       int
│   ├── next_review:       timestamp
│   └── error_history:     [{timestamp, user_answer, correct_answer}]
│
Collection: puzzles/{puzzle_id}
├── type:                  "flashcard" | "nanikiru"
├── difficulty_rating:     int
├── content: {
│     tile_id:             string         // 闪卡题
│     hand_tiles:          [string]       // 何切题 (14个 tile ID)
│     drawn_tile:          string
│   }
├── precomputed: {                        // 何切题专用
│     discard_results: {
│       [tile_id]: {
│         shanten_after:   int
│         ukeire_types:    [string]
│         ukeire_count:    int
│         is_correct:      bool
│       }
│     }
│   }
├── mnemonic_ref:          string         // 关联的助记数据 ID
└── created_at:            timestamp
```

### 5.2 客户端本地存储 (Isar)

```dart
// Isar Schema
@collection
class LocalProgress {
  Id id = Isar.autoIncrement;
  late String moduleId;
  late List<String> completedTileIds;
  late Map<String, int> errorCounts;      // tileId → count
  late DateTime lastSynced;
}

@collection
class LocalSRSItem {
  Id id = Isar.autoIncrement;
  late String tileId;
  late String puzzleType;
  late double easinessFactor;
  late int intervalDays;
  late int repetitions;
  late DateTime nextReview;
  late bool pendingSync;
}

@collection
class CachedPuzzle {
  Id id = Isar.autoIncrement;
  late String puzzleId;
  late String type;
  late String contentJson;                // JSON string
  late String precomputedJson;
  late DateTime cachedAt;
  late DateTime expiresAt;
}
```

---

## 六、SRS 错题沉淀系统

### 6.1 SM-2 算法流程

```
用户答题
  │
  ▼
quality 评分 (0-5)
  ├─ 0: 完全忘记
  ├─ 1: 错误, 看到答案后想起来
  ├─ 2: 错误, 但答案熟悉
  ├─ 3: 正确, 但费力
  ├─ 4: 正确, 略有犹豫
  └─ 5: 完美, 本能反应
  │
  ├─ quality < 3 → 重置为 Day 1 (明天复习)
  │
  └─ quality ≥ 3 → 更新参数
       │
       ├─ EF = max(1.3, EF + (0.1 - (5-q)*(0.08+(5-q)*0.02)))
       ├─ reps += 1
       └─ interval:
            reps=1 → 1 day
            reps=2 → 6 days
            reps>2 → interval × EF
```

### 6.2 跨模块 SRS

```
闪卡模块答错 "四萬" → SRS 池: { tile: m4, type: flashcard, due: +1d }
     │
     ▼ (1天后)
首页 Daily Quest 混入: "复习: 四萬 (Square Canopy)"
     │
     ├─ 答对 → EF↑, interval × EF
     └─ 答错 → EF 不变, reps=0, interval=1

何切模块 Blunder "打五萬非四萬" → SRS 池: { type: nanikiru, trap: m5, correct: m4 }
     │
     ▼ (3天后)
首页 Daily Quest 混入: 同类型陷阱题的变体
```

### 6.3 每日推送逻辑

```python
def build_daily_quest(user_id: str, db: Firestore):
    """
    为用户组装今日任务:
      - 10 道新闪卡题 (从未见过的花色, 难度匹配 ELO)
      - 3 道何切题 (难度匹配 ELO)
      - N 道 SRS 到期复习题 (按 error_weight 排序)
    """
    # 1. 拉取 ELO rating
    elo = get_user_elo(user_id)

    # 2. 拉取到期 SRS 题目
    due_srs = db.collection(f"users/{user_id}/srs_items") \
        .where("next_review", "<=", datetime.utcnow()) \
        .order_by("easiness_factor") \
        .limit(10).get()

    # 3. 拉取新题 (排除已完成的 tile)
    completed = get_completed_tiles(user_id)
    new_flashcards = db.collection("puzzles") \
        .where("type", "==", "flashcard") \
        .where("tile_id", "not-in", completed) \
        .where("difficulty_rating", ">=", elo - 150) \
        .where("difficulty_rating", "<=", elo + 150) \
        .order_by("difficulty_rating") \
        .limit(10 - len(due_srs)).get()

    # 4. 组装
    return DailyQuest(
        flashcards=srs_cards_from(due_srs) + list(new_flashcards),
        nanikiru=select_nanikiru_for_elo(elo, 3),
        srs_review=due_srs
    )
```

---

## 七、安全架构

### 7.1 认证链路

```
┌──────────┐     Firebase     ┌──────────┐     Bearer Token    ┌──────────┐
│  Flutter │────▶ Auth ──────▶│  Client  │──────────────────▶│  FastAPI  │
│  Client  │     SDK          │  (Token) │    Authorization   │  Server   │
└──────────┘                  └──────────┘    Header           └─────┬─────┘
                                                                     │
                                                              ┌──────┴──────┐
                                                              │ Verify ID   │
                                                              │ Token via   │
                                                              │ Firebase    │
                                                              │ Admin SDK   │
                                                              └─────────────┘
```

### 7.2 安全措施清单

| 层级 | 措施 | 实现 |
|---|---|---|
| **传输** | HTTPS only (TLS 1.3) | Cloudflare + GCP |
| **认证** | Firebase Auth (Email/Apple/Google SSO) | Firebase Auth SDK |
| **API 鉴权** | Bearer Token → Firebase Admin SDK 验证 | FastAPI Dependency |
| **Firestore 安全** | Firestore Security Rules (UID 匹配) | `request.auth.uid == resource.data.uid` |
| **IAP 验证** | 服务端二次验证 RevenueCat Receipt | `/subscription/verify` |
| **Rate Limiting** | 每 UID 100 req/min (FastAPI 中间件) | slowapi |
| **输入验证** | Pydantic 模型 + 牌 ID 白名单 (34 张) | Pydantic validator |
| **敏感数据** | API Key / Service Account → GCP Secret Manager | 环境变量注入 |
| **时间防篡改** | NTP 对时 + 服务端时间戳权威 | `ntp_client` (Dart) + 服务端 `server_time` |
| **代码保护** | Flutter `--obfuscate` + AES 题库加密 | `dart:convert` + `encrypt` package |

### 7.3 Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 用户只能读写自己的数据
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    match /users/{uid}/progress/{module} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    match /users/{uid}/srs_items/{item} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    // 题库: 所有认证用户可读, 不可写
    match /puzzles/{puzzleId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

### 7.4 时间防篡改 (NTP Sync)

**威胁**: 用户通过修改手机本地时间绕过体力值恢复倒计时 (4h/❤️)。

**对策**:

```
┌──────────────────────────────────────────────────┐
│              体力恢复时间线                         │
├──────────────────────────────────────────────────┤
│                                                    │
│  客户端                        服务端               │
│  ┌──────────┐                ┌──────────┐         │
│  │ NTP 对时  │──────────────▶│ 记录     │         │
│  │ (启动时)  │   offset      │ server_time│        │
│  └──────────┘                └────┬─────┘         │
│                                   │                │
│  体力扣减时:                       │                │
│  POST /user/stamina/decrease      │                │
│  └─ 服务端记录 consumed_at        │                │
│  └─ 返回 next_recovery_at (UTC)   │                │
│                                    │                │
│  客户端展示倒计时:                  │                │
│  remaining = next_recovery_at      │                │
│            - (NTP.now())           │                │
│                                    │                │
│  若 remaining < 0:                 │                │
│  └─ 重新请求 GET /user/stamina    │                │
│     └─ 服务端独立计算恢复状态       │                │
│                                    │                │
└──────────────────────────────────────────────────┘
```

**Flutter 实现**:

```dart
// pubspec.yaml: ntp ^2.0
import 'package:ntp/ntp.dart';

class TimeService {
  static Duration? _ntpOffset;

  static Future<void> sync() async {
    final offset = await NTP.getNtpOffset(
      lookUpAddress: 'time.google.com',
    );
    _ntpOffset = offset;
  }

  static DateTime now() {
    return DateTime.now().add(_ntpOffset ?? Duration.zero);
  }

  /// NTP 失败时的缓存回退 — 严防用户切断网络改时间
  static Future<void> syncWithFallback() async {
    try {
      final offset = await NTP.getNtpOffset(
        lookUpAddress: 'time.google.com',
        timeout: const Duration(seconds: 3),
      );
      _ntpOffset = offset;
      // 持久化缓存 (下次启动可用)
      await _saveOffsetToLocal(offset);
    } catch (e) {
      // NTP 获取失败 → 使用上次缓存的偏移值
      _ntpOffset = await _loadCachedOffset();
      if (_ntpOffset == null) {
        // 首次启动 + 无网络 → 回退到 Firebase 服务端时间
        _ntpOffset = await _fetchServerTime();
      }
    }
  }
}
```

### 7.5 代码混淆与题库加密

**Flutter 构建混淆**:

```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=./build/debug-info
```

**本地题库 AES 加密**:

```dart
// 题库 JSON 不打进 Asset Bundle, 而是加密存储
// 首次启动时从服务端下载加密包, 本地 AES 解密后存入 Hive

import 'package:encrypt/encrypt.dart' as encrypt;

class PuzzleCrypto {
  static final _key = encrypt.Key.fromSecureRandom(32);
  static final _iv = encrypt.IV.fromSecureRandom(16);

  static String encryptJson(String plainJson) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    return encrypter.encrypt(plainJson, iv: _iv).base64;
  }

  static String decryptJson(String encryptedBase64) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    return encrypter.decrypt64(encryptedBase64, iv: _iv);
  }
}
```

> **注意**: MVP 阶段题库加密可选（暂无逆向风险）。V2 引入排行榜和竞技模式后必须开启。`_key` 应从 Firebase Remote Config 动态下发，不得硬编码。

### 8.1 部署拓扑

```
┌──────────────────────────────────────────────────────┐
│                    Cloudflare                          │
│  · DNS: tilezhan.app                                  │
│  · CDN: assets.tilezhan.app (静态资产)                 │
│  · DDoS Protection                                    │
│  · SSL Termination                                    │
└────────────────────┬─────────────────────────────────┘
                     │
     ┌───────────────┼───────────────┐
     ▼               ▼               ▼
┌─────────┐   ┌──────────┐   ┌──────────────┐
│Firebase │   │  GCP     │   │  Apple/Google │
│· Auth   │   │ Cloud Run│   │  App Store    │
│· Firestore│  │ (FastAPI)│   │  Connect      │
│· Storage│   │          │   │               │
│· Analytics│  │          │   │               │
└─────────┘   └──────────┘   └──────────────┘
```

### 8.2 CI/CD Pipeline

```
GitHub Repository
  │
  ├─ Pull Request
  │   └─ GitHub Actions:
  │       ├─ flutter analyze
  │       ├─ flutter test --coverage
  │       ├─ python -m pytest (backend)
  │       └─ Code review required
  │
  └─ Push to main
      └─ GitHub Actions:
          ├─ Build:
          │   ├─ Flutter: flutter build appbundle (Android)
          │   └─ Flutter: flutter build ipa (iOS)
          ├─ Backend:
          │   ├─ docker build + push → GCR
          │   └─ gcloud run deploy (Cloud Run)
          ├─ Deploy:
          │   ├─ Android: Fastlane → Play Store Internal Track
          │   └─ iOS: Fastlane → TestFlight
          └─ Hotfix:
              └─ Shorebird: patch push (Dart code, no review)
```

### 8.3 环境配置

| 环境 | 用途 | Firebase Project | API Base URL |
|---|---|---|---|
| `dev` | 本地开发 | tilezhan-dev | `http://localhost:8000` |
| `staging` | 内部测试 | tilezhan-staging | `https://staging-api.tilezhan.app` |
| `prod` | 生产 | tilezhan-prod | `https://api.tilezhan.app` |

### 8.4 成本估算

| 阶段 | MAU | 月成本 | 盈亏平衡 |
|---|---|---|---|
| MVP (0-3月) | ≤1万 | $60-110/月 | - |
| 增长 (3-6月) | 1-5万 | $200-500/月 | ~500 付费用户 → 盈亏 |
| 规模 (6-12月) | 5-10万+ | $700-1500/月 | 3000-5000 付费 → $15k-25k/月收入 |

---

## 九、可观测性

### 9.1 监控栈

| 层 | 工具 | 监控内容 |
|---|---|---|
| **客户端崩溃** | Firebase Crashlytics | 崩溃率 <0.1%, 按版本/OS 分组 |
| **客户端性能** | Firebase Performance | 启动时间, 屏幕渲染帧率, HTTP 延迟 |
| **API 监控** | GCP Cloud Monitoring | 请求量, 延迟 p50/p95/p99, 错误率 |
| **日志** | GCP Cloud Logging | API 日志, 异常追踪 |
| **用户行为** | Firebase Analytics + Amplitude | DAU/MAU, 留存, 漏斗转化, Paywall CVR |
| **错误追踪** | Sentry | 全栈错误聚合 (前端 + 后端) |

### 9.2 关键告警

| 告警 | 条件 | 严重级别 |
|---|---|---|
| API 错误率 >5% | 5分钟内 | P1 |
| Cloud Run 实例 OOM | 任何实例 | P1 |
| 崩溃率 >1% (新版本) | 发布后 1h 内 | P1 |
| Firestore 读写超过免费配额 | 每日检查 | P2 |
| 付费转化率下降 >20% | 周环比 | P2 |

### 9.3 关键埋点 (必须实现)

```
1. Onboarding Funnel:
   download → tutorial_start → tutorial_complete → first_card_swiped

2. Core Loop:
   daily_quest_start → flashcard_complete → nanikiru_complete → session_end

3. Monetization:
   paywall_impression → paywall_click → subscription_start → subscription_renew

4. Learning:
   card_correct / card_wrong / card_timeout (per tile)
   nanikiru_perfect / nanikiru_good / nanikiru_blunder
   srs_review_due / srs_review_completed

5. Retention:
   day1_retention, day7_retention, day30_retention
```

---

## 十、MVP 交付范围与 Sprint 拆解

### 10.1 Scope

| 包含 (IN) | 不包含 (OUT) |
|---|---|
| ✅ 34 张牌闪卡训练 (四选一 + 花色筛选) | ❌ AI 截图复盘 (OCR) |
| ✅ 何切实战 (预计算查表, 300 题) | ❌ 好友排行榜 / PVP |
| ✅ 牌浏览器 (34 张网格 + 助记) | ❌ 实时多人对战 |
| ✅ 番型图鉴 (8 种基础 Yaku) | ❌ 复杂役种计算器 |
| ✅ 错题本 (SM-2 SRS) | ❌ 语音识别 |
| ✅ 体力值 + 付费墙 (RevenueCat) | ❌ Web 版本 |
| ✅ 新手引导 (3-Step) | ❌ 国标/川麻规则 |
| ✅ Firebase Analytics 埋点 | ❌ FSRS 算法 |
| ✅ 英文 + 日文本地化 | |

### 10.2 Sprint 计划 (4 周)

```
Sprint 1 (Week 1): Foundation
├── Flutter 项目骨架搭建 (主题/路由/核心组件 TzTile)
├── 34 张牌数据 + SVG 资源导入
├── Firebase 项目初始化 (Auth + Firestore + Analytics)
├── FastAPI 项目骨架 + /puzzles/daily 端点
└── Shanten Calculator Dart 原型 + 单元测试

Sprint 2 (Week 2): Core Loop
├── 闪卡模块完整实现 (四选一 + 倒计时 + 助记翻转 + 花色筛选)
├── 何切模块完整实现 (14张牌选牌 + 预计算查表 + 反馈 Sheet)
├── 首页 Dashboard (每日任务 + 快速入口)
├── 牌浏览器 (34 张网格)
└── SRS SM-2 实现 (客户端 + 服务端同步)

Sprint 3 (Week 3): Monetization + Content
├── RevenueCat 集成 + 付费墙页面
├── 服务端 IAP 验证 Webhook
├── 体力值系统 + 爱心动画
├── 番型图鉴 (8 种 Yaku 详情)
├── 错题本 (弱项雷达图 + 一键复习)
└── 新手引导 (3-Step Onboarding)

Sprint 4 (Week 4): Polish + Ship
├── 火焰/粒子/Confetti 特效调优
├── 音效集成 + Haptic 触觉反馈
├── 日语本地化
├── Firebase Analytics 埋点补全
├── TestFlight / Play Store Internal Track 提审
├── TikTok 营销素材制作
└── Bug fix + 性能优化 (60fps 达标)
```

### 10.3 团队配置

| 角色 | 人数 | Sprint 1-2 | Sprint 3-4 |
|---|---|---|---|
| Flutter 开发 | 1 | 闪卡 + 何切 + 首页 | 付费墙 + 图鉴 + 动效 |
| Python 后端 | 1 | FastAPI + 引擎 + 题库生成 | IAP Webhook + SRS 调度 |
| UI/UX 设计 | 1 (外包) | 34 张助记插画绘制 | 微动效 + 营销素材 |

---

## 十一、自动化内容运营流水线 (V2)

> **阶段**: V2 (MVP 后引入)。MVP 阶段 500 闪卡 + 300 何切手工构建即可。

### 11.1 目标

将"何切题目"和"闪卡图鉴"的内容录入从人工 SQL 操作，转化为自动化流水线——降低运营成本，提高内容新鲜度。

### 11.2 Pipeline 设计

```
┌─────────────┐    ┌─────────────┐    ┌──────────────┐    ┌──────────┐
│ 数据采集     │───▶│ 清洗/转化   │───▶│ 人工复核      │───▶│ 入库发布  │
│             │    │             │    │              │    │          │
│ r/Mahjong   │    │ LLM 提取    │    │ 审核后台      │    │ PostgreSQL│
│ Discord     │    │ 14张手牌    │    │ (标注最优解)  │    │ → API    │
│ 天凤牌谱    │    │ 标注正确舍牌 │    │              │    │ → Daily  │
│ 雀魂回放    │    │ → JSON      │    │              │    │   Quest  │
└─────────────┘    └─────────────┘    └──────────────┘    └──────────┘
       ↑                ↑                                    │
  定时触发         LLM Prompt:                               │
  (Cron/          "Extract the 14-tile hand                 │
   Cloud Tasks)    and label the best discard"               │
```

### 11.3 各阶段技术方案

| 阶段 | 工具 | 说明 |
|---|---|---|
| **采集** | Python + PRAW (Reddit API) / Discord Bot | 抓取关键词: "which tile to discard", "shanten help", "yaku question" |
| **采集** | tenhou-python / mjlog-parser | 解析天凤牌谱 XML/JSON, 提取 14 张手牌快照 |
| **清洗** | OpenAI / Claude API | Prompt: 给定 14 张牌, 输出 `{tiles: [...], correct_discard: "m4", ukeire: {...}, difficulty: 3}` |
| **复核** | 内部 Web 后台 (Retool / 自建) | 人工抽查 LLM 输出, 修正误判, 打难度标签 |
| **入库** | FastAPI `/admin/puzzles/batch` | 批量写入 Firestore `puzzles` 集合, 自动触发 CDN 缓存预热 |

### 11.4 LLM Prompt 模板

```
You are a Riichi Mahjong expert.
Given the following 14 tiles in a closed hand, determine the
single best tile to discard for maximum tile acceptance (ukeire).

Hand: 1m 1m 2m 3m 3m 4m 5m 5m 6m 7m 8m 8m 9m 7s
(Last tile 7s was just drawn.)

Output JSON:
{
  "tiles_34": [...],
  "correct_discard": "m4",
  "shanten_before": 2,
  "shanten_after": 1,
  "ukeire_types": ["2p", "5p", "8p"],
  "ukeire_count": 11,
  "trap_options": ["m5"],
  "difficulty": 2,
  "explanation": "Discarding 4m preserves the 567m run and
                  opens a two-sided wait for 2p/5p/8p."
}
```

### 11.5 节奏

| 阶段 | 时间 | 产出 |
|---|---|---|
| MVP | Week 1-4 | 500 闪卡 + 300 何切 (手工) |
| V2 试验 | Month 3 | 爬虫 + LLM Pipeline 原型, 周产 50 题 |
| V2 稳定 | Month 4+ | 全自动, 周产 100+ 题, 人工复核率 <20% |

---

> 📐 本文档为 TileZhan 项目的 CTO 级架构设计。所有技术选型、模块划分、Sprint 计划均以此为准。
> 修订记录: v1.1 (2026-06-06) — 新增 §7.4 NTP 防篡改, §7.5 代码混淆, §十一 内容流水线。
