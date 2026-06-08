# 配置与权限审计报告

审计范围：后端环境变量、Flutter 编译配置、部署配置、JWT/RBAC/角色权限、学生/教师/管理员资源边界。

## 1. 配置文件结构

| 文件/目录 | 用途 | 是否自动生效 |
|---|---|---|
| `backend/app/core/config.py` | Pydantic Settings，读取 `.env` | 是 |
| `backend/.env.example` | 后端环境变量模板 | 否，仅模板 |
| `backend/.env` | 运行时配置，gitignore | 是，需从 `backend/` 工作目录启动 |
| `backend/alembic/env.py` | 迁移读取 `settings.DATABASE_URL` | 是 |
| `config/client.env.example` | Flutter `API_BASE_URL` 示例 | 否 |
| `config/server.env` | 服务器地址说明 | 否 |
| `stday/lib/core/config/app_config.dart` | 学生端 `API_BASE_URL` | 是，编译期 |
| `teacher_app/lib/core/config/app_config.dart` | 教师端 `API_BASE_URL` | 是，编译期 |
| `backend/deploy/start.sh` | Uvicorn 启动 | 是 |
| `backend/deploy/stday-api.service` | systemd 模板 | 部署后生效 |

## 2. 环境变量审计

| 配置项 | 使用位置 | 是否读取 | 是否生效 | 风险等级 | 问题/建议 |
|---|---|---:|---:|---|---|
| `DATABASE_URL` | `backend/app/core/config.py:10`、`database.py`、`alembic/env.py` | 是 | 是 | 高 | 必填；应启动时 DB ping，`/health` 也应检查 DB |
| `JWT_SECRET_KEY` | `backend/app/core/security.py` | 是 | 是 | 高 | 模板弱默认；生产必须随机长串并启动校验 |
| `JWT_EXPIRE_MINUTES` | `config.py:13` | 是 | 是 | 低 | 默认 24h；无 refresh/revoke |
| `QWEN_API_KEY` | `rag/qwen_provider.py`、`dashscope_client.py`、AI services | 是 | 是 | 高 | 空时 AI 不可用；需启动/健康检查提示 |
| `OPENAI_API_KEY` | 无 | 否 | 否 | 低 | 项目使用 Qwen/DashScope，不应按 OpenAI 配置 |
| `QWEN_FAST_MODEL` | `config.py:19-22` | 是 | 是 | 中 | 用于心情/小人短交互；应保存到 AI run |
| `QWEN_CHAT_MODEL` | `config.py:17` | 是 | 是 | 中 | 用于故事/通用 chat |
| `QWEN_T2I_MODEL`、`QWEN_I2V_MODEL` | `config.py:24-25` | 是 | 是 | 中 | 通用 AI 接口对普通用户开放，存在费用风险 |
| `TEACHER_REGISTRATION_SECRET` | `config.py:28`、`auth_service.py` | 是 | 是 | 高 | 默认 `root`，生产上线阻断 |
| `DEBUG` | `main.py:12-20`、`database.py` | 是 | 是 | 中 | `DEBUG=true` 时 CORS `*` + SQL echo；`DEBUG=false` 时 Web CORS 不可用 |
| `API_BASE_URL` | 两个 Flutter `app_config.dart` | 是 | 是 | 中 | 编译期注入，发版后改地址需重打包 |
| `UVICORN_HOST/PORT/WORKERS` | deploy shell/systemd | 部分 | 部分 | 低 | `config/server.env` 不会自动 source |

## 3. Flutter 配置审计

| 检查项 | 学生端 | 教师端 | 风险 |
|---|---|---|---|
| API 基址 | `String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000')` | 同 | Release 忘记 dart-define 会连错 |
| flavor | 未见正式 flavor 体系 | 未见 | 多环境发布靠脚本，易漂移 |
| const/env | 使用编译期 const | 使用编译期 const | 不能运行时切换 |
| token 存储 | SharedPreferences | SharedPreferences | 设备侧明文存储 |
| 401 拦截 | 不完整 | 不完整 | token 过期体验差 |

## 4. FastAPI 配置审计

| 检查项 | 位置 | 结论 | 风险 |
|---|---|---|---|
| docs/redoc | `backend/app/main.py:12` | 始终开放 | 中 |
| CORS | `main.py:13-20` | 仅 DEBUG 时添加，且 `*` + credentials | 中 |
| health | `main.py:26-28` | 只返回 ok，不检查 DB/AI | 中 |
| Settings | `core/config.py` | `.env` 读取正常 | 需校验弱默认 |
| 日志 | `RequestLoggingMiddleware` | 有请求日志 | 缺敏感字段脱敏/访问审计 |

## 5. 部署结构风险

| 风险 | 位置 | 说明 | 优先级 |
|---|---|---|---|
| 无 CI | 仓库无 `.github/workflows` | 测试与 lint 无门禁 | P1 |
| 无 Docker | 无 Dockerfile/docker-compose | 环境一致性依赖手工 | P2 |
| HTTP 明文 | 部署文档默认 8000 HTTP | token 与未成年人数据明文 | P0(生产) |
| 公网 IP 硬编码 | `*.bat`、docs、`config/server.env` | 地址变更需多处修改 | P1 |
| 生产 docs 常开 | `main.py` | API 结构暴露 | P1 |

## 6. 权限体系现状

### 6.1 已实现机制

| 机制 | 文件 | 状态 |
|---|---|---|
| JWT Bearer | `backend/app/api/deps.py` | 已接入多数接口 |
| 教师角色校验 | `backend/app/api/teacher_deps.py` | `/teacher/*` 已使用 |
| 教师班级隔离 | `TeacherPrincipal.class_name` + Service 校验 | 教师端主链路较完整 |
| RBAC 表 | `models/rbac.py` | 表存在 |
| Permission 校验 | 无统一 Depends | 未实现 |

### 6.2 权限矩阵（实际状态）

| 角色 | 资源 | 读 | 写 | 删 | 现状判断 |
|---|---|---|---|---|---|
| 未登录 | `/auth/*`、`/health` | 是 | 注册/登录 | 否 | 合理 |
| 学生 | 自己 profile | 是 | 是 | 部分 moment 删除 | 合理 |
| 学生 | 自己 daily_moments | 是 | 是 | 是 | 合理 |
| 学生 | 自己 mood_reports | 是 | 生成/覆盖当天 | 否 | 基本合理 |
| 学生 | 全局 island_styles | 是 | **是** | 否 | 不合理，P0 |
| 学生 | 任意 students | **是** | **是** | **是** | 严重越权，P0 |
| 学生 | 任意 observations | **是** | **是** | **是** | 严重越权，P0 |
| 学生 | 任意 stories/timeline | **是** | 生成 | 否 | 严重越权，P0 |
| 学生 | rules | 是 | **是** | 否 | 不合理，P0 |
| 学生 | 通用 AI | 是 | 发起 T2I/I2V | 否 | 费用与内容风险，P0/P1 |
| 教师 | 本班 mood_reports | 是 | 否 | 否 | 合理 |
| 教师 | 本班 risk-signals | 是 | follow/reactivate/dismiss | 否 | 基本合理 |
| 教师 | 跨班学生 | 否 | 否 | 否 | 后端已校验 |
| 教师 | 学生备注原文 | 是（危险信号） | 否 | 否 | 合规口径需重定 |
| 管理员 | 全局规则/样式/用户 | 未定义 | 未定义 | 未定义 | 管理角色缺失 |

## 7. 越权访问问题定位

| 问题 | 文件/行 | 说明 | 修复建议 |
|---|---|---|---|
| 任意登录用户可创建学生 | `backend/app/api/v1/endpoints/students.py:15-17` | 仅 `Depends(get_current_user)` | 改 admin-only 或教师受限创建 |
| 任意登录用户可更新/删除学生 | `students.py:20-28` | 无角色/归属校验 | 学生仅自己，教师仅本班，管理员全局 |
| 任意登录用户可列学生 | `students.py:36-45` | 无 class/profile 过滤 | 按角色过滤 |
| 任意登录用户可读写 observation | `observations.py:20-51` | 仅检查学生存在 | 加资源归属 |
| 任意登录用户可查故事 | `stories.py:34-58` | `student_id` 外部传入 | 加 student ownership/class check |
| timeline 可枚举 | `stories.py:62-99` | `student_id` 可为空查全量 | 角色过滤 |
| 全局岛屿样式可写 | `island_styles.py:28-45` | 普通登录即可 PATCH | admin-only 或移除写接口 |
| 规则可写 | `rules.py:15-36` | 普通登录即可 create/update | admin-only |
| 通用 AI 可用 | `ai.py:18-40` | 普通登录即可调用 | 限流、配额、角色限制 |

## 8. 教育合规权限问题

| 问题 | 位置 | 风险 | 建议 |
|---|---|---|---|
| 设置页宣称不含原文，但危险信号展示原文 | `moment_story_service.py:14-16`、教师端风险页 | 高 | 列表脱敏；详情查看需审计与最小化 |
| 教师查看敏感详情无审计日志 | `teacher_risk_signals.py` | 高 | 增加 `teacher_access_logs` |
| 撤销风险无原因/操作者字段 | `daily_mood_reports.dismissed_risk_moment_ids` | 中 | 新建风险处置表或 JSONB 结构化对象 |
| 无家校/学校组织边界 | 当前只有班级 | 中 | 引入 school/org 维度 |

## 9. P0 修复建议

1. 新增权限依赖：
   - `get_student_owner_or_admin`
   - `get_teacher_for_class`
   - `require_admin`
2. 立即限制以下接口：
   - `/students/*`、`/observations/*`、`/story/*`、`/timeline`
   - `/rules/*`
   - `PATCH /profile/island-styles/*`
   - `/ai/text-to-image`、`/ai/image-to-video`
3. 生产启动校验：
   - `JWT_SECRET_KEY` 不能为模板值。
   - `TEACHER_REGISTRATION_SECRET` 不能为 `root`。
   - `DATABASE_URL` 不能为空。
4. 配置生产安全：
   - HTTPS。
   - 关闭 `/docs`/`/redoc` 或加认证。
   - CORS 白名单化。
5. 敏感数据：
   - 教师列表默认只展示风险标签/摘要。
   - 查看 note 原文写访问审计。

