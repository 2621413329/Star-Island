# MVP上线风险评估报告

审计对象：学生成长观察 / 心情岛屿 / 教师预警系统 MVP。

## 1. MVP完成度评估

| 维度 | 完成度 | 判断依据 |
|---|---:|---|
| 产品完成度 | 68% | 学生每日记录、AI报告、成长岛、教师风险主链路已具备；教师分享、档案时间轴、通用跟进缺失 |
| 技术完成度 | 62% | 前后端主链路可跑；权限边界、配置安全、AI可追溯、档案聚合存在明显缺陷 |
| 测试完成度 | 20% | 后端只有少量单元/未认证冒烟；Flutter 学生端测试仍是模板；无权限/DB/教师端集成测试 |
| 可上线程度 | 45% | 若面向真实学校/未成年人数据，P0 权限和合规问题阻断上线；可用于内部假数据演示 |

## 2. 上线结论

当前版本不建议直接进入真实学生数据试点。  
可以进行“内部演示/假数据体验”，但真实学校试点前必须完成 P0 修复，尤其是：

1. 学生/观察/故事接口水平越权。
2. 岛屿样式、规则、通用 AI 接口权限过宽。
3. 教师注册默认密钥和 JWT 默认密钥风险。
4. 教师端敏感学生备注原文暴露口径不一致。
5. 成长档案 `timeline/risk_exposures/follow_ups` 空返回。
6. 生产 HTTPS、docs、CORS、health check 配置。

## 3. P0 上线阻断问题

| 编号 | 问题 | 位置 | 风险等级 | 修复建议 | 是否影响上线 |
|---|---|---|---|---|---|
| P0-01 | 任意登录用户可 CRUD/list 学生 | `backend/app/api/v1/endpoints/students.py:15-45` | 严重 | 按角色和资源归属过滤；学生只能自己，教师只能本班，管理员全局 | 是 |
| P0-02 | 任意登录用户可读写观察记录 | `backend/app/api/v1/endpoints/observations.py:20-51` | 严重 | 加 student ownership/class check | 是 |
| P0-03 | 故事/时间线可按 `student_id` 枚举 | `backend/app/api/v1/endpoints/stories.py:34-99` | 严重 | 所有 story/timeline 查询加归属校验 | 是 |
| P0-04 | 全局岛屿样式可被普通用户修改 | `backend/app/api/v1/endpoints/island_styles.py:28-45` | 严重 | PATCH admin-only 或移除 | 是 |
| P0-05 | 规则系统可被普通用户写入 | `backend/app/api/v1/endpoints/rules.py:15-36` | 高 | admin-only | 是 |
| P0-06 | 通用 AI/T2I/I2V 对普通用户开放 | `backend/app/api/v1/endpoints/ai.py:18-40` | 高 | 限流、配额、角色/内部接口隔离 | 是 |
| P0-07 | 教师注册密钥默认 `root` | `backend/app/core/config.py:28` | 高 | 生产启动校验非默认强密钥 | 是 |
| P0-08 | JWT 弱默认模板 | `backend/.env.example:21` | 高 | 去掉可猜默认，生产启动校验 | 是 |
| P0-09 | 教师成长档案关键数据空返回 | `backend/app/services/growth_archive_service.py:58-75` | 高 | 接入 `_build_timeline`、`_risk_exposures`、`follow_up_repo` | 是 |
| P0-10 | 教师端展示学生备注原文且文案称不含原文 | `backend/app/services/moment_story_service.py:14-16` | 高 | 列表脱敏，详情审计，更新告知文案 | 是 |
| P0-11 | 生产 HTTP 明文 | 部署文档/脚本 | 高 | Nginx/HTTPS，客户端 API_BASE_URL 使用 https | 是 |
| P0-12 | 无权限回归测试 | `backend/app/tests` | 高 | 补学生越权、教师跨班、admin 权限测试 | 是 |

## 4. P1 建议修复问题

| 编号 | 问题 | 位置 | 影响 | 建议 |
|---|---|---|---|---|
| P1-01 | 学生端使用 `/auth/login`，不触发班级同步 | `stday/lib/data/repositories/app_repository.dart:28-39` | 转班后教师视图可能不准 | 改用 `/auth/student-login` |
| P1-02 | 删除 moment 后报告不自动重算 | `daily_moments` -> `daily_mood_reports` | 教师统计和风险过期 | 删除后标记报告 stale 或自动重算 |
| P1-03 | 删除 moment 4xx 可能被当成功 | `app_repository.dart:179-186` | UI 假成功 | 只接受 2xx，失败回滚 |
| P1-04 | AI 心情报告不可复现 | `daily_mood_reports` | 争议无法追溯 | 新增 AI run 表或字段 |
| P1-05 | 教师通用跟进 UI 缺失 | `teacher_repository.dart:119-130` | 跟进闭环不足 | 档案页加跟进表单 |
| P1-06 | 教师分享零实现 | `teacher_app` + backend | 产品目标缺失 | 明确是否纳入 MVP；若纳入则设计接口/权限/水印 |
| P1-07 | Flutter 401 无统一处理 | `api_client.dart` | token 过期体验差 | Dio interceptor |
| P1-08 | `/health` 不检查 DB | `backend/app/main.py:26-28` | 监控误判 | 增加 DB `SELECT 1` |
| P1-09 | `/docs` 生产常开 | `backend/app/main.py:12` | 攻击面增加 | DEBUG=false 时关闭或认证 |
| P1-10 | CORS 只在 DEBUG 启用 | `backend/app/main.py:13-20` | Web 版生产不可用 | 增加 `CORS_ORIGINS` |
| P1-11 | 双岛屿体系 | `stday/lib/design_system`、`stday/lib/world` | 体验割裂 | 统一使用 world 引擎 |
| P1-12 | 班级/情绪/成长分类多端硬编码 | 两个 Flutter app + backend | 数据漂移 | 后端下发配置或 shared package |

## 5. P2 可延期优化

| 编号 | 问题 | 建议 |
|---|---|---|
| P2-01 | Docker 缺失 | 后续补容器化，提升部署一致性 |
| P2-02 | CI 缺失 | 先补基础 CI，后续加 Flutter integration |
| P2-03 | 旧 CompanionPage / 旧 story card | 清理死代码 |
| P2-04 | `teacher/alerts` 旧接口 | 若不再使用，归档或删除 |
| P2-05 | Runtime API_BASE_URL | 移动端可后续引入远程配置 |
| P2-06 | 组织/学校维度 | 学校试点扩大后增加 school/org model |

## 6. 产品功能矩阵

| 功能 | 状态 | 完成度 | 风险等级 | 上线建议 |
|---|---|---:|---|---|
| 学生注册/登录 | 可用 | 80% | 中 | 改学生专用登录 |
| 每日心情记录 | 可用 | 90% | 中 | 修删除语义与派生数据 |
| AI成长分析 | 可用但不可追溯 | 75% | 高 | 上线前补 AI run |
| 成长轨迹展示 | 部分可用 | 65% | 高 | 修教师档案 timeline |
| 教师风险预警 | 可用 | 80% | 高 | 修敏感原文、审计日志 |
| 教师成长分享 | 未实现 | 0% | 中 | MVP 范围需明确 |
| 学生成长档案 | 部分可用 | 70% | 高 | 修 follow-ups/risk_exposures |
| 岛屿成长系统 | 可用 | 80% | 高 | 锁定 PATCH 权限 |
| 数据统计分析 | 部分可用 | 70% | 中 | 对齐 category filter |
| 权限与合规 | 不足 | 45% | 严重 | P0 阻断 |
| 运维部署 | 手工可用 | 55% | 高 | HTTPS/health/docs/CORS |
| 测试质量 | 不足 | 20% | 高 | 补权限与 DB 测试 |

## 7. 教育试点准入建议

### 7.1 可进入内部演示的条件

- 使用假学生数据。
- 后端不暴露公网或只限白名单。
- 禁用或保护 `/ai/text-to-image`、`/rules`、`/students` 等高风险接口。
- 教师注册密钥改为强密钥。

### 7.2 可进入小范围学校试点的条件

- P0 全部修复。
- 加入访问审计：教师查看风险详情、导出/分享、撤销风险。
- AI 分析可追溯：保存输入摘要、模型、prompt 版本、raw response 或 hash。
- 隐私告知与教师端文案一致。
- HTTPS 与生产密钥校验。
- 至少覆盖以下自动化测试：
  - 学生不能访问其他学生资料。
  - 教师不能访问跨班学生。
  - 普通用户不能改规则/岛屿样式。
  - 删除 moment 后报告状态正确。
  - 风险 dismiss 后教师列表同步。

## 8. 修复路线建议

### 第一组：安全上线门禁

1. 增加角色/资源依赖并修复 P0-01 到 P0-06。
2. 生产配置强校验：密钥、DB、DEBUG、HTTPS。
3. 敏感原文脱敏与访问审计。

### 第二组：业务闭环

1. 修复 `growth_archive_service.get_archive` 空字段。
2. 接通教师 follow-ups UI。
3. 决定教师分享是否进入 MVP；若不进入，产品目标中标注延期。

### 第三组：测试和运维

1. 建测试数据库 fixture。
2. 增加权限回归测试。
3. 增加 CI。
4. 完善 health check 和生产 docs/CORS 配置。

## 9. 最终判断

当前系统具备 MVP 的主要产品雏形，但尚未达到真实未成年人数据上线标准。阻断因素不是功能页面数量，而是权限边界、敏感数据治理、AI 可追溯和成长档案闭环。完成 P0 后，可进入受控小范围试点；完成 P1 后，才适合扩大到学校教师日常使用。

