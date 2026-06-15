# 项目全量审计报告

审计对象：学生成长观察 / 心情岛屿 / 教师预警项目  
审计日期：2026-06-08  
审计范围：`stday` 学生端、`teacher_app` 教师端、`backend` FastAPI、数据库模型/迁移、配置/部署/测试文档。

## 1. 审计方法与发现过程

本次审计按“页面 -> Repository/API -> 后端 Endpoint -> Service/Repository -> ORM 表”的路径追踪，并使用以下证据源：

- 前端路由与页面：`stday/lib/router/app_router.dart`、`teacher_app/lib/app.dart`、`features/**`。
- 前端接口调用：`stday/lib/data/repositories/app_repository.dart`、`teacher_app/lib/data/repositories/teacher_repository.dart`。
- 后端路由：`backend/app/api/v1/endpoints/*.py`、聚合入口 `backend/app/api/v1/api.py`。
- 后端业务：`backend/app/services/*.py`、`backend/app/repositories/*.py`。
- 数据结构：`backend/app/models/*.py`、`backend/alembic/versions/*.py`。
- 配置与部署：`backend/app/core/config.py`、`backend/.env.example`、`config/*.env*`、`docs/DEPLOYMENT*.md`。

## 2. 项目结构图

```text
项目总架构图
├── frontend
│   ├── stday/                 # 学生端 Flutter：注册、每日心情/故事、成长岛、成长值
│   └── teacher_app/           # 教师端 Flutter：班级心情、危险信号、成长档案
├── backend
│   ├── app/main.py            # FastAPI 入口
│   ├── app/api/v1/endpoints   # 业务接口
│   ├── app/services           # 业务编排
│   ├── app/repositories       # 数据访问
│   ├── app/models             # SQLAlchemy ORM
│   ├── app/schemas            # Pydantic DTO
│   ├── app/rag, app/story_engine, app/prompts
│   └── app/tests              # 少量单元/冒烟测试
├── database
│   └── backend/alembic        # PostgreSQL 迁移，14 个版本脚本
├── ai
│   ├── app/rag                # Qwen/DashScope Provider
│   ├── app/services/*ai*      # 心情报告、小人动作、通用 AI
│   └── app/story_engine       # 成长故事 Rule -> Plan -> Prompt -> LLM
├── docs
│   ├── DEPLOYMENT.md
│   ├── DEPLOYMENT_LINUX_BACKEND.md
│   └── audit/                 # 本次审计报告
└── deployment
    ├── backend/deploy         # install.sh/start.sh/systemd
    ├── config                 # 客户端/服务器地址说明，非自动加载
    └── *.bat/*.ps1            # Windows 运行和构建脚本
```

### 2.1 目录职责判断

| 目录 | 用途 | 职责问题 | 重复/无效模块 |
|---|---|---|---|
| `stday` | 学生端 | 学生端承担部分成长值兜底计算，和服务端口径可能不一致 | 旧 `CompanionPage`、旧岛屿 Painter、旧故事卡片仍存在 |
| `teacher_app` | 教师端 | “成长关注”实际展示危险信号，产品命名漂移 | 旧 `teacher/alerts` Repository 方法、`MoodDetailPage` 未接主导航 |
| `backend/app/api` | 接口层 | 部分管理接口只要求登录，未做角色/资源边界 | `/students`、`/observations`、`/story`、`/rules`、`/ai` 风险较高 |
| `backend/app/services` | 业务层 | 教师班级隔离较好；学生通用 CRUD 缺归属校验 | `growth_archive_service.get_archive` 有私有构建方法未接返回 |
| `backend/app/models` | ORM 表 | 表结构覆盖主业务 | RBAC Permission 表未真正用于鉴权 |
| `config` | 地址/环境说明 | 文件不会被程序自动读取 | 公网 IP 多处硬编码 |
| `backend/deploy` | Linux 手工部署 | 无 Docker、无 CI | systemd/workers 与脚本配置不一致 |

## 3. 技术栈与核心模块

| 子系统 | 技术/组件 | 关键文件 |
|---|---|---|
| 学生端 | Flutter、Riverpod、GoRouter、Dio、SharedPreferences | `stday/lib/app.dart`、`stday/lib/data/repositories/app_repository.dart` |
| 教师端 | Flutter、Riverpod、GoRouter、Dio | `teacher_app/lib/app.dart`、`teacher_app/lib/data/repositories/teacher_repository.dart` |
| 后端 | FastAPI、SQLAlchemy Async、Pydantic、JWT、Alembic | `backend/app/main.py`、`backend/app/api/v1/api.py` |
| 数据库 | PostgreSQL | `backend/app/models/*.py`、`backend/alembic/versions/*.py` |
| AI | DashScope/Qwen，OpenAI-compatible SDK，HTTP task API | `backend/app/rag/*.py`、`backend/app/services/daily_mood_report_service.py` |

## 4. 死代码与重复逻辑审计

### 4.1 疑似无引用/废弃页面与模块

| 路径/符号 | 原因 | 建议 | 风险 |
|---|---|---|---|
| `stday/lib/features/onboarding/companion_page.dart` | 正常注册流程在 `GenderPage` 后直接进入 `/today`，后端也自动完成 onboarding | 删除路由或恢复选择伙伴流程 | 中 |
| `stday/lib/features/landing/landing_island_hero.dart` | 已标记 `@Deprecated`，主流程不引用 | 删除或迁移到新世界引擎 | 低 |
| `stday/lib/features/today/moment_story_card.dart` | 被 `TodayStoryCard` 替代 | 删除 | 低 |
| `stday/lib/design_system/island_game/growth_island_game.dart` | Flame 岛屿游戏未进入主路由 | 标记 experimental 或删除 | 低 |
| `stday/lib/providers/world_state_provider.dart::worldSceneParamsProvider` | 已定义但 `GrowthWorldViewport` 自行构建 world state | 合并到统一 Provider 或删除 | 低 |
| `teacher_app/lib/features/mood/mood_detail_page.dart` | 无主导航入口，心情列表点击直达成长档案 | 删除或恢复详情页入口 | 低 |
| `teacher_app/lib/data/repositories/teacher_repository.dart::listAlertsInRange` | 标记 Deprecated，UI 已切到 `risk-signals` | 删除旧 alerts 流程或接回 UI | 低 |
| `backend/app/agents/base.py` | 只有 Agent 抽象，无具体业务调用 | 标注预留或删除 | 低 |
| `backend/app/rag/qwen_provider.py::EmbeddingProvider` | Embedding 能力未接业务 | 标注未启用 | 低 |

### 4.2 无引用/低引用函数与接口

| 函数/接口 | 文件 | 引用/调用情况 | 建议 |
|---|---|---|---|
| `authEntry()` | `stday/lib/data/repositories/app_repository.dart:18` | 学生端无页面调用；README 仍写登录即注册 | 删除或恢复 `/auth/entry` 产品策略 |
| `getMoodReport()` | `teacher_repository.dart:58` | 教师端未调用 | 若不做详情页则删除 |
| `createFollowUp()` | `teacher_repository.dart:119` | Repository 有，UI 无入口 | 在成长档案补跟进表单，或删除 |
| `markGrowthFollowed/unmarkGrowthFollowed/dismissGrowthFocus` | `teacher_repository.dart:98`、`:105`、`:112` | 旧 `teacher/alerts` 流程未用 | 统一“成长关注/危险信号”语义 |
| `GET/POST /api/v1/rules/*` | `backend/app/api/v1/endpoints/rules.py` | 学生/教师端未调用，且普通用户可写 | 改为 admin-only |
| `POST /api/v1/ai/text-to-image` 等 | `backend/app/api/v1/endpoints/ai.py` | 当前产品主流程未调用 | 限 admin/内部服务，增加限流和配额 |

### 4.3 重复逻辑

| 重复内容 | 出现位置 | 建议抽象 |
|---|---|---|
| 班级列表常量 | `stday`、`teacher_app`、`backend/app/core/school_classes.py` | 前端注册页调用 `GET /api/v1/auth/classes` |
| 情绪/成长分类 | 两个 Flutter app 各维护 constants | 抽 shared Dart package 或以后端配置下发 |
| 岛屿渲染 | 学生端旧 `GrowthIslandWidget` 与新 `GrowthWorldViewport` | 统一到 `world` 引擎 |
| 成长值计算 | 后端 `GrowthPointsService` 与学生端 `GrowthSystem.compute` | 以服务端为准，客户端只缓存展示 |
| 教师关注语义 | 旧 `teacher/alerts` 与新 `teacher/risk-signals` | 产品层重命名为“危险信号”，保留一个数据源 |

## 5. 接口完整性审计

### 5.1 页面有入口但能力缺失

| 页面/功能 | 现状 | 缺失 | 风险 |
|---|---|---|---|
| 教师成长分享 | `teacher_app` 无分享页面/Repository/API | 分享生成、权限、水印、审计日志均缺失 | 中 |
| 教师通用跟进 | 后端 `POST /teacher/students/{id}/follow-ups` 存在，前端无 UI | 跟进记录无法录入 | 中 |
| 成长档案时间轴 | 后端 schema 有 `timeline`，返回硬编码空 | 教师不能还原完整轨迹 | 高 |
| AI分析可追溯 | `daily_mood_reports` 保存结果，但未保存 prompt/模型/输入快照 | 无法复现分析 | 高 |

### 5.2 接口存在但页面未调用

| 接口 | 文件 | 状态 | 建议 |
|---|---|---|---|
| `/api/v1/story/*`、`/api/v1/timeline` | `stories.py` | 学生端未调用 | 若旧版本功能，移动到 admin/legacy 或补 UI |
| `/api/v1/record`、`/api/v1/observations` | `records.py`、`observations.py` | 当前双端未调用 | 加权限后再保留 |
| `/api/v1/teacher/alerts/*` | `teacher_alerts.py` | 教师端 UI 已改用 `risk-signals` | 删除旧 UI 仓储或接入双轨 |
| `/api/v1/auth/student-login` | `auth.py` | 学生端用通用 `/auth/login` | 学生端改用专用登录以同步班级 |

### 5.3 表存在但业务未充分使用

| 表 | 现状 | 问题 |
|---|---|---|
| `permissions`、`role_permissions` | 存表但未在 Depends 中做细粒度校验 | RBAC 形同虚设 |
| `teacher_follow_ups` | 可写但 UI 未接，档案返回空 | 数据价值未闭环 |
| `story_generation_runs` | 故事引擎使用；日常心情 AI 不使用 | 核心 AI 报告缺追溯 |
| `teacher_alert_instances` | 旧成长关注流 | 与 `risk-signals` 并存导致语义混乱 |

## 6. 核心风险问题清单

| 编号 | 问题位置 | 发现 | 风险等级 | 修复优先级 | 影响上线 |
|---|---|---|---|---|---|
| A-01 | `backend/app/api/v1/endpoints/students.py:15-45` | 任意登录用户可 CRUD/list 全部学生 | 严重 | P0 | 是 |
| A-02 | `backend/app/api/v1/endpoints/observations.py:20-51` | 任意登录用户可读写任意观察记录 | 严重 | P0 | 是 |
| A-03 | `backend/app/api/v1/endpoints/stories.py:34-99` | `student_id` 查询无归属/班级校验 | 严重 | P0 | 是 |
| A-04 | `backend/app/api/v1/endpoints/island_styles.py:28-45` | 任意登录用户可修改全局岛屿样式 | 严重 | P0 | 是 |
| A-05 | `backend/app/api/v1/endpoints/rules.py:15-36` | 普通用户可创建/修改故事规则 | 高 | P0 | 是 |
| A-06 | `backend/app/api/v1/endpoints/ai.py:18-40` | 普通用户可直接调用通用 AI/T2I/I2V | 高 | P0 | 是 |
| A-07 | `backend/app/core/config.py:28` | 教师注册密钥默认 `root` | 高 | P0 | 是 |
| A-08 | `backend/.env.example:21` | JWT 示例为弱默认值 | 高 | P0 | 是 |
| A-09 | `backend/app/services/growth_archive_service.py:58-75` | `timeline`、`risk_exposures`、`follow_ups` 永远空 | 高 | P0 | 是 |
| A-10 | `backend/app/services/moment_story_service.py:14-16` | 教师列表/档案展示学生备注原文 | 高 | P0 | 是 |
| A-11 | `backend/app/main.py:12-20` | 生产 CORS 与 docs 开关不合理；docs 常开 | 中 | P1 | 视部署而定 |
| A-12 | `stday/lib/data/repositories/app_repository.dart:179-186` | 删除 4xx 可能被当成成功处理 | 中 | P1 | 否 |
| A-13 | `stday/lib/features/onboarding/*` | 引导流程保留旧伙伴选择但主流程跳过 | 中 | P1 | 否 |
| A-14 | `teacher_app` | 教师分享为零实现 | 中 | P1 | 若试点要求则是 |

## 7. AI 功能审计

### 7.1 AI 链路图

```text
学生记录心情/故事
  -> stday AddMomentFlowPage
  -> POST /api/v1/profile/moments
  -> DailyMomentService / CompanionSceneService
  -> CompanionActionAIService(QWEN_FAST_MODEL)
  -> daily_moments.visual_payload

学生整理今日心情
  -> POST /api/v1/profile/mood-report/upload
  -> DailyMoodReportService
  -> 规则检测 + QWEN_FAST_MODEL
  -> daily_mood_reports
  -> 教师端 mood reports / risk-signals

旧成长故事
  -> POST /api/v1/story/generate
  -> StoryOrchestrator
  -> stories + story_generation_runs
```

### 7.2 AI 风险

| 检查项 | 结论 | 位置 | 风险 |
|---|---|---|---|
| AI 输入是否完整 | 心情报告聚合情绪、事件、连续记录；但未保存完整输入快照 | `daily_mood_report_service.py`、`daily_mood_reports` | 高 |
| AI 输出是否落库 | 心情报告输出落入 `daily_mood_reports`，小人演出落入 `daily_moments.visual_payload` | 模型表 | 中 |
| 是否可追溯/复现 | 故事生成有 `story_generation_runs`；心情报告无 prompt/model/raw response | `story_generation_runs` vs `daily_mood_reports` | 高 |
| AI 结论是否有依据 | 教师端展示结论，但未把依据以结构化字段完整回传 | `growth_insight`、`risk_flags` | 中 |
| 是否存在直接丢失 | `QWEN_API_KEY` 缺失时部分服务降级或报错；需前端区分失败 | `daily_mood_report_service.py` | 中 |

## 8. 需求覆盖率矩阵

| 功能 | 实现状态 | 完成度 | 缺失内容 | 风险 |
|---|---|---:|---|---|
| 每日心情记录 | 已实现 | 90% | 删除失败语义、历史编辑策略需确认 | 中 |
| AI成长分析 | 部分实现 | 75% | prompt/输入快照/模型版本不可追溯 | 高 |
| 成长轨迹展示 | 部分实现 | 65% | 教师档案 timeline 空；学生端主要展示成长值 | 高 |
| 教师风险预警 | 已实现主要链路 | 80% | 敏感原文暴露、误报/漏报评估缺测试 | 高 |
| 教师成长分享 | 未实现 | 0% | 全链路缺失 | 中 |
| 学生成长档案 | 部分实现 | 70% | 教师档案 follow-ups/timeline 空 | 高 |
| 岛屿成长系统 | 已实现 | 80% | 双渲染体系、全局样式可被普通用户改 | 高 |
| 数据统计分析 | 部分实现 | 70% | category_filter 未完全接 UI，测试不足 | 中 |
| 权限与合规 | 部分实现 | 45% | 学生/通用接口水平越权，RBAC 未接入 | 严重 |
| 测试体系 | 弱实现 | 20% | 无 DB 集成、无权限回归、学生端测试失效 | 高 |

## 9. 教育场景专项审计

### 9.1 教育安全风险清单

| 风险 | 位置 | 说明 | 优先级 |
|---|---|---|---|
| 学生敏感原文向教师列表级暴露 | `moment_story_service.py:14-16`、教师端风险列表/档案 | 设置页称“不含原文”，实际危险信号含 note | P0 |
| 危险信号缺审计日志 | `teacher_risk_signals.py` | 教师查看/跟进未记录访问审计 | P1 |
| 风险预警缺人工确认闭环 | `teacher_risk_moment_follows` | 有 follow/reactivate，但通用跟进档案未展示 | P1 |
| 普通学生可访问通用 CRUD | `/students`、`/observations`、`/story` | 未成年人数据可被越权读取/破坏 | P0 |

### 9.2 数据治理风险清单

| 风险 | 表/字段 | 说明 | 优先级 |
|---|---|---|---|
| AI 输入快照缺失 | `daily_mood_reports` | 无法还原 AI 结论依据 | P0 |
| 删除记录后派生报告不同步 | `daily_moments` -> `daily_mood_reports` | 删除 moment 不自动重算当日报告/风险 | P1 |
| 孤儿/冗余班级字段 | `user_profiles.class_name`、`students.class_name` | 学生班级权威源不统一 | P1 |
| 档案链路字段空返回 | `timeline`、`risk_exposures`、`follow_ups` | 表有数据但 API 不回 | P0 |

### 9.3 AI误判风险清单

| 风险 | 说明 | 修复建议 |
|---|---|---|
| 漏报 | 仅依赖关键词/AI，缺连续低落趋势测试 | 增加规则回归集和边界样本 |
| 误报 | 教师可 dismiss，但 dismiss 依据只写 JSONB 列表 | 增加误报原因、操作者、时间 |
| 无复现 | 心情报告未保存 prompt/model/input/raw output | 增加 `ai_report_runs` 或扩展 report run 表 |

### 9.4 未成年人保护风险清单

| 风险 | 说明 | 是否阻断上线 |
|---|---|---|
| 越权访问学生资料 | 任意登录用户可访问学生/观察/故事接口 | 是 |
| 敏感备注展示口径不一致 | 产品文案与实际暴露不一致 | 是 |
| HTTP 明文部署 | Token 与敏感情绪数据明文传输 | 生产上线阻断 |
| 无访问审计 | 教师查看敏感风险详情不可追责 | 试点建议阻断 |

