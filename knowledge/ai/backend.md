# 后端：给 AI 改代码用

| | |
|---|---|
| 编号 | KB-07 |
| 回答的问题 | 改 Python 从哪个服务进，哪份必须和客户端一起改 |
| 不负责 | 每个 URL 的字段表 |
| 何时更新 | 服务拆分变了，或对齐用的常量换了文件 |
| 路由 | 只在 `knowledge/README.md` |


人审接口表看 `knowledge/BACKEND_API.md`。这里只写改 Python 时从哪进、哪份必须和客户端一起改。

## 从哪进

```text
backend/app/api/v1/api.py                         路由装配
backend/app/api/v1/endpoints/                     HTTP
backend/app/services/                             业务
backend/app/repositories/                         数据库
backend/app/schemas/                              请求和响应模型
backend/alembic/versions/                         迁移
```

成功响应多数包在 `ResponseModel`，数据在 `data`。例外：`POST /api/v1/auth/token` 返回裸 token。

客户端全部打到 `stday/lib/data/repositories/app_repository.dart` 的 `StdayApiDatasource`。改 path、字段或状态码时，先改这里和 `knowledge/BACKEND_API.md`，再改对应 facade。

## 和客户端必须保持一致的数字

| 主题 | 后端 | 客户端 |
|---|---|---|
| 用户等级、当日经验、连续天数 | `backend/app/services/growth_points_service.py` | `stday/lib/core/growth/growth_system.dart` |
| 副岛 10 级建筑名 | `backend/app/config/story_island_buildings.py` | `stday/lib/core/constants/story_island_building_catalog.dart` |
| 副岛每级 30、满级 300 | 同一份 Python 配置里的成长阈值 | `stday/lib/core/constants/story_island_size.dart` |
| 内购商品 ID | `member_products.product_id` | `stday/lib/core/membership/iap_product_ids.dart` |
| 陪伴台词占位符 | `backend/app/services/companion_action_ai_service.py` | 客户端只替换 `{nickname}`，不自己生成那 3 句 |

客户端的 VIP 蒙版不是权限。写接口时仍要在服务端判断会员。会员状态在 `backend/app/services/member_service.py` 和 `permission_service.py`。

## 按任务选文件

| 要改的事 | 先打开 |
|---|---|
| 登录、注册、注销 | `endpoints/auth.py`、`services/auth_service.py`。注销是 `DELETE /auth/me` |
| 日常、语音、照片、故事岛、任务、心情 | `endpoints/profile.py`、`services/profile_service.py` |
| 语音转写正文 | `services/moment_transcription_service.py`、`moment_voice_pipeline.py`。客户端按住说话会先打 `/profile/speech/transcribe`，404 才换另一条，再 404 才临时建语音日常 |
| 成长值入账 | `services/growth_points_service.py` |
| 主岛建筑解锁 | `services/building_unlock_service.py` |
| 周观察、周期小结 | `growth_observation_analysis_service.py`、`mood_period_summary_service.py` |
| 陪伴台词 | `services/companion_action_ai_service.py`、`backend/app/core/companion_dialogue.py` |
| Apple 验单 | `endpoints/iap.py`、`services/iap_service.py`、`services/apple_service.py` |
| 激活码 | `endpoints/member.py`、`services/activation_code_service.py` |
| 成长标签、动态文案 | `endpoints/growth_tags.py`、`endpoints/i18n.py` |

管理端路由前缀是 `/api/v1/admin/`，需要管理员身份。客户端不调用它们。

## 不要做的事

- 不要在客户端蒙版通过之后，就假定服务端可以不校验。
- 不要只改 Python 里的等级表或建筑名。
- 不要把故事岛任务的完成逻辑写进客户端 repository 以外的新 HTTP 路径，除非 `BACKEND_API.md` 和 `feature_map.md` 一起改。
- 本地库和远程库可以不同名。开发启动看 `backend/README.md`，不要把部署文档 `docs/DEPLOYMENT_LINUX_BACKEND.md` 当成接口说明。
