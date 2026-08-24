# 系统架构

## 架构目标

TileZhan 的核心训练必须在网络不稳定时仍可使用，因此客户端采用离线优先架构。需要身份可信、跨设备共享或服务端运营的数据，再通过 FastAPI 与 Firebase 处理。

## 系统组成

```text
┌──────────────────────────────────────────────────────────────┐
│ Flutter 客户端                                               │
│                                                              │
│ 页面与组件                                                   │
│      ↓                                                       │
│ Riverpod 状态管理                                            │
│      ↓                                                       │
│ 领域逻辑：SRS、何切、防守、役种、手牌分析、每日计划            │
│      ↓                         ↓                             │
│ Hive / JSON 本地存储          Dio 网络层                     │
└───────────────────────────────┬──────────────────────────────┘
                                │ Firebase 身份令牌
                                ↓
┌──────────────────────────────────────────────────────────────┐
│ FastAPI 服务端                                               │
│ 认证依赖 → 业务接口 → 麻将计算 / 订阅 / 排行榜 / 分析          │
└───────────────┬───────────────────┬──────────────────────────┘
                │                   │
                ↓                   ↓
        Firebase / Firestore   RevenueCat / Redis
```

## 客户端分层

### 页面层

页面位于 `frontend/lib/features/*/presentation/`，负责展示状态、接收输入和触发领域动作。路由集中在 `frontend/lib/core/router/app_router.dart`。

主要路由包括：

- `/`：首页和今日训练
- `/flashcard`：闪卡训练
- `/nanikiru`：何切训练
- `/defense-training`：防守训练
- `/hand-analyzer`：手牌分析
- `/yaku-quiz`：役种测验
- `/tiles`、`/collection`、`/graveyard`：牌张和学习内容管理
- `/profile`、`/settings`、`/leaderboard`：用户与设置
- `/premium`：商业功能页面

### 状态与领域层

Riverpod Provider 和 Notifier 负责把界面与领域模型连接起来。领域层不得依赖具体页面，关键规则必须能通过纯 Dart 测试验证。

重要领域模块：

- `core/srs`：间隔重复调度和复习队列
- `features/nanikiru/domain`：何切状态、难度、自适应选题和教学分析
- `features/defense_trainer/domain`：防守题目、评估和技能进度
- `features/training_plan/domain`：每日计划、任务和弱项推荐
- `features/hand_analyzer/domain`：向听数、有效牌和弃牌候选
- `features/yaku_quiz/domain`：役种测验题目与答题状态
- `core/commerce`：销售、训练限制和购买恢复策略

### 数据层

客户端同时使用两类本地存储：

- Hive：偏好、红心、认证信息和役种收藏等简单数据。
- `StorageService`：SRS、何切掌握度、每日计划、防守进度和手牌历史等版本化 JSON。

具体键名、写入保证和迁移要求见 [数据与持久化](data-storage.md)。

### 网络层

`DioClient` 统一处理基础地址、认证头和日志。当前部分重试实现仍是占位逻辑，因此关键线上流程不能假设自动重试已经可靠可用。

## 服务端分层

```text
backend/app/
├── api/       FastAPI 依赖和版本化路由
├── core/      Firebase、安全、订阅存储和基础服务
├── domain/    牌张等领域模型
├── engine/    向听数和有效牌计算
├── services/  SRS、幂等和时间校验等服务
├── config.py  运行环境和生产安全校验
└── main.py    应用入口、生命周期、跨域和健康检查
```

服务端通过 `get_current_user` 验证 Firebase 身份令牌。只有 `APP_ENV` 为 `development` 或 `test`，并显式设置 `ALLOW_DEV_AUTH_BYPASS=true` 时，才能使用开发身份。

生产启动会先校验配置，再初始化 Firebase。配置不安全时应直接启动失败，而不是带着降级认证继续服务。

## 外部系统边界

### 身份与云端数据库

- Firebase Admin SDK 验证客户端身份令牌。
- 排行榜尝试写入 Firestore 的 `rankings` 集合。
- Firestore 不可用时，排行榜会降级到进程内内存；进程重启后数据丢失。

### 订阅服务与商店

- 服务端存在订阅查询和 RevenueCat webhook 接口。
- 客户端实际购买使用 Flutter `in_app_purchase`。
- 当前默认构建关闭新销售，免费用户不受训练限制。
- 客户端与后端商品 ID 当前不一致，重新开启销售前必须统一并完成端到端验证。

### 后台任务队列

依赖清单和配置中预留了 Redis 与 Celery，但当前主要 API 流程并不依赖后台任务才能启动。接入任务队列前需补充任务定义、运行命令、监控与失败重试文档。

## 关键数据流

### 一次训练作答

```text
用户选择答案
  → 领域评估器判定结果
  → 页面展示反馈
  → 更新对应技能进度
  → 更新每日计划
  → 必要时更新 SRS
  → 等待关键本地写入完成
```

### 一次受保护接口请求

```text
客户端取得 Firebase 身份令牌
  → Authorization: Bearer <令牌>
  → FastAPI HTTPBearer 提取令牌
  → Firebase Admin SDK 验证
  → 路由取得当前用户
  → 执行业务逻辑
```

### 一次自动发布

```text
合并到 main
  → 前后端自动化测试
  → Android 构建 AAB/APK → 上传 Google Play 内部测试
  → iOS 构建 IPA → 上传 TestFlight
  → 人工在商店控制台确认审核和正式发布状态
```

## 架构约束

- 用户可见文案必须来自英语、法语和德语 ARB，不在页面中硬编码英文。
- 存储模型使用稳定 ID 和显式版本，不能依赖枚举序号长期不变。
- 商品 ID 是客户端、后端和商店之间的契约，不能随意修改。
- 本地写入完成前，不应向用户承诺关键进度已经保存。
- 商店自动上传不等于通过审核或完成正式发布。
- 服务端进程内数据不属于持久化数据，不能用于生产可信状态。
