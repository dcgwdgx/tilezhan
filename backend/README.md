# 服务端开发指南（TileZhan）

服务端提供 Firebase 认证、用户与体力、题目、SRS、麻将计算、订阅校验、分析事件和排行榜 API。

接口的认证要求、参数、返回结构和原型限制见 [服务端接口说明](../docs/api.md)。

## 环境要求

- Python `3.12`（GitHub Actions 使用的版本）
- 可选：Firebase / Firestore 项目
- 可选：Redis，用于 Celery 后台任务
- 可选：RevenueCat，用于订阅校验和 webhook

## 安装

PowerShell 7：

```powershell
Set-Location backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
Copy-Item .env.example .env
```

`requirements.txt` 中的固定版本会在 Backend CI 的 Python 3.12 环境安装。更新依赖后，至少运行一次完整安装或 `pip install --dry-run -r requirements.txt`，避免锁定不存在的版本。

## 配置

服务通过 `pydantic-settings` 读取环境变量和当前目录中的 `.env`。

| 变量 | 代码默认值 | 说明 |
|---|---|---|
| `APP_NAME` | `TileZhan API` | OpenAPI 和日志中的服务名 |
| `APP_VERSION` | `1.0.0` | `/health` 与 OpenAPI 版本 |
| `APP_ENV` | `development` | `development`、`test` 或 `production` |
| `DEBUG` | `false` | 生产环境必须为 `false` |
| `ALLOW_DEV_AUTH_BYPASS` | `false` | 仅允许在开发或测试环境显式启用 |
| `FIREBASE_PROJECT_ID` | 空 | Firebase 项目 ID |
| `FIREBASE_PRIVATE_KEY` | 空 | 服务账号私钥，换行可写为 `\n` |
| `FIREBASE_CLIENT_EMAIL` | 空 | 服务账号邮箱 |
| `FIRESTORE_DATABASE` | `(default)` | Firestore 数据库 ID |
| `REVENUECAT_API_KEY` | 空 | RevenueCat 服务端 API key |
| `REVENUECAT_WEBHOOK_SECRET` | 空 | RevenueCat webhook 校验密钥 |
| `REDIS_URL` | `redis://localhost:6379/0` | Redis / Valkey / KeyDB 地址 |
| `RATE_LIMIT_PER_MINUTE` | `100` | 每分钟请求限制 |
| `ALLOWED_ORIGINS` | `["https://tilezhan.app"]` | JSON 格式的 CORS 白名单 |

`.env.example` 为方便本地排错设置了 `DEBUG=true`，复制后会覆盖代码中的 `false`。进入测试、预发布或生产环境时必须显式改回 `false`。

不要提交真实 `.env`、Firebase 私钥、RevenueCat 密钥或服务账号 JSON。

### 生产环境安全要求

当 `APP_ENV=production` 时，应用启动前会拒绝以下配置：

- Firebase 项目 ID、私钥或客户端邮箱缺失
- RevenueCat webhook secret 缺失
- `DEBUG=true`
- `ALLOW_DEV_AUTH_BYPASS=true`

开发认证绕过必须保持显式、局部和可测试，不能根据“Firebase 凭证是否缺失”自动开启。

## 启动

```powershell
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

常用入口：

- `GET /health`：健康检查
- `/docs`：Swagger UI
- `/openapi.json`：OpenAPI schema

## 接口分组

所有业务 API 使用 `/api/v1` 前缀：

- `/user`：用户资料与体力
- `/puzzles`：每日题目和闪卡
- `/mahjong`：向听数与有效牌计算
- `/srs`：到期复习和结果上报
- `/subscription`：订阅校验、状态和 RevenueCat webhook
- `/products`：产品定义
- `/analytics`：分析仪表盘和事件
- `/leaderboard`：排行榜与异常成绩上报

除明确公开的入口外，受保护 API 使用 Firebase Bearer token。

## 测试

```powershell
python -m pytest -q
```

测试覆盖配置校验、认证安全、Firebase 初始化、API 路由，以及向听数和有效牌计算。Pull Request 修改 `backend/**` 时会触发 `Backend CI`；合并到 `main` 后也会重新运行。

完整测试门槛和 GitHub Actions 说明见 [测试与质量保证](../docs/testing.md)。
