# TileZhan (麻雀斩) — PRD 深化 & 技术架构评审

> 撰写日期：2026-06-06
> 状态：MVP 前技术评审阶段

---

## 目录

- [Part B: PRD 深化](#part-b-prd-深化)
  - [B1. 何切模块难度梯度系统 (ELO-based)](#b1-何切模块难度梯度系统-elo-based)
  - [B2. 用户验证与 A/B 测试计划](#b2-用户验证与-ab-测试计划)
  - [B3. 规则体系选择：日麻 vs 国标](#b3-规则体系选择日麻-vs-国标)
  - [B4. 内容生产管线](#b4-内容生产管线)
  - [B5. 本地化与多语言策略](#b5-本地化与多语言策略)
- [Part D: 技术架构评审](#part-d-技术架构评审)
  - [D1. 客户端框架深度对比](#d1-客户端框架深度对比)
  - [D2. 向听数/算番引擎算法分析](#d2-向听数算番引擎算法分析)
  - [D3. 后端架构设计](#d3-后端架构设计)
  - [D4. 离线优先架构](#d4-离线优先架构)
  - [D5. SRS 间隔重复算法选型](#d5-srs-间隔重复算法选型)
  - [D6. 动画与动效引擎](#d6-动画与动效引擎)
  - [D7. 支付与订阅架构](#d7-支付与订阅架构)
  - [D8. 基础设施成本估算](#d8-基础设施成本估算)
  - [D9. CI/CD 与发布管线](#d9-cicd-与发布管线)
- [总结：推荐技术栈与排期修正](#总结推荐技术栈与排期修正)

---

## Part B: PRD 深化

### B1. 何切模块难度梯度系统 (ELO-based)

#### 1.1 问题定义

原始 PRD 中，"何切实战模拟"只定义了三级反馈（Perfect/Good/Blunder），但缺少**题目难度分级的量化模型**。如果题目难度随机分布，会出现：
- 新手遭遇高难牌姿 → 挫败感 → 流失
- 进阶用户反复刷到简单题 → 无聊 → 流失

#### 1.2 解决方案：双 ELO 评分系统

借鉴 Chess.com 的 Puzzle ELO 机制，为每道何切题赋予一个独立的 **Puzzle Rating**，为用户赋予 **Player Rating**。

```
Player Rating (μ_player)  ←→  Puzzle Rating (μ_puzzle)
       ↓                            ↓
   初始 1000                    由难度因子计算
   K=32 (新手期)                输赢后 ELO 更新
   K=16 (稳定期)
```

#### 1.3 题目难度因子 (Puzzle Difficulty Factors)

每道何切题的 Puzzle Rating 由以下 6 个维度加权计算：

| 维度 | 权重 | 说明 | 示例 |
|---|---|---|---|
| **向听数 (Shanten)** | 0.25 | 当前手牌的向听数 | 1向听=简单，2向听=中等，3+向听=困难 |
| **有效舍牌数** | 0.20 | 候选舍牌中"正确解"的占比 | 14张中只有1张正确=极难 |
| **进张面复杂度** | 0.20 | 正确舍牌后的进张种数与枚数 | 2种8张=简单，5种16张且需识别=困难 |
| **陷阱吸引力** | 0.15 | 是否存在表面合理但实际牌效低的陷阱选项 | 有陷阱=难度+150 |
| **役种识别需求** | 0.10 | 是否需要识别特定 Yaku 才能做出正确判断 | 需要判断"断幺九"可行性=+100 |
| **时间压力系数** | 0.10 | 是否在限时模式下作答 | 5秒限时 → 等效难度+50 |

**Puzzle Rating 初始计算公式**：

```
Puzzle_Rating = 800 + Σ(维度_score × 权重 × 400)
```

其中每个维度标准化到 [0, 1] 区间。

#### 1.4 渐进式难度曲线

```
Week 1 (Tutorial Phase):
  仅投放 Shanten ≤ 1 且有效舍牌数 ≥ 3 的题目
  Puzzle Rating 区间: 800-1100

Week 2-3 (Skill Building):
  引入 Shanten = 2 的题目
  开始出现陷阱选项
  Puzzle Rating 区间: 1000-1400

Week 4+ (Mastery Phase):
  全难度开放
  引入多面张复合判断
  Puzzle Rating 区间: 1200-1800
```

#### 1.5 动态难度调节 (DDA)

每次刷题 Session 的题目选择算法：

```python
def select_puzzle(player_rating, session_history):
    """
    从题库中选择 3 道题：1道 巩固题 + 1道 挑战题 + 1道 复习题
    """
    # 巩固题：rating 略低于玩家，确保成功率 > 70%
    consolidate = puzzles.filter(
        rating__range=(player_rating - 150, player_rating - 50)
    ).exclude(id__in=session_history).order_by('?').first()

    # 挑战题：rating 略高于玩家，目标成功率 40-60%
    challenge = puzzles.filter(
        rating__range=(player_rating + 50, player_rating + 150)
    ).exclude(id__in=session_history).order_by('?').first()

    # 复习题：从 SRS 错题池中按遗忘曲线权重抽取
    review = srs_pool.filter(
        user=user, due__lte=now()
    ).order_by('-error_weight').first()

    return [consolidate, challenge, review]
```

#### 1.6 数据埋点补充

在原 PRD 的 4 项 Key Telemetry 基础上增加：

5. **ELO 收敛速度**：新用户从 1000 分到达"稳定区间"（连续 20 局胜率在 45-55% 之间）所需局数。目标 ≤ 15 局。
6. **陷阱辨识率**：含陷阱的题目中，用户选择陷阱选项的比例（按 Player Rating 分桶统计）。

---

### B2. 用户验证与 A/B 测试计划

#### 2.1 助记插画的认知有效性验证

34 张 Meme 化助记插画是产品的核心护城河，在投入全套美术资源前，必须验证假设：**"欧美用户看到插画后，认牌准确率和速度显著提升。"**

**验证方案：Remote Unmoderated Usability Test**

| 参数 | 设定 |
|---|---|
| **平台** | UserTesting.com 或 UsabilityHub |
| **样本量** | n ≥ 60（欧美英语母语者，零麻将经验） |
| **对照组** | 纯汉字牌面（无插画、无提示） |
| **实验组A** | 汉字 + 边缘微标注（如 `5m`） |
| **实验组B** | 汉字 + 完整 Meme 插画 + Slogan |
| **核心指标** | ① 单卡识别正确率 ② 平均识别耗时(ms) ③ 24h 后记忆保持率 |

**判定标准**：
- 实验组 B vs 对照组：正确率 ≥ +25%，识别耗时 ≤ -40% → 插画方案有效
- 实验组 B vs 实验组 A：正确率 ≥ +15% → Meme 插画增量价值高于纯标注

#### 2.2 关键假设的 A/B 测试矩阵

| # | 假设 | 对照组 | 实验组 | 关键指标 | 最小样本量/组 |
|---|---|---|---|---|---|
| H1 | "一刀斩"碎裂特效提升次日留存 | 无特效（牌直接消失） | 有斩击+粒子特效 | Day 1 → Day 2 留存率 | n=500 |
| H2 | 1.5 秒限时提升长期记忆强度 | 不限时 | 1.5 秒倒计时 | 7 日记忆保持率 | n=300 |
| H3 | 体力值=3 是付费墙最优触发点 | 体力值=5 | 体力值=3 | Paywall CVR | n=1000 |
| H4 | 助记层默认开启提升新手完成率 | 默认关闭 | 默认开启（关卡>5后自动淡出） | 新手教程完成率 | n=400 |
| H5 | $4.99 vs $6.99 vs $9.99 定价 | $4.99/月 | $6.99/月 + $9.99/月 | ARPU | n=1500/组 |

**A/B 测试工具建议**：
- Firebase Remote Config（功能开关）
- Firebase A/B Testing（与 Remote Config 原生集成，自动计算置信区间）
- Amplitude Experiment（更高级的多臂老虎机自动调优）

#### 2.3 定性验证：Reddit 社区前置调研

在正式开发前，先以"独立开发者"身份在 r/Mahjong 发布**低保真原型图**（Figma 导出的静态截图，3-5 张核心页面），收集：

1. 社区对"Meme 插画风格"的接受度（Upvote 数和评论情感分析）
2. 最受欢迎/最反感的单张插画
3. 社区自发提出的补充建议

这比闭门造车后再推倒重来成本低两个数量级。

---

### B3. 规则体系选择：日麻 vs 国标

#### 3.1 对比矩阵

| 维度 | 日麻 (Riichi Mahjong) | 国标麻将 (Guobiao/MCR) | 推荐 |
|---|---|---|---|
| **全球玩家基数** | ~1000 万+（日本 760 万 + 全球在线玩家） | ~200 万（主要集中在华人圈） | 🟢 日麻 |
| **规则标准化** | 高度统一（日本麻雀联盟/天凤/雀魂规则基本一致） | 存在多个变体（MCR/川麻/广麻） | 🟢 日麻 |
| **英语学习资源** | 极其丰富（Riichi Wiki, Mahjong Soul EN, 大量 YouTube 教程） | 稀缺且碎片化 | 🟢 日麻 |
| **App Store 生态** | 已有 Mahjong Soul（雀魂）在头部，但纯"教学工具"品类空白 | 几乎无竞品 | 🟢 日麻 |
| **Yaku 数量** | ~40 种（含地方役），新手核心 8-10 种即可上手 | 81 个番种，记忆负担重 | 🟢 日麻 |
| **算番复杂度** | 番 + 符双轨制（有学习门槛，但也是"教学工具"的价值点） | 纯番数累加制（简单但单项数值大） | ⚖️ 持平 |
| **TikTok 热度** | Riichi Mahjong 相关视频月均播放 ~5000 万次 | Guobiao 几乎无英文内容 | 🟢 日麻 |

#### 3.2 最终建议

**MVP 阶段：仅支持日麻（Riichi Mahjong）**

理由：
1. **市场规模碾压**：日麻在海外的认知度是国标的 5-10 倍
2. **竞品空白**：雀魂（Mahjong Soul）是对战游戏，没有人在做"日麻教学工具"这个细分品类
3. **规则确定性**：日麻规则高度标准化，不会陷入"哪种国标变体才正宗"的内耗

**V2 扩展路径**：
- Phase 2：增加川麻（Sichuan Bloody Rules）—— 因为"换三张"和"血战到底"在 TikTok 上传播力极强
- Phase 3：增加 MCR（国标竞赛规则）—— 面向已经在打国标的海外华人群体

---

### B4. 内容生产管线

#### 4.1 34 张 Meme 助记插画的标准化生产流程

```
需求文档 (已完成)
  ↓
风格指引 (Style Guide) — 1 天
  ├─ 色彩规范：翡翠深绿底 + 琉璃红 + 霓虹金
  ├─ 角色风格：扁平化矢量 + 1px 描边 + 柔和阴影
  ├─ 一致性要求：所有插画使用统一的线宽、圆角、渐变规则
  ↓
分镜草稿 (Storyboard) — 2 天
  ├─ 每张牌的构图草稿 (Thumbnail Sketch)
  ├─ 内部评审 → 筛掉不成立的联想
  ↓
线稿绘制 (Line Art) — 5 天
  ├─ 外包画师并行产出 34 张线稿
  ├─ 产品侧逐张验收（构图/文化适配/清晰度）
  ↓
上色 + 动效分层 — 5 天
  ├─ 按色彩规范统一上色
  ├─ 将插画拆分为"静态层"和"动效层"（如火山喷发的岩浆需要独立图层）
  ↓
Lottie/Rive 动画制作 — 5 天
  ├─ 为 34 张牌制作微动效（2-3 秒循环动画）
  ├─ 最高优先级：一条（鸟眨眼睛）、七筒（北斗七星连线）、五万（隐藏数字5高亮）
  ↓
集成测试 — 2 天
  └─ 在真机上验证 60fps 性能
```

**总计**：约 20 个工作日（1 名全职 UI + 1 名外包画师）

#### 4.2 资产规格

| 资产类型 | 规格 | 格式 | 用途 |
|---|---|---|---|
| 静态插画 | 512×768 px @2x, @3x | PNG (无损) / WebP | 闪卡核心展示 |
| 动效文件 | 原始尺寸 | .riv (Rive) 或 .json (Lottie) | 正确/错误反馈动效 |
| 缩略图 | 128×192 px | WebP | 列表/图鉴加载态占位 |
| 牌面 SVG | 矢量 | SVG | 何切模块手牌渲染 |

---

### B5. 本地化与多语言策略

#### 5.1 MVP 语言覆盖

| 优先级 | 语言 | 理由 |
|---|---|---|
| P0 | English (US) | 核心目标市场 |
| P1 | English (UK) | 英国麻将协会活跃 |
| P1 | 日本語 | 日麻发源地，对"教学工具"需求巨大 |
| P2 | Français | 法国麻将联盟（FFMJ）有 3000+ 会员 |
| P2 | Deutsch | 德国麻将协会（DMV）活跃 |
| P3 | Español | 拉美市场增长 |

#### 5.2 本地化特别注意事项

- **Slogan 不可直译**：英文 Slogan 依赖谐音梗（如 "Wand" = 万），日语/法语版需要重新创作等效的记忆锚点
- **数字格式**：欧洲使用 `10.000` 而非 `10,000`
- **颜色文化差异**：红色在中国=喜庆，在部分西方语境=危险/停止。教学卡片的色彩编码需做区域性 Review

---

## Part D: 技术架构评审

### D1. 客户端框架深度对比

#### 1.1 Flutter vs React Native vs 原生

| 维度 | Flutter | React Native | 原生 (Swift/Kotlin) |
|---|---|---|---|
| **卡片滑动性能** | 🟢 Impeller 引擎，自绘 UI，60fps 稳定 | 🟡 JS Bridge 可能掉帧 | 🟢 原生手势最优 |
| **复杂动画 (碎裂/粒子)** | 🟢 内置 Animation API + Flame 游戏引擎 | 🟡 需依赖 Reanimated + Skia | 🟢 最佳 |
| **跨平台一致性** | 🟢 像素级一致 | 🟡 需处理平台差异 | 🔴 需两套代码 |
| **离线存储** | 🟢 Hive/Isar/Drift | 🟢 WatermelonDB/MMKV | 🟢 CoreData/Room |
| **海外 Firebase 集成** | 🟢 官方 FlutterFire 插件 | 🟢 React Native Firebase | 🟢 原生 SDK |
| **热更新能力** | 🟡 Shorebird (第三方) | 🟢 CodePush/Expo Updates | 🔴 需审核 |
| **团队效率** | 🟢 一套代码，快速迭代 MVP | 🟢 一套代码 | 🔴 人力成本 ×2 |
| **包体积** | ⚠️ 基础 ~15MB (Android) | 🟢 基础 ~7MB | 🟢 最小 |

#### 1.2 最终建议：Flutter ✅

**决定性因素**：
1. **Flame Engine** — 原生 PRD 中提到的"斩击碎裂"特效、"牌面翻转"动效，用 Flame 的 `SpriteAnimationComponent` 和 `ParticleSystem` 可以做到 60fps，而 React Native 需要额外集成 Skia 桥接层
2. **Impeller** — Flutter 3.22+ 默认使用 Impeller 渲染引擎，在 iOS 上的动画性能已接近原生
3. **Shorebird** — 虽然不是官方，但已经足够成熟，可以支持无需 App Store 审核的快速热修复

**Flutter 版本建议**：≥ 3.24（稳定 Impeller + WASM 支持）

#### 1.3 Flutter 项目架构建议

```
lib/
├── app.dart                    # MaterialApp + 路由配置
├── core/
│   ├── constants/              # 颜色/字体/API 端点常量
│   ├── theme/                  # 赛博国风主题定义
│   ├── storage/                # Hive/Isar 本地存储封装
│   ├── network/                # Dio HTTP 客户端 + 拦截器
│   └── utils/                  # 工具函数
├── features/
│   ├── onboarding/             # 新手教程
│   ├── flashcard/              # 图形闪卡训练
│   │   ├── presentation/       # UI 组件 (Bloc/Provider)
│   │   ├── domain/             # 业务逻辑
│   │   └── data/               # 数据层 (Repository)
│   ├── nanikiru/               # 何切实战模拟
│   │   ├── presentation/
│   │   ├── domain/
│   │   │   └── shanten_calc/   # 向听数计算器 (Dart 实现)
│   │   └── data/
│   ├── srs/                    # SRS 错题沉淀
│   ├── collection/             # 番型收集图鉴
│   ├── premium/                # 付费墙 + IAP
│   └── profile/                # 用户设置
├── shared/
│   ├── widgets/                # 复用组件
│   └── models/                 # 共享数据模型
└── l10n/                       # 多语言资源
```

---

### D2. 向听数/算番引擎算法分析

#### 2.1 算法复杂度

向听数（Shanten）计算的本质是：在给定 13/14 张手牌中，找到离"听牌"还差几张牌。

- **暴力枚举**：C(14, 组合方式) → 指数级，不可接受
- **标准算法**：递归回溯 + 剪枝，时间复杂度约 O(n²)，其中 n=手牌数

#### 2.2 客户端侧 vs 服务端侧

| 方案 | 优势 | 劣势 | 延迟 |
|---|---|---|---|
| **纯客户端 (Dart)** | 离线可用，零网络延迟 | Dart 不是高性能语言，复杂牌姿可能耗时 | <5ms (简单) / ~50ms (复杂) |
| **纯服务端 (Python/C++)** | 可利用 C++ 扩展库 | 依赖网络，无法离线使用 | 50-200ms (RTT) |
| **WASM (Rust → Flutter)** | 离线 + 接近原生性能 | 需要 WASM 编译链，包体积 +2-3MB | <1ms |
| **预计算 + 客户端查表** | 零计算延迟，离线 | 无法覆盖所有牌姿组合 | <1ms |

#### 2.3 推荐方案：混合策略

```
┌──────────────────────────────────────────────────┐
│                 TileZhan 算番架构                  │
├──────────────────────────────────────────────────┤
│                                                    │
│  ┌──────────┐     ┌─────────────────┐            │
│  │ 题目生成器 │────▶│ JSON 预计算结果  │──────────┐ │
│  │ (Python)  │     │ (14张 → 14种打法的│          │ │
│  │ 服务端运行 │     │  进张数 + Shanten) │          │ │
│  └──────────┘     └─────────────────┘          │ │
│                                                    ▼ │
│  ┌──────────────────────────────────────────────┐ │
│  │            Flutter 客户端                     │ │
│  │  ┌─────────────┐  ┌──────────────────────┐   │ │
│  │  │ 离线题库缓存  │  │ Shanten 实时计算器     │   │ │
│  │  │ (Hive 存储)  │  │ (Dart 实现，用于       │   │ │
│  │  │ 覆盖 99% 场景 │  │  用户自定义牌姿输入)    │   │ │
│  │  └─────────────┘  └──────────────────────┘   │ │
│  └──────────────────────────────────────────────┘ │
│                                                    │
└──────────────────────────────────────────────────┘
```

**核心逻辑**：
- **95% 的何切题**：服务端预计算 JSON → 客户端直接查表，延迟 <1ms
- **5% 的用户自定义牌姿**：客户端 Dart 实现的 Shanten Calculator（降级方案，允许 <100ms）
- **算番确认（付费功能）**：调用服务端完整 Mahjong Engine，返回结构化的 Yaku 分解

#### 2.4 Shanten Calculator Dart 实现要点

```dart
/// 向听数计算器 - 基于 Syanten 算法
/// 
/// 策略：将手牌分为"面子组"（顺子/刻子/对子）和"孤立牌"
/// 递归搜索所有分组方式，取最小向听数
class ShantenCalculator {
  // 手牌表示：34维数组，索引 0-8=万, 9-17=饼, 18-26=条, 27-33=字
  final List<int> tiles34;
  
  // 计算标准向听数 (13张手牌, 4面子+1雀头)
  int calculate() {
    // 第一步：检查七对子 和 国士无双 的特殊向听
    final chiitoiShanten = _chiitoiShanten();
    final kokushiShanten = _kokushiShanten();
    
    // 第二步：标准 4面子+1雀头 向听
    int standardShanten = _standardShanten(4, 1);
    
    return [standardShanten, chiitoiShanten, kokushiShanten]
        .reduce(min);
  }
  
  // 核心递归
  int _standardShanten(int remainingMentsu, int remainingJantou) {
    // 剪枝：如果已经不可能比当前最优解更好，提前返回
    // ... 
  }
}
```

**性能基准**（预期）：
- Dart VM (Debug)：平均 15-30ms
- Dart AOT (Release)：平均 3-8ms
- 复杂牌姿（如国士无双 13 面听）：<50ms

#### 2.5 备选方案：Rust → WASM

如果 Dart 实现在低端机上性能不足（>100ms），可以通过 `flutter_rust_bridge` 调用 Rust 编译的 WASM 模块：

```rust
// 使用 mahjong-rs crate (假设已存在或自行实现)
use mahjong_core::shanten::calculate_shanten;

#[wasm_bindgen]
pub fn evaluate_shanten(tiles: &[u8; 34]) -> i32 {
    calculate_shanten(tiles)
}
```

**切换成本**：约 3-5 人天（配置 WASM 编译链 + Flutter 集成 + 测试）
**建议**：先用纯 Dart 实现，性能瓶颈出现后再切换。过早优化是万恶之源。

---

### D3. 后端架构设计

#### 3.1 推荐技术栈

```
┌─────────────────────────────────────────────────┐
│                   CDN (Cloudflare)                │
│         静态资产：插画 / 动效 / 牌面 SVG           │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│            API Gateway (FastAPI)                  │
│  ┌──────────┐ ┌───────────┐ ┌────────────────┐  │
│  │ Auth     │ │ Puzzle    │ │ Mahjong Engine │  │
│  │ (Firebase│ │ Service   │ │ (Python/Rust)  │  │
│  │  Auth)   │ │           │ │                │  │
│  └──────────┘ └───────────┘ └────────────────┘  │
│  ┌──────────┐ ┌───────────┐ ┌────────────────┐  │
│  │ User     │ │ SRS       │ │ Analytics      │  │
│  │ Profile  │ │ Scheduler │ │ Proxy          │  │
│  └──────────┘ └───────────┘ └────────────────┘  │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│              Firebase / GCP                       │
│  ┌──────────┐ ┌──────────┐ ┌─────────────────┐  │
│  │ Firestore│ │ Auth     │ │ Cloud Functions │  │
│  │ (用户数据)│ │          │ │ (SRS 定期调度)   │  │
│  └──────────┘ └──────────┘ └─────────────────┘  │
│  ┌──────────┐ ┌──────────┐ ┌─────────────────┐  │
│  │ Cloud    │ │ Crashlytics│ │ Analytics      │  │
│  │ Storage  │ │          │ │                 │  │
│  └──────────┘ └──────────┘ └─────────────────┘  │
└─────────────────────────────────────────────────┘
```

#### 3.2 为什么 FastAPI 而不是纯 Firebase (Firestore Functions)?

| 需求 | Firebase Functions | FastAPI | 选择 |
|---|---|---|---|
| 简单 CRUD (用户资料/进度) | ✅ 直接读写 Firestore | 🔸 多一层 | Firebase |
| 麻将算番引擎 | ❌ 无法集成 C/Python 库 | ✅ 可集成 mahjong 库 | FastAPI |
| 题库生成与预计算 | ❌ 内存/时间限制 (60s) | ✅ 无限制 | FastAPI |
| WebSocket 实时通信 | ❌ 不支持 | ✅ 原生支持 | - (MVP 不需要) |
| 部署复杂度 | ✅ 一键部署 | 🔸 需管理容器 | - |

**结论**：FastAPI 作为"重型计算层"，Firebase 作为"轻量数据层"，各司其职。

#### 3.3 API 端点设计 (MVP)

```yaml
# 用户与进度
GET    /api/v1/user/profile
PATCH  /api/v1/user/settings
GET    /api/v1/user/progress          # 各模块通关进度

# 题库服务
GET    /api/v1/puzzles/daily          # 获取今日卡包 (含预计算结果)
GET    /api/v1/puzzles/flashcards     # 获取闪卡题目
GET    /api/v1/puzzles/nanikiru       # 获取何切题目
POST   /api/v1/puzzles/evaluate       # 提交答案 + 获取反馈

# 算番引擎 (付费功能)
POST   /api/v1/mahjong/calculate      # 完整算番 (传入完整手牌)
POST   /api/v1/mahjong/shanten        # 向听数计算
POST   /api/v1/mahjong/ukeire         # 进张数计算 (打某张牌后的进张)

# SRS 系统
GET    /api/v1/srs/review_due         # 获取待复习的错题
POST   /api/v1/srs/report             # 上报答题结果 (更新 SRS 权重)

# 订阅验证
POST   /api/v1/subscription/verify    # 验证 Receipt (服务端二次验证)
GET    /api/v1/subscription/status    # 查询订阅状态
```

#### 3.4 数据库设计 (Firestore)

```
Collection: users/{uid}
  - display_name: string
  - email: string
  - created_at: timestamp
  - settings: map { language, sound_enabled, haptic_enabled, mnemonic_layer_visible }
  - stats: map { total_cards_swiped, total_nanikiru_solved, current_streak_days }
  - elo_rating: number (default: 1000)
  - subscription_tier: "free" | "premium"
  - subscription_expiry: timestamp

Collection: users/{uid}/progress/{module_id}
  - module: "flashcard" | "nanikiru" | "collection"
  - cards_completed: number[]
  - cards_errors: map { tile_id: error_count }
  - last_activity: timestamp

Collection: users/{uid}/srs_items/{srs_item_id}
  - tile_id: string
  - puzzle_type: "flashcard" | "nanikiru"
  - easiness_factor: number (SM-2 EF, default: 2.5)
  - interval_days: number
  - repetitions: number
  - next_review: timestamp
  - error_history: array[{ timestamp, user_answer, correct_answer }]

Collection: puzzles/{puzzle_id}
  - type: "flashcard" | "nanikiru"
  - difficulty_rating: number
  - content: map (牌面数据)
  - precomputed_result: map (预计算结果)
  - mnemonic_data: map (助记插画 URL, Slogan)
```

---

### D4. 离线优先架构

#### 4.1 离线策略分层

```
Layer 1: 静态资产 (CDN + 本地缓存)
  ├─ 34 张 Meme 插画 → CachedNetworkImage (flutter_cached_network_image)
  ├─ 牌面 SVG → 打包进 Asset Bundle
  └─ Lottie/Rive 动效 → 打包进 Asset Bundle (体积小)

Layer 2: 题库数据 (本地预加载)
  ├─ 每日卡包 → 凌晨 2 点 Background Fetch 下载到 Hive
  ├─ 预计算结果 → 与卡包绑定，一次下载
  └─ 缓存过期策略 → 24h TTL，下次联网时静默刷新

Layer 3: 用户数据 (双向同步)
  ├─ 进度数据 → 本地 Isar DB ↔ Firestore (Firestore Offline Persistence)
  ├─ SRS 状态 → 本地优先计算，联网时同步到服务端
  └─ 冲突解决 → Last-Write-Wins (进度数据无强一致性需求)

Layer 4: 离线降级
  ├─ 无网状态 → 使用本地缓存题库，进度暂存本地
  ├─ 恢复网络 → WorkManager 触发后台同步
  └─ 同步状态 UI → 底部轻量 Banner "Syncing your progress..."
```

#### 4.2 本地存储技术选型

| 库 | 类型 | 适用场景 |
|---|---|---|
| **Hive** | 轻量 KV 存储 | 题库缓存、设置项 |
| **Isar** | 嵌入式 NoSQL | 用户进度、SRS 状态（需索引查询） |
| **Drift (Moor)** | SQLite 封装 | 如需要复杂关联查询（当前 MVP 不需要） |

**推荐**：Hive 存缓存 + Isar 存结构化数据。Isar 支持 `IsarLink` 做对象关联，对 SRS 数据模型友好。

#### 4.3 同步协议

```dart
/// 离线同步管理器
class SyncManager {
  /// 将本地离线操作队列同步到 Firestore
  Future<void> syncPendingOperations() async {
    final pendingOps = await localDB.getPendingOperations();
    
    for (final op in pendingOps) {
      try {
        await firestore.applyOperation(op);
        await localDB.markAsSynced(op.id);
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          // 权限错误 → 标记失败，通知用户
          await localDB.markAsFailed(op.id);
        }
        // 网络错误 → 保留在队列，下次重试
      }
    }
  }
  
  /// 拉取最新的远程题库
  Future<void> fetchLatestPuzzles() async {
    final lastFetchTime = await localDB.getLastPuzzleFetchTime();
    final newPuzzles = await api.getPuzzlesSince(lastFetchTime);
    await localDB.upsertPuzzles(newPuzzles);
  }
}
```

---

### D5. SRS 间隔重复算法选型

#### 5.1 SM-2 vs FSRS vs 简化版

| 维度 | SM-2 (SuperMemo) | FSRS (Free Spaced Repetition Scheduler) | 简化艾宾浩斯 |
|---|---|---|---|
| **算法复杂度** | 中等（EF 因子 + 间隔公式） | 高（17 个参数，DNN 训练） | 低（固定间隔） |
| **实现成本** | 1-2 天 | 3-5 天 + 需训练数据 | 半天 |
| **记忆效率** | 🟢 良好 | 🟢 最优（Anki 新默认算法） | 🟡 一般 |
| **冷启动** | ✅ 无需训练数据 | ❌ 需要种子数据或预训练模型 | ✅ 无需数据 |
| **个性化** | 🟡 每个卡片独立 EF | 🟢 根据用户历史全局优化 | 🔴 无个性化 |
| **移动端性能** | 🟢 轻量 | 🟡 需定期在客户端跑参数更新 | 🟢 轻量 |

#### 5.2 推荐：SM-2 (MVP) → FSRS (V2)

```
MVP (Week 1-4):  SM-2 算法
  - 实现简单，业界验证 30+ 年
  - 参数少，不需要训练数据
  - Anki 用户基数已验证有效性

V2 (Month 3+):  迁移到 FSRS
  - 积累 ≥ 1万条用户记忆数据后
  - 训练个性化参数
  - 预期记忆保持率提升 10-15%
```

#### 5.3 SM-2 Dart 实现

```dart
class SM2Algorithm {
  /// 处理一次复习结果
  /// 
  /// [quality] 0-5 评分:
  ///   0: 完全忘记
  ///   1: 错误，但看到答案后想起来
  ///   2: 错误，但答案看起来很熟悉
  ///   3: 正确，但很费力
  ///   4: 正确，略有犹豫
  ///   5: 完美，本能反应
  static SRSUpdateResult update({
    required double easinessFactor,  // 初始 2.5
    required int repetitions,        // 初始 0
    required int intervalDays,       // 初始 1
    required int quality,
  }) {
    if (quality < 3) {
      // 答错 → 重置为初始状态
      return SRSUpdateResult(
        easinessFactor: easinessFactor, // EF 不变
        repetitions: 0,
        intervalDays: 1,
      );
    }
    
    // 答对 → 更新参数
    final newEF = max(1.3, 
      easinessFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    );
    
    final newRepetitions = repetitions + 1;
    
    int newInterval;
    if (newRepetitions == 1) {
      newInterval = 1;
    } else if (newRepetitions == 2) {
      newInterval = 6;
    } else {
      newInterval = (intervalDays * newEF).round();
    }
    
    return SRSUpdateResult(
      easinessFactor: newEF,
      repetitions: newRepetitions,
      intervalDays: newInterval,
    );
  }
}
```

#### 5.4 与何切模块的联动

SRS 不只用于闪卡模块，也用于何切：
- 用户在何切中犯了"弃和判断错误" → 自动生成一道针对该 Yaku 的闪卡复习题
- 下周的同一天，系统自动推送该 Yaku 的变体题目
- **跨模块 SRS** 是 TileZhan 区别于 Duolingo/Anki 的核心差异化能力

---

### D6. 动画与动效引擎

#### 6.1 三大引擎对比

| 场景 | Rive | Lottie | Flame (游戏引擎) | 原生 Animation |
|---|---|---|---|---|
| **闪卡翻转** | ✅ 完美 | ✅ 完美 | ✅ 完美 | ✅ 可实现但代码多 |
| **斩击碎裂特效** | 🟡 需技巧 | 🔴 不支持粒子 | ✅ 原生粒子系统 | 🔴 极难实现 |
| **牌面粒子爆发** | 🟡 有限 | 🔴 不支持 | ✅ ParticleSystem | 🔴 极难实现 |
| **北斗七星连线** | ✅ 路径动画 | ✅ 路径动画 | ✅ 可实现 | ✅ 可实现 |
| **4 选 1 按钮动效** | 🔴 过度设计 | ✅ 轻量 | 🔴 过度设计 | ✅ 最合适 |
| **文件体积** | ~50KB/个 | ~30KB/个 | 内置引擎 ~3MB | 0 (代码) |
| **设计师友好度** | ✅ Rive Editor | ✅ After Effects | ❌ 需开发参与 | ❌ 纯代码 |

#### 6.2 推荐混合策略

```
┌─────────────────────────────────────────┐
│           TileZhan 动效分层              │
├─────────────────────────────────────────┤
│                                          │
│  Layer 1: 微交互 (原生 Animation)        │
│  ├─ 按钮 hover/press 状态               │
│  ├─ 卡片 4 选 1 选中高亮                │
│  ├─ 页面转场路由动画                     │
│  └─ 体力值爱心破碎                      │
│                                          │
│  Layer 2: 复杂动效 (Rive)               │
│  ├─ 34 张牌的 Mnemonic 微动效           │
│  ├─ 火焰/水流/爆炸 预设特效              │
│  └─ 付费墙解锁庆祝动画                   │
│                                          │
│  Layer 3: 游戏级特效 (Flame)             │
│  ├─ 斩击碎裂 + 粒子爆发（核心爽点）      │
│  ├─ 胡牌金色粒子特效                     │
│  └─ 何切答对时牌面"斩断"动画             │
│                                          │
└─────────────────────────────────────────┘
```

**Flame 集成注意**：
- Flame 运行在自己的 `GameWidget` 中，和 Flutter Widget Tree 是隔离的
- 在何切模块中，可以使用 `GameWidget.overlays` 在 Flame 画布上叠加 Flutter UI（如分数显示）
- MVP 阶段 Flame 仅用于何切模块的"斩"特效，其余用 Rive + 原生 Animation

---

### D7. 支付与订阅架构

#### 7.1 RevenueCat 集成

```
┌──────────┐     ┌──────────────┐     ┌──────────┐
│  Flutter  │────▶│  RevenueCat  │────▶│  App Store│
│  Client   │     │  SDK         │     │  / Google │
│           │◀────│              │◀────│  Play     │
└──────────┘     └──────┬───────┘     └──────────┘
                        │
                        │ Webhook
                        ▼
                 ┌──────────────┐
                 │  FastAPI     │
                 │  /webhooks/  │
                 │  revenuecat  │
                 └──────┬───────┘
                        │
                        ▼
                 ┌──────────────┐
                 │  Firestore   │
                 │  user/{uid}/ │
                 │  subscription│
                 └──────────────┘
```

#### 7.2 商品配置

| Product ID | 类型 | 价格 | 内容 |
|---|---|---|---|
| `tilezhan_premium_monthly` | Auto-renewable | $4.99 | 月度 Pro |
| `tilezhan_premium_weekly` | Auto-renewable | $1.49 | 周度 Pro（冲动消费入口） |
| `tilezhan_premium_yearly` | Auto-renewable | $29.99 | 年度 Pro（50% off vs 月度） |
| `tilezhan_skin_cyberpunk` | Consumable | $2.99 | 赛博国风牌面皮肤 |
| `tilezhan_skin_tang_dynasty` | Consumable | $2.99 | 大唐水墨牌面皮肤 |
| `tilezhan_stamina_pack_5` | Consumable | $0.99 | 5 点体力值补充 |

#### 7.3 收据验证流程

```python
@app.post("/api/v1/subscription/verify")
async def verify_subscription(
    user_id: str,
    receipt_data: str,  # RevenueCat 返回的 purchaserInfo
    db: Firestore = Depends()
):
    """
    服务端二次验证订阅状态。
    不能信任客户端返回的 isPro 字段——必须服务端独立验证。
    """
    # 1. 调用 RevenueCat REST API 验证
    rc_response = await revenuecat_api.get_subscriber(user_id)
    
    # 2. 检查有效授权
    entitlements = rc_response.get("subscriber", {}).get("entitlements", {})
    is_pro = entitlements.get("premium", {}).get("expires_date")
    
    if is_pro and datetime.fromisoformat(is_pro) > datetime.utcnow():
        # 3. 更新 Firestore
        await db.collection("users").document(user_id).update({
            "subscription_tier": "premium",
            "subscription_expiry": is_pro
        })
        return {"is_pro": True, "expires_at": is_pro}
    
    return {"is_pro": False}
```

---

### D8. 基础设施成本估算

#### 8.1 MVP 阶段（月活 ≤ 1万）

| 服务 | 用途 | 月成本 (USD) |
|---|---|---|
| **Firebase Auth** | 用户认证 | $0（免费额度内） |
| **Firestore** | 用户数据存储 | $0-25（免费额度：1GB 存储 + 5万读/天） |
| **Cloud Storage** | 用户上传截图（AI 诊断功能） | $0-10 |
| **Cloud Functions** | SRS 调度定时任务 | $0-5 |
| **Cloudflare CDN** | 静态资产分发 + DDoS 防护 | $0（免费计划） |
| **FastAPI 服务器** | 算番引擎 + 题库生成 | $20-50（Railway / Fly.io / GCP Cloud Run） |
| **RevenueCat** | 支付订阅管理 | $0（月收入 <$10k 免费） |
| **域名** | tilezhan.app | $12/年 |
| **Apple Developer** | App Store 上架 | $99/年 |
| **Google Play** | Google Play 上架 | $25（一次性） |
| **总计** | | **约 $60-110/月** |

#### 8.2 规模化阶段（月活 10万+）

| 服务 | 预估月成本 |
|---|---|
| Firestore (增强配额) | $200-500 |
| Cloud Run (扩缩容) | $200-500 |
| CDN (高流量) | $50-200 |
| RevenueCat | $200（Pro 计划） |
| 监控 (Sentry/Datadog) | $50-100 |
| **总计** | **约 $700-1500/月** |

盈亏平衡点（以月活 10万，付费率 3-5%，ARPU $4.99 测算）：
- 付费用户：3,000-5,000
- 月收入：$15,000-25,000
- 毛利率：~90%+

---

### D9. CI/CD 与发布管线

#### 9.1 推荐工具链

```
GitHub (源码管理)
  ├─ GitHub Actions (CI/CD)
  │   ├─ Pull Request → Flutter Analyze + Test
  │   ├─ Push to main → Build + Deploy
  │   └─ Scheduled → Weekly Dependency Audit
  │
  ├─ Fastlane (自动化打包)
  │   ├─ iOS: build + TestFlight upload
  │   └─ Android: build + Play Store Internal Track
  │
  └─ Shorebird (热修复)
      └─ 无需 App Store 审核的 Dart 代码更新
```

#### 9.2 GitHub Actions 工作流

```yaml
# .github/workflows/ci.yml
name: TileZhan CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage

  build-android:
    needs: analyze
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      # ... build APK/AAB + upload to Play Store via Fastlane

  build-ios:
    needs: analyze
    if: github.ref == 'refs/heads/main'
    runs-on: macos-latest
    steps:
      # ... build IPA + upload to TestFlight via Fastlane
```

---

## 总结：推荐技术栈与排期修正

### 最终推荐技术栈

| 层 | 技术选型 | 版本要求 |
|---|---|---|
| **客户端** | Flutter | ≥ 3.24 (Impeller) |
| **游戏特效** | Flame Engine | ≥ 1.17 |
| **复杂动效** | Rive | Runtime ≥ 0.13 |
| **本地存储** | Hive (缓存) + Isar (结构化) | 最新稳定版 |
| **后端 API** | Python FastAPI | ≥ 0.111 |
| **算番引擎** | mahjong (Python) + Dart Shanten Calc | - |
| **BaaS** | Firebase (Auth, Firestore, Analytics, Crashlytics) | - |
| **支付** | RevenueCat | SDK ≥ 4.0 |
| **CDN** | Cloudflare | Free Plan |
| **CI/CD** | GitHub Actions + Fastlane + Shorebird | - |
| **监控** | Sentry + Firebase Crashlytics | - |

### 排期修正（基于 PRD 深化的发现）

| 周次 | 原计划 | 修正后 |
|---|---|---|
| **Week 1** | 视觉资产设计 + 后端引擎 | **增加**：Reddit 前置调研（3 天，B2.3）+ Style Guide 定稿（1 天） |
| **Week 2** | Flutter 闪卡 + 何切 | **增加**：Shanten Calculator Dart 实现 + 单元测试（2 天） |
| **Week 3** | 支付接入 + 徽章系统 | **增加**：RevenueCat Webhook 服务端验证（1 天）+ SRS SM-2 实现（1 天） |
| **Week 4** | 提审 + TikTok 营销 | **增加**：UserTesting.com 认知验证上线（B2.1，与提审并行）+ 数据埋点验证 |

**修正后总工期：仍为 4 周，但 Week 1-2 的工作密度显著增加，建议配置 1 名 Flutter 开发 + 1 名 Python 后端 + 1 名外包画师（并行）。**

---

## 后续行动建议

1. **立即行动**：Reddit r/Mahjong 前置调研（Figma 低保真原型 → 社区验证）
2. **本周内**：Flutter 项目骨架搭建 + Shanten Calculator Dart 原型
3. **Week 2 前**：34 张 Meme 插画的 Style Guide 最终定稿，启动外包绘制
4. **Week 3 前**：UserTesting.com 认知验证实验上线（与开发并行）

---

> 📌 本文档为 TileZhan（麻雀斩）项目的 PRD 深化与技术架构评审，应作为后续所有开发决策的参考基线。所有"推荐"和"选择"均基于 2026 年 Q2 的技术生态和成本评估，如有重大技术变更（如 Flutter 大版本更新、Firebase 定价调整），需重新评审。
