# 心情 / 小人表情图片资源

本目录存放**心情表情** PNG。扩展后包含五档手动心情 + AI 感受对应资源。

## 占位图

未提供正式素材时，程序会使用矢量绘制兜底；也可放置统一占位图：

- `_placeholder.png` — 通用占位（任意心情缺失时可选回退）

## 需要替换的文件

### 1. 心情表情（五档手动选择）

| 心情 ID | 中文名 | 通用图 | 男生图 | 女生图 |
|---------|--------|--------|--------|--------|
| `happy` | 超开心 | `happy.png` | `man_happy.png` | `woman_happy.png` |
| `calm` | 开心 | `calm.png` | `man_calm.png` | `woman_calm.png` |
| `thinking` | 平静 | `thinking.png` | `man_thinking.png` | `woman_thinking.png` |
| `sad` | 低落 | `sad.png` | `man_sad.png` | `woman_sad.png` |
| `angry` | 生气 | `angry.png` | `man_angry.png` | `woman_angry.png` |

### 2. AI 感受扩展心情

| 心情 ID | AI 感受 | 通用图 | 男生图 | 女生图 |
|---------|---------|--------|--------|--------|
| `kai_xin` | 开心 | `kai_xin.png` | `man_kai_xin.png` | `woman_kai_xin.png` |
| `ping_jing` | 平静 | `ping_jing.png` | `man_ping_jing.png` | `woman_ping_jing.png` |
| `jiao_lv` | 焦虑 | `jiao_lv.png` | `man_jiao_lv.png` | `woman_jiao_lv.png` |
| `ya_li` | 压力 | `ya_li.png` | `man_ya_li.png` | `woman_ya_li.png` |
| `xing_fen` | 兴奋 | `xing_fen.png` | `man_xing_fen.png` | `woman_xing_fen.png` |
| `gan_dong` | 感动 | `gan_dong.png` | `man_gan_dong.png` | `woman_gan_dong.png` |
| `shi_luo` | 失落 | `shi_luo.png` | `man_shi_luo.png` | `woman_shi_luo.png` |
| `fen_nu` | 愤怒 | `fen_nu.png` | `man_fen_nu.png` | `woman_fen_nu.png` |
| `zi_wo_jue_cha` | 自我觉察 | `zi_wo_jue_cha.png` | `man_zi_wo_jue_cha.png` | `woman_zi_wo_jue_cha.png` |
| `shen_ti_guan_huai` | 身体关怀 | `shen_ti_guan_huai.png` | `man_shen_ti_guan_huai.png` | `woman_shen_ti_guan_huai.png` |

目录：`stday/assets/images/mood_faces/`

## 小人基底表情（岛屿 / 卡片）

目录：`stday/assets/images/companion/base/`

| 表情 ID | 男生 | 女生 |
|---------|------|------|
| `happy` | `male_happy.png` | `female_happy.png` |
| `calm` | `male_calm.png` | `female_calm.png` |
| `thinking` | `male_thinking.png` | `female_thinking.png` |
| `sad` | `male_sad.png` | `female_sad.png` |
| `angry` | `male_angry.png` | `female_angry.png` |
| `hopeful` | `male_hopeful.png` | `female_hopeful.png` |
| `proud` | `male_proud.png` | `female_proud.png` |
| `hurt` | `male_hurt.png` | `female_hurt.png` |
| `expecting` | `male_expecting.png` | `female_expecting.png` |
| 占位 | `male_placeholder.png` | `female_placeholder.png` |

AI 感受会映射到上述表情 ID 显示小人，例如「感动」→ `hopeful`，「身体关怀」→ `hopeful`。

## 规格建议

- 尺寸：800×800 或等比正方形，透明背景 PNG
- 命名必须小写，与上表 ID 完全一致
