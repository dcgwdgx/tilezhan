# TileZhan App Store Connect 配置指南

## 1. GitHub Secrets 配置

在 GitHub 仓库 `Settings → Secrets and variables → Actions` 添加：

### iOS 必需

| Secret | 来源 | 说明 |
|---|---|---|
| `APPLE_P12_BASE64` | `base64 Certificates.p12` | 发布证书（Keychain → 导出为 .p12 → base64 编码） |
| `APPLE_P12_PASSWORD` | 导出时设置的密码 | P12 密码 |
| `APPSTORE_ISSUER_ID` | App Store Connect → 用户和访问 → 密钥 → Issuer ID | API 密钥 |
| `APPSTORE_KEY_ID` | 同上 → Key ID | 密钥 ID |
| `APPSTORE_PRIVATE_KEY` | 下载的 .p8 文件内容 | API 私钥 |

### Android 必需

| Secret | 说明 |
|---|---|
| `GOOGLE_PLAY_SERVICE_ACCOUNT` | Google Play Console → 服务账号 → JSON 密钥全文 |

## 2. App Store Connect 操作步骤

### 2.1 创建 App
1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → 我的 App → +
2. Bundle ID: `com.tilezhan.app`
3. 名称: TileZhan

### 2.2 创建 API 密钥（用于 CI）
1. 用户和访问 → 集成 → App Store Connect API
2. 生成 API 密钥 → 下载 .p8 → 复制 Key ID 和 Issuer ID

### 2.3 创建内购商品（与 RevenueCat 同步）
在 App Store Connect → 功能 → App 内购买项目，逐项创建：

| 产品 ID | 类型 | 价格 |
|---|---|---|
| `tilezhan_premium_monthly` | 自动续期订阅 | $4.99/月 |
| `tilezhan_premium_weekly` | 自动续期订阅 | $1.49/周 |
| `tilezhan_premium_yearly` | 自动续期订阅 | $29.99/年 |
| `tilezhan_skin_cyberpunk` | 消耗型 | $2.99 |
| `tilezhan_skin_dynasty` | 消耗型 | $2.99 |
| `tilezhan_stamina_pack_5` | 消耗型 | $0.99 |

## 3. RevenueCat 对接

1. [app.revenuecat.com](https://app.revenuecat.com) → 创建项目
2. 添加 App → 填入 Bundle ID
3. 在 RevenueCat → 权利 → 创建 `premium` 权限
4. 在 RevenueCat → 产品 → 关联 App Store Connect 的商品 ID
5. 复制 API 密钥 → 填入 `backend/.env`:
   ```
   REVENUECAT_API_KEY=rck_...
   REVENUECAT_WEBHOOK_SECRET=whsec_...
   ```
6. 在 RevenueCat → 集成 → Webhook → 填入 `https://api.tilezhan.app/api/v1/webhooks/revenuecat`

## 4. 首次部署

推送代码到 main 分支即可自动触发 CI/CD：
```
git push origin main
```

或手动触发（不部署）：
```
GitHub Actions → Frontend CI/CD → Run workflow → deploy: false
```
