# App Store 订阅审核清单（Guideline 3.1.2 / 2.1）

针对 Rejection（Submission `95ccd895-476e-4b54-903f-f8483ea4106b`）的修复与操作说明。

## 结论：代码侧已补齐，ASC 配置仍需人工完成

| 问题 | 状态 | 说明 |
|------|------|------|
| 3.1.2(c) 缺少 Terms of Use (EULA) 功能链接 | 代码已提供公开 URL；**ASC 元数据需你粘贴** | 见下方「App Store Connect 元数据」 |
| 应用内隐私政策 / 条款可打开页面 | **已修复** | 「更多」与「星屿会员」均可进入完整页面 |
| 2.1(b) 内购商品未提交审核 | **需在 ASC 操作** | 代码商品 ID 已就绪，须随版本一并提交 |

## 公开可打开链接（部署后端后生效）

先部署包含 `/legal` 静态页的后端，然后在浏览器验证：

- Terms of Use (EULA)：https://api.lcxxingyu.fun/legal/terms
- Privacy Policy：https://api.lcxxingyu.fun/legal/privacy
- 目录页：https://api.lcxxingyu.fun/legal/

## App Store Connect 元数据（必须）

1. **隐私政策 URL**（App 信息 → 隐私政策）  
   `https://api.lcxxingyu.fun/legal/privacy`

2. **Terms of Use (EULA)**（二选一）  
   - **推荐（自定义 EULA）**：App 信息 → 许可协议协议 → 自定义，粘贴条款全文；或在「App 描述」末尾加入：  
     `Terms of Use (EULA): https://api.lcxxingyu.fun/legal/terms`  
   - **若使用 Apple 标准 EULA**：在 App 描述中加入：  
     `Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`

### App 描述可直接粘贴的补充段落

```text
星屿会员为自动续费订阅，含月卡（1 个月）、季卡（3 个月）、年卡（12 个月）。
付款将计入 Apple ID；订阅将自动续费，除非在当前周期结束至少 24 小时前取消。
可在「设置」> Apple ID >「订阅」中管理或取消。

Privacy Policy: https://api.lcxxingyu.fun/legal/privacy
Terms of Use (EULA): https://api.lcxxingyu.fun/legal/terms
```

## 内购商品提交（Guideline 2.1(b)）

应用内商品 ID（须与 ASC 一致）：

| Product ID | 名称建议 | 时长 | 标价（CNY） |
|------------|----------|------|-------------|
| `com.xiaoerlcx.app.vip.monthly` | 星屿会员·月卡 | 1 个月 | ¥12 |
| `com.xiaoerlcx.app.vip.quarterly` | 星屿会员·季卡 | 3 个月 | ¥28 |
| `com.xiaoerlcx.app.vip.yearly` | 星屿会员·年卡 | 12 个月 | ¥98 |

操作步骤：

1. App Store Connect → 你的 App → **App 内购买项目**
2. 确认上述 3 个自动续期订阅已创建，状态不是「元数据缺失」
3. 为每个商品上传 **App Review 截图**（订阅页即可）
4. 在提交新版本时，于「App 审核」页勾选这些 IAP，与二进制**一并提交审核**
5. 上传**新二进制**（含本修复的法律页面入口）

## 应用内入口（审核录屏建议路径）

1. 登录 → **更多** → **用户协议 / Terms of Use**（完整页）
2. **更多** → **隐私政策 / Privacy Policy**（完整页）
3. **更多** → **星屿会员** → 底部 **Terms of Use / Privacy Policy** 链接
4. 订阅页可见：套餐名称、时长、价格、自动续费说明、恢复购买

## 回复审核的 Notes 建议

```text
We have added functional Terms of Use (EULA) and Privacy Policy pages:
- In-app: More → Terms of Use / Privacy Policy; Membership page links
- Metadata URLs:
  Privacy Policy: https://api.lcxxingyu.fun/legal/privacy
  Terms of Use (EULA): https://api.lcxxingyu.fun/legal/terms
Subscription IAPs are submitted with this binary:
  com.xiaoerlcx.app.vip.monthly / quarterly / yearly
Screen recording attached showing the openable legal pages and subscription info.
```
