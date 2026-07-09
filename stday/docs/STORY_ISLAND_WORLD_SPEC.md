# Star Island 副岛世界观与岛屿生成规范

> **范围**：仅影响副岛（故事岛）显示与资产，**不改变主岛**渲染与成长逻辑。

## 一、整体世界观

这是一个以长期成长、陪伴、记录人生为核心的岛屿养成世界。

每一个标签对应一座独立的小岛，每座岛屿代表人生的一个重要维度。

用户每天完成对应标签的一条记录，即累计一天成长值。

岛屿会随着累计天数不断建设，最终形成完整的小镇，而不是简单摆放建筑。

整个世界强调：**温暖 · 治愈 · 长期陪伴 · 手绘游戏感 · 真实生活气息**。

**禁止**：AI 科技感、赛博朋克、高楼大厦、现代商业城市、金属未来建筑、HDR 照片风、复杂噪点。

## 二、统一美术风格

所有建筑全部遵循：

```
isometric 45-degree view, hand-painted mobile game art style, low saturation color palette, soft natural lighting, matte materials (wood, stone, brick), painterly texture, clean silhouette, believable proportions, cozy environment, no futuristic elements, mobile game asset
```

代码常量：`StoryIslandBuildingCatalog.artStylePrompt`（Dart）/ `story_island_buildings.py` 注释（Python）。

## 三、岛屿整体显示方式

- 每一个标签对应一座**独立圆形岛屿**
- 不是漂浮岩石，而是：**圆形草坪岛 + 四周环绕河流 + 圆润边缘 + 少量树木 + 小路 + 留白**
- **45° Isometric View**，参考 Animal Crossing / Stardew Valley / Cozy Grove

### 建筑布局（由外到内）

```
          Lv10
     Lv8       Lv9
     Lv6       Lv7
     Lv4       Lv5
 Lv2    Lv1    Lv3
```

随等级提高，建筑越来越靠近中心，最终形成完整聚落。

实现位置：`StoryIslandWorldBuilder._buildingAnchor` / `island_home_page.dart` 同名锚点。

## 四、建筑成长规则

- 每座岛固定 **10 级**建筑
- 用户每天记录一次累计成长；达到阈值解锁下一级
- Lv1 外圈最小 → Lv10 中心最大地标
- 渐进建设，非一次性堆满

## 五、标签与建筑清单

| category_id | 标签 | Lv1 → Lv10 建筑（外圈→中心） |
|-------------|------|------------------------------|
| work | 工作 | 工作角 → … → 公司总部 |
| study | 学习 | 学习角 → … → 大学主教学楼 |
| health | 健康 | 健康角 → … → 自然疗愈中心 |
| social | 人际 | 友谊长椅 → … → 社区会堂 |
| life | 生活 | 生活角 → … → 温馨生活之家 |
| finance | 财富 | 收获角 → … → 商会大厅 |
| milestone | 重要事件 | 回忆角 → … → 回忆纪念馆 |
| inspiration | 灵感 | 灵感角 → … → 创意殿堂 |
| creation | 创造 | 创作角 → … → 创造工坊 |
| emotion | 情感 | 暖心角 → … → 心灵花园 |
| achievement | 成就 | 起点纪念角 → … → 荣耀殿堂 |

完整名称见：

- 后端：`backend/app/config/story_island_buildings.py`
- 前端：`stday/lib/core/constants/story_island_building_catalog.dart`

## 六、资产规范

路径：`assets/images/islands/<category_id>/buildings/lv01.png` … `lv10.png`

- 推荐尺寸：512×512 px，透明背景
- Lv1 对应 `lv01.png`（外圈最小建筑）
- Lv10 对应 `lv10.png`（中心地标）
- 缺失时回退程序生成的默认建筑

## 七、整体目标

整个 Star Island 不应呈现为多个孤立建筑，而应随成长逐渐演变成**有生命力的小型主题社区**。

每座岛屿应具备：清晰主题、由简到繁的成长过程、道路/树木/花草自然融合、统一手绘治愈风格与鲜明主题差异。

---

*与产品文档同步；修改建筑名时请同时更新 Python 与 Dart 两份 catalog。*
