# 服务端接口说明

## 基本信息

- 应用入口：`backend/app/main.py`
- 本地默认地址：`http://127.0.0.1:8000`
- 业务前缀：`/api/v1`
- 健康检查：`GET /health`
- 交互文档：`GET /docs`
- 接口定义：`GET /openapi.json`

本文记录当前代码行为，不代表所有原型接口都已经具备生产级持久化和权限控制。

## 认证

受保护接口要求请求头：

```http
Authorization: Bearer <Firebase 身份令牌>
```

验证流程：

1. FastAPI 的 `HTTPBearer` 提取令牌。
2. `get_current_user` 调用 Firebase Admin SDK 验证令牌。
3. 验证成功后，把至少包含 `uid` 的用户信息传给路由。
4. 无效令牌返回 `401`；认证基础设施异常返回脱敏的 `503`。

只有开发或测试环境可以显式设置 `ALLOW_DEV_AUTH_BYPASS=true`。生产环境设置该值会导致启动校验失败。

## 接口总表

| 方法 | 路径 | 认证 | 当前作用 |
|---|---|---:|---|
| `GET` | `/health` | 否 | 返回服务状态和版本 |
| `GET` | `/api/v1/user/profile` | 是 | 返回当前用户资料模板 |
| `GET` | `/api/v1/user/stamina` | 是 | 返回体力和服务端时间 |
| `POST` | `/api/v1/user/stamina/consume` | 是 | 校验客户端时间并消耗一颗心 |
| `GET` | `/api/v1/puzzles/daily` | 是 | 返回每日闪卡；何切与 SRS 字段目前为空 |
| `GET` | `/api/v1/puzzles/flashcards` | 是 | 按花色和数量随机返回闪卡 |
| `POST` | `/api/v1/mahjong/shanten` | 是 | 计算 13 或 14 张牌的向听数 |
| `POST` | `/api/v1/mahjong/ukeire` | 是 | 计算 14 张牌各弃牌候选的有效牌 |
| `GET` | `/api/v1/srs/review_due` | 是 | 原型接口，目前返回空复习队列 |
| `POST` | `/api/v1/srs/report` | 是 | 原型 SM-2 结果计算，不写数据库 |
| `POST` | `/api/v1/subscription/verify` | 是 | 返回当前进程中的订阅状态 |
| `GET` | `/api/v1/subscription/status` | 是 | 返回订阅等级和过期时间 |
| `POST` | `/api/v1/subscription/webhooks/revenuecat` | webhook 密钥 | 接收 RevenueCat 事件 |
| `GET` | `/api/v1/products/` | 否 | 返回后端产品定义与权益映射 |
| `GET` | `/api/v1/analytics/dashboard` | 否 | 返回进程内运营指标原型 |
| `POST` | `/api/v1/analytics/track` | 否 | 写入进程内分析事件原型 |
| `GET` | `/api/v1/leaderboard` | 否 | 查询 Firestore 或内存排行榜 |
| `POST` | `/api/v1/leaderboard/report` | 否 | 按玩家名称上报更高 ELO |

## 用户与体力

### 消耗体力

请求：

```json
{
  "client_timestamp": 1724457600000,
  "hearts_before": 3
}
```

服务端校验客户端时间与服务端时间偏差，并返回剩余心数与服务端时间。目前用户资料和体力值仍是模板/请求驱动逻辑，没有写入持久数据库。

## 题目

### 获取闪卡

```http
GET /api/v1/puzzles/flashcards?suite=man&count=10
```

`suite` 可取：

- `all`
- `man`
- `pin`
- `sou`
- `honor`

`count` 范围为 5 到 20。

每日题目接口当前只随机返回 10 张闪卡，`nanikiru` 与 `srs_review` 仍为空列表。客户端现有何切与本地 SRS 不应依赖这两个空字段。

## 麻将计算

牌张 ID 使用 `m1` 到 `m9`、`p1` 到 `p9`、`s1` 到 `s9`、`z1` 到 `z7`。

请求示例：

```json
{
  "tiles": ["m1", "m2", "m3", "p1", "p2", "p3", "s1", "s2", "s3", "z1", "z1", "z1", "z2", "z2"]
}
```

校验规则：

- 只能提交 13 或 14 张牌。
- 每个 ID 必须合法。
- 同一种牌不能超过四张。
- 有效牌接口必须恰好 14 张，否则返回 `400`。

向听数支持标准型、七对子和国士无双。有效牌结果按弃牌 ID 返回弃牌后向听数、有效牌种类和剩余枚数。

## 间隔重复接口

服务端 SRS 目前是原型：

- 到期列表固定为空。
- 上报接口基于请求中的 `quality` 返回新的容易度和间隔。
- 结果没有写入 Firestore。
- 客户端的正式训练进度当前以设备本地 SRS 为主。

在接入线上 SRS 前，必须定义客户端与服务端的权威来源、冲突合并、幂等键和离线回放策略。

## 订阅与产品

客户端代码当前商品 ID：

- `com.tilezhan.app.premium.monthly`
- `com.tilezhan.app.premium.yearly`
- `com.tilezhan.app.premium.lifetime`

后端产品表当前商品 ID：

- `tilezhan_premium_monthly`
- `tilezhan_premium_yearly`

两者不一致，后端也尚未定义永久买断产品。因此在重新开启销售前必须：

1. 选定唯一且与商店后台一致的商品 ID。
2. 同步客户端、后端、App Store Connect、Google Play Console 和 RevenueCat。
3. 明确月度、年度和永久权益映射。
4. 使用沙盒/许可测试账号完成购买、续期、取消、退款和恢复验证。
5. 完成服务端票据或权益校验，不能只依赖客户端回调。

默认构建关闭新销售，因此该不一致不会阻止当前免费版本训练，但属于重新商业化前的阻断项。

RevenueCat webhook 当前实现还需要在生产启用前复核配置对象导入、未配置密钥时的行为和自动化测试覆盖。现有路由代码引用运行时 `settings`，但没有显式导入该对象；在修复前不能把 webhook 视为已验证的生产能力。

## 排行榜与分析

排行榜优先使用 Firestore；不可用时降级为进程内字典。分析数据同样存放在进程内。以下限制必须明确：

- 进程重启会丢失内存数据。
- 多实例部署时数据不一致。
- 排行榜上报当前没有身份认证，玩家名称直接参与文档 ID。
- 分析仪表盘和事件上报当前没有管理员或用户鉴权。
- 上线生产前必须增加权限、输入限制、速率限制和持久化方案。

## 错误处理约定

- `400`：业务输入不满足要求，例如体力不足或有效牌接口不是 14 张。
- `401`：Firebase 身份令牌无效或过期。
- `422`：Pydantic 请求结构、牌数或牌张 ID 校验失败。
- `429`：超过限流策略时使用。
- `503`：Firebase 等认证基础设施不可用。

服务端日志可以记录异常上下文，但响应不得返回令牌、私钥、完整内部堆栈或服务账号内容。
