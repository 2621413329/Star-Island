# iOS 强制更新（App Store）

## 行为

- 仅 iOS：启动时请求 `GET /api/v1/app/version?platform=ios`
- 若本地营销版本 **&lt;** `min_supported_version` → 进入不可关闭的强制更新页
- 按钮跳转 App Store：`https://apps.apple.com/app/id6782086773`
- 接口失败时不拦截（避免服务端异常导致全员无法使用）

## 服务端配置（`.env`）

```text
APPLE_APP_ID=6782086773
IOS_LATEST_VERSION=1.3.2
IOS_MIN_SUPPORTED_VERSION=1.3.2
IOS_FORCE_UPDATE_TITLE=需要更新后才能继续使用
IOS_FORCE_UPDATE_MESSAGE=当前版本已停止支持，请前往 App Store 更新至最新版本。
```

## 发版顺序（重要）

1. 新版本过审并在 App Store **可下载**
2. 再把 `IOS_MIN_SUPPORTED_VERSION`（及 `IOS_LATEST_VERSION`）改为新版本并重启后端
3. 旧包启动后会被强制引导更新

默认 `IOS_MIN_SUPPORTED_VERSION=1.0.0`，不会立刻拦截现网用户。
