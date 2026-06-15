# 业务流程审计报告

审计目标：从学生与教师真实使用视角，检查关键流程是否闭环、是否断链、是否有无响应/假成功/语义不一致。

## 1. 学生端流程

### 1.1 注册流程

```text
/welcome
  -> /auth/register
  -> POST /api/v1/auth/student-register
  -> users + students + user_profiles
  -> /onboarding/gender
  -> PATCH /api/v1/profile/gender
  -> /today
```

| 检查项 | 状态 | 位置 | 问题 |
|---|---|---|---|
| 注册账号落库 | 正常 | `RegisterPage` -> `AppRepository.studentRegister` | `users/students/user_profiles` 正常创建 |
| 班级选择 | 正常但硬编码 | 双 Flutter app constants + 后端 school_classes | 前端未调用 `/auth/classes` |
| 引导完整性 | 异常 | `CompanionPage` 仍存在但主流程跳过 | 伙伴选择需求名存实亡 |
| 初始心情 | 部分闭环 | 每日引导 `daily_entry_flow.dart` | 不是注册后强制步骤，进入首页后弹 |

### 1.2 登录流程

```text
/auth
  -> POST /api/v1/auth/login
  -> JWT 存 SharedPreferences
  -> GET /api/v1/profile
  -> /today 或 /onboarding/gender
```

| 检查项 | 状态 | 位置 | 问题 |
|---|---|---|---|
| 登录接口 | 可用 | `app_repository.dart:28-39` | 使用通用 `/auth/login` |
| 学生班级同步 | 异常 | 后端有 `/auth/student-login` | 通用登录不会执行 `_sync_student_class` |
| token 失效处理 | 不完整 | Dio/Auth Provider | 401 未统一登出 |

### 1.3 记录心情/故事

```text
/today
  -> AddMomentFlowPage
  -> POST /api/v1/profile/moments
  -> DailyMomentService
  -> CompanionSceneService + CompanionActionAIService
  -> daily_moments
  -> 刷新 todayMomentsProvider
```

| 检查项 | 状态 | 位置 | 问题 |
|---|---|---|---|
| 新增记录 | 正常 | `app_repository.dart:96-113` | 字段 `event_tags/emotion_tag/note` 落库 |
| 编辑记录 | 正常 | `app_repository.dart:159-177` | 后端限制当日编辑 |
| 删除记录 | 部分异常 | `app_repository.dart:179-186` | 4xx 可能被当成功；已生成报告不自动重算 |
| 敏感词/风险检测 | 部分实现 | 后端心情报告/风险服务 | 未见独立敏感词服务与测试集 |

### 1.4 查看成长与岛屿

```text
/today, /status, /more/my-level
  -> GET /profile/growth-summary
  -> GET /profile/island-styles
  -> GrowthWorldViewport
```

| 检查项 | 状态 | 位置 | 问题 |
|---|---|---|---|
| 成长值展示 | 正常 | `GrowthPointsService` | 前端失败时本地兜底，可能口径漂移 |
| 岛屿样式读取 | 正常 | `GET /profile/island-styles` | PATCH 写接口权限过宽 |
| 岛屿体系一致性 | 异常 | 学生端旧/新两套岛屿 | 欢迎页与主功能视觉/解锁可能不一致 |

### 1.5 整理今日心情 / AI 成长分析

```text
TodayMoodRecapBar
  -> POST /api/v1/profile/mood-report/upload
  -> DailyMoodReportService
  -> daily_mood_reports
  -> 弹窗展示 insight/warm_suggestion/concern
  -> 教师端读取同表
```

| 检查项 | 状态 | 位置 | 问题 |
|---|---|---|---|
| AI 输出落库 | 正常 | `daily_mood_reports` | 报告结果可读 |
| AI 可追溯 | 异常 | `daily_mood_reports` | 未保存 prompt/model/raw input/raw output |
| 打卡闭环 | 正常但错误吞掉 | `mood_report_check_in_provider.dart` | 后端失败时可能显示空状态 |

### 1.6 退出

| 检查项 | 状态 | 问题 |
|---|---|---|
| 本地 token 清理 | 正常 | 仅清本地 token，无服务端 token revoke |
| 导航回登录 | 基本正常 | 依赖 AuthProvider 状态刷新 |

## 2. 教师端流程

### 2.1 教师注册

```text
/register
  -> POST /api/v1/auth/teacher-register
  -> 校验 registration_secret
  -> users + user_profiles.class_name + user_roles(teacher)
  -> /home
```

| 检查项 | 状态 | 位置 | 问题 |
|---|---|---|---|
| 教师账号创建 | 正常 | `TeacherRepository.register` | 角色写入 |
| 注册密钥 | 高风险 | `backend/app/core/config.py:28` | 默认 `root`，生产必须阻断 |
| 班级绑定 | 正常 | `user_profiles.class_name` | 班级列表硬编码 |

### 2.2 教师登录与首页

```text
/login
  -> POST /api/v1/auth/teacher-login
  -> SharedPreferences teacher_access_token
  -> /home
  -> Tab: 心情 / 成长关注 / 更多
```

| 检查项 | 状态 | 问题 |
|---|---|---|
| 登录闭环 | 正常 | token 本地存储 |
| 冷启动状态 | 部分异常 | auth 异步加载可能闪登录页 |
| 401 统一处理 | 缺失 | token 过期后页面散落报错 |

### 2.3 查看学生今日心情

```text
MoodListPage
  -> GET /api/v1/teacher/mood-reports/today?report_date=
  -> TeacherMoodReportService.list_today
  -> daily_mood_reports JOIN students by class_name
```

| 检查项 | 状态 | 位置 | 问题 |
|---|---|---|---|
| 班级隔离 | 正常 | `TeacherMoodReportService` | 后端按 class_name 过滤 |
| 心情统计展示 | 正常 | `MoodListPage` | 可按日期看 |
| 详情页 | 断链 | `MoodDetailPage` 无入口 | 心情详情能力未用 |

### 2.4 查看风险预警 / 成长关注

```text
GrowthFocusPage
  -> GET /api/v1/teacher/risk-signals
  -> TeacherCriticalRiskService.list_signals
  -> daily_moments + teacher_risk_moment_follows
  -> RiskSignalDetailPage
```

| 检查项 | 状态 | 位置 | 问题 |
|---|---|---|---|
| 风险列表 | 正常 | `teacher_repository.dart:143-160` | 按班级过滤 |
| 跟进状态 | 正常 | `markCriticalRiskFollowed/reactivate` | 状态落库 |
| 产品命名 | 异常 | Tab 名“成长关注” | 实际是危险信号，不是旧 alerts |
| 敏感原文 | 高风险 | `moment_story_service.py:14-16` | 列表/档案可见 note 原文，与设置页文案冲突 |

### 2.5 查看成长档案

```text
GrowthObservationArchivePage
  -> GET /api/v1/teacher/students/{student_id}/growth-archive
  -> GrowthArchiveService.get_archive
  -> reports + moments
  -> 返回 trend/mood_counts/daily_records
  -> timeline=[], risk_exposures=[], follow_ups=[]
```

| 检查项 | 状态 | 位置 | 问题 |
|---|---|---|---|
| 基础趋势 | 正常 | `trend_points/mood_counts/daily_records` | 可展示 |
| 时间轴 | 异常 | `growth_archive_service.py:73` | 永远空 |
| 风险暴露 | 异常 | `growth_archive_service.py:74` | 永远空 |
| 教师跟进 | 异常 | `growth_archive_service.py:58,75` | 表存在但档案不展示 |
| 轨迹还原 | 不完整 | 档案页 | 无法完整还原成长轨迹 |

### 2.6 生成分享

| 检查项 | 状态 | 证据 |
|---|---|---|
| 分享页面 | 未实现 | `teacher_app/lib/features` 无分享页面 |
| 分享接口 | 未实现 | 后端无 teacher share endpoint |
| 分享表 | 未实现 | ORM 无分享记录/审计表 |
| 风险 | 若产品目标要求教师成长分享，该功能当前 0% | P1 或上线范围裁剪 |

### 2.7 退出

| 检查项 | 状态 | 问题 |
|---|---|---|
| 清 token | 正常 | `SettingsPage` |
| 服务端会话 | 无 | JWT 无 revoke/refresh 策略 |

## 3. 断链步骤清单

| 编号 | 流程 | 断链位置 | 影响 | 优先级 |
|---|---|---|---|---|
| B-01 | 学生 onboarding | 性别后跳过伙伴选择 | 伙伴选择需求未闭环 | P1 |
| B-02 | 学生登录 | 未调用 `student-login` | 班级同步可能失效 | P1 |
| B-03 | 删除故事 | 删除后不重算当日报告 | 教师风险/统计可能过期 | P1 |
| B-04 | 教师档案 | `timeline/risk_exposures/follow_ups` 空 | 成长档案不完整 | P0 |
| B-05 | 教师分享 | 无页面/接口/表 | 需求未实现 | P1 |
| B-06 | 教师通用跟进 | 有接口无 UI，有表无展示 | 跟进闭环缺失 | P1 |
| B-07 | 权限流程 | 学生可调通用管理接口 | 数据越权 | P0 |

## 4. 无响应/假成功步骤

| 场景 | 位置 | 说明 | 建议 |
|---|---|---|---|
| 删除 moment | `stday/lib/data/repositories/app_repository.dart:179-186` | `validateStatus < 500` 使 403/404 进入 unwrap，UI 可能先乐观删除 | 只接受 2xx，失败回滚 |
| 打卡状态 | `mood_report_check_in_provider.dart` | 异常被转为空状态 | 区分 loading/error/empty |
| 成长值 | `landing_growth_provider.dart` | 后端失败后本地计算 | 显示“数据暂不可用”或缓存服务端值 |
| 教师 token 过期 | `teacher_app/lib/core/api/api_client.dart` | 无 401 拦截 | 统一登出并跳登录 |

## 5. 流程闭环结论

| 用户 | 闭环程度 | 主要结论 |
|---|---:|---|
| 学生 | 约 75% | 注册、记录、AI 整理、成长展示可用；引导与删除/派生数据同步需修 |
| 教师 | 约 65% | 看班级心情与危险信号可用；档案、跟进、分享不闭环 |
| 管理员 | 约 10% | 存在 RBAC 表但无管理端与细粒度权限 |

