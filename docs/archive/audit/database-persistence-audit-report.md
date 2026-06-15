# 数据库落库审计报告

审计目标：验证核心业务数据是否从页面提交后经过接口、Service、Repository 最终落库，并检查字段丢失、覆盖、孤儿数据和派生数据同步问题。

## 1. 数据库结构概览

| 业务域 | 表 | ORM 文件 | 用途 |
|---|---|---|---|
| 账号 | `users` | `backend/app/models/user.py` | 学生/教师账号 |
| 权限 | `roles`、`permissions`、`user_roles`、`role_permissions` | `models/rbac.py` | 教师角色、预留权限 |
| 学生 | `students` | `models/student.py` | 学生档案、班级 |
| 用户画像 | `user_profiles` | `models/profile.py` | 用户与学生绑定、性别、今日心情、伙伴 |
| 每日记录 | `daily_moments` | `models/profile.py` | 每日心情/事件/note/AI 小人演出 |
| 心情报告 | `daily_mood_reports` | `models/daily_mood_report.py` | AI 成长分析、风险、教师统计 |
| 观察记录 | `observation_records` | `models/observation.py` | 旧成长观察记录 |
| 故事 | `stories`、`story_generation_runs` | `models/story.py` | 旧 AI 故事生成及可追溯 run |
| 规则 | `story_rules`、`story_templates` | `models/rule.py` | 旧故事规则/模板 |
| 教师关注 | `teacher_alert_instances` | `models/teacher_alert.py` | 旧成长关注/预警实例 |
| 教师跟进 | `teacher_follow_ups` | `models/teacher_follow_up.py` | 通用跟进记录 |
| 危险跟进 | `teacher_risk_moment_follows` | `models/teacher_risk_moment_follow.py` | 危险信号状态与 note |
| 岛屿样式 | `mood_island_styles` | `models/mood_island.py` | 全局心情岛屿配置 |

## 2. 页面 -> 接口 -> Service -> 数据库链路

| 功能 | 页面 | 接口 | Service/Repository | 数据库 | 状态 |
|---|---|---|---|---|---|
| 学生注册 | `stday/lib/features/auth/register_page.dart` | `POST /api/v1/auth/student-register` | `AuthService.student_register` | `users`、`students`、`user_profiles` | 正常 |
| 学生登录 | `AuthPage` | `POST /api/v1/auth/login` | `AuthService.login` | 仅读 `users` | 异常：未走 `student-login`，不会同步班级 |
| 选性别 | `GenderPage` | `PATCH /api/v1/profile/gender` | `ProfileService.update_gender` | `user_profiles.gender`、`students.gender` | 正常但跳过伙伴选择 |
| 选伙伴 | `CompanionPage` | `PATCH /profile/companion` | `ProfileService.update_companion` | `user_profiles.companion_style` | 页面可达性异常 |
| 今日心情 | `MoodTodayCard`/每日引导 | `PATCH /api/v1/profile/mood` | `ProfileService.update_mood` | `user_profiles.today_mood` | 正常 |
| 新增每日故事 | `AddMomentFlowPage` | `POST /api/v1/profile/moments` | `ProfileService.create_moment` + AI enrich | `daily_moments` | 正常 |
| 编辑每日故事 | `EditMomentSheet` | `PATCH /api/v1/profile/moments/{id}` | `ProfileService.update_moment` | `daily_moments` | 正常 |
| 删除每日故事 | 今日故事列表 | `DELETE /api/v1/profile/moments/{id}` | `ProfileService.delete_moment` | 硬删 `daily_moments` | 部分异常：派生报告不自动重算 |
| 整理今日心情 | `TodayMoodRecapBar` | `POST /api/v1/profile/mood-report/upload` | `DailyMoodReportService.generate_report` | `daily_mood_reports` upsert | 正常但可追溯不足 |
| 成长值 | `LandingPage`、`MyLevelPage` | `GET /api/v1/profile/growth-summary` | `GrowthPointsService` | 聚合 `daily_moments`、`daily_mood_reports` | 正常 |
| 岛屿样式读取 | 学生端世界 | `GET /api/v1/profile/island-styles` | `MoodIslandRepository.list_active` | `mood_island_styles` | 正常 |
| 岛屿样式修改 | 无页面 | `PATCH /api/v1/profile/island-styles/{mood_id}` | API 直接保存 | `mood_island_styles` | 异常：普通登录用户可写 |
| 教师注册 | `TeacherRegisterPage` | `POST /api/v1/auth/teacher-register` | `AuthService.teacher_register` | `users`、`user_profiles.class_name`、`user_roles` | 正常但密钥默认风险 |
| 教师今日心情 | `MoodListPage` | `GET /api/v1/teacher/mood-reports/today` | `TeacherMoodReportService` | `daily_mood_reports` + `students` | 正常 |
| 教师危险信号 | `GrowthFocusPage` | `GET /api/v1/teacher/risk-signals` | `TeacherCriticalRiskService` | `daily_moments` + `teacher_risk_moment_follows` | 正常但敏感原文暴露 |
| 标记危险已关注 | `RiskFollowSheet` | `POST /api/v1/teacher/risk-signals/{moment_id}/follow` | `TeacherCriticalRiskService.mark_followed` | `teacher_risk_moment_follows` | 正常 |
| 重新激活危险信号 | `RiskFollowActions` | `POST /api/v1/teacher/risk-signals/{moment_id}/reactivate` | `TeacherCriticalRiskService.reactivate` | `teacher_risk_moment_follows.status` | 正常 |
| 撤销危险标记 | 档案/详情页 | `POST /teacher/students/{student_id}/risk-exposures/{moment_id}/dismiss` | `GrowthRiskReviewService.dismiss_risk_exposure` | `daily_mood_reports.dismissed_risk_moment_ids` | 正常但审计字段不足 |
| 教师成长档案 | `GrowthObservationArchivePage` | `GET /teacher/students/{id}/growth-archive` | `GrowthArchiveService.get_archive` | 聚合 reports/moments | 异常：timeline/risk_exposures/follow_ups 空返回 |
| 通用跟进 | 无 UI | `POST /teacher/students/{id}/follow-ups` | `GrowthArchiveService.add_follow_up` | `teacher_follow_ups` | 接口可落库但页面断链 |
| 旧观察记录 | 无当前页面 | `/api/v1/observations` | `ObservationService` | `observation_records` | 接口可落库但权限异常 |
| 旧故事生成 | 无当前页面 | `/api/v1/story/generate` | `StoryService.generate` | `stories`、`story_generation_runs` | 接口可落库但权限异常 |

## 3. 前端提交但未落库 / 页面断链

| 功能 | 问题 | 位置 | 影响 | 优先级 |
|---|---|---|---|---|
| 教师成长分享 | 无页面、无接口、无表 | `teacher_app` 全局未发现 share 业务 | 需求未实现 | P1 |
| 教师通用跟进 | Repository 有 `createFollowUp`，UI 无入口 | `teacher_repository.dart:119-130` | 教师无法记录非危险类跟进 | P1 |
| 伙伴选择 | 页面存在但正常流程跳过 | `CompanionPage`、`GenderPage` | `companion_style` 固定默认 | P1 |
| 成长档案时间轴 | Service 有 `_build_timeline`，返回 `[]` | `growth_archive_service.py:73` | 教师无法还原轨迹 | P0 |
| 档案风险暴露列表 | Service 有 `_risk_exposures`，返回 `[]` | `growth_archive_service.py:74` | 档案页风险区缺数据 | P0 |

## 4. 落库字段丢失 / 语义丢失

| 场景 | 页面字段/服务端生成 | 实际落库 | 丢失/风险 |
|---|---|---|---|
| 心情报告 AI | 输入 moments、mood_counts、risk flags、prompt、模型、raw output | `daily_mood_reports` 保存结果字段 | 未保存 prompt/model/raw input snapshot，不能复现 |
| 撤销风险 | 教师点击 dismiss | `daily_mood_reports.dismissed_risk_moment_ids` JSONB | 未保存操作者、时间、原因，不利于教育审计 |
| 教师跟进 | `note`、`action` | `teacher_follow_ups` | UI 不显示；档案 API 返回空 |
| 学生登录班级 | `class_name` 可由专用 `student-login` 同步 | 通用 `/auth/login` 不更新学生班级 | 转班后班级隔离可能不准 |
| 删除每日故事 | 删除 `daily_moments` | 旧 `daily_mood_reports` 不自动重算 | 教师端可能看到过期风险/统计 |

## 5. 数据覆盖问题

| 数据 | 覆盖方式 | 是否合理 | 风险 |
|---|---|---|---|
| `daily_mood_reports` | `(user_id, report_date)` upsert | 合理：每日一份报告 | 需要保留历史 run 才能审计变更 |
| `user_profiles.today_mood` | 每次 PATCH 覆盖 | 合理：当前心情状态 | 与 daily_moments 的情绪记录不同步属产品语义 |
| `mood_island_styles` | PATCH 修改全局配置 | 不合理：普通用户可覆盖 | P0 |
| `teacher_risk_moment_follows` | 按 `moment_id` 唯一跟进状态 | 基本合理 | 多教师协作场景会互相覆盖状态 |

## 6. 孤儿数据与关联完整性

| 风险 | 表/字段 | 证据 | 建议 |
|---|---|---|---|
| 学生日志缺归属校验 | `observation_records.student_id` | `/observations` 只检查学生存在，不检查访问者关系 | 加学生/教师/管理员角色边界 |
| 故事可跨学生查询 | `stories.student_id` | `/story/daily?student_id=` 只要求登录 | 同上 |
| 教师 follow_up 不展示 | `teacher_follow_ups.student_id` | `get_archive` 中 `follow_ups: []` | 调用 `TeacherFollowUpRepository.list_by_student` |
| 用户 profile 与 student 班级冗余 | `user_profiles.class_name`、`students.class_name` | 教师使用 profile，学生使用 students | 明确权威源和同步策略 |

## 7. 数据关系图

```text
users
  ├── user_profiles.user_id
  │     ├── student_id -> students.id
  │     ├── today_mood / gender / companion_style
  │     └── class_name(教师班级)
  ├── daily_moments.user_id
  │     └── student_id -> students.id
  └── daily_mood_reports.user_id
        └── student_id -> students.id

students
  ├── observation_records.student_id
  ├── stories.student_id
  ├── teacher_alert_instances.student_id
  ├── teacher_follow_ups.student_id
  └── teacher_risk_moment_follows.student_id
```

## 8. 数据库审计结论

1. 学生端主链路“每日故事 -> AI 心情报告 -> 成长值/教师预警”已真实落库。
2. 教师端“危险信号 -> 标记已关注/重新激活/撤销风险”已真实落库。
3. 最大落库断点是成长档案：`timeline`、`risk_exposures`、`follow_ups` 有模型/函数/表支撑，但 API 当前返回空。
4. 最大治理风险是心情报告 AI 结果不可复现，以及删除/撤销类操作缺审计元数据。
5. 最大权限风险是旧 CRUD/故事接口能读写他人学生数据，属于上线阻断。

