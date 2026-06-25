# AI 感受表情图片资源

本目录存放 **AI 感受** 对应的表情 PNG（用户唯一可见的心情体系）。

## 占位图

- `_placeholder.png` — 任意感受缺失时的通用占位

## 需要替换的文件

| 感受 ID | 中文名 | 通用图 | 男生图 | 女生图 |
|---------|--------|--------|--------|--------|
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

## 小人全身立绘（岛屿 / 卡片）

目录：`stday/assets/images/companion/base/`

命名与 [mood_faces] 感受 id 一致：`{gender}_{感受拼音 id}.png`（`gender` 为 `male` / `female`）。

| 感受 ID | 中文名 | 男生图 | 女生图 |
|---------|--------|--------|--------|
| `kai_xin` | 开心 | `male_kai_xin.png` | `female_kai_xin.png` |
| `ping_jing` | 平静 | `male_ping_jing.png` | `female_ping_jing.png` |
| `jiao_lv` | 焦虑 | `male_jiao_lv.png` | `female_jiao_lv.png` |
| `ya_li` | 压力 | `male_ya_li.png` | `female_ya_li.png` |
| `xing_fen` | 兴奋 | `male_xing_fen.png` | `female_xing_fen.png` |
| `gan_dong` | 感动 | `male_gan_dong.png` | `female_gan_dong.png` |
| `shi_luo` | 失落 | `male_shi_luo.png` | `female_shi_luo.png` |
| `fen_nu` | 愤怒 | `male_fen_nu.png` | `female_fen_nu.png` |
| `zi_wo_jue_cha` | 自我觉察 | `male_zi_wo_jue_cha.png` | `female_zi_wo_jue_cha.png` |
| `shen_ti_guan_huai` | 身体关怀 | `male_shen_ti_guan_huai.png` | `female_shen_ti_guan_huai.png` |
| `_placeholder` | 占位 | `male__placeholder.png` | `female__placeholder.png` |

旧英文文件名（`happy`/`calm` 等）已由代码层映射到上表拼音 id，替换资源时只需按拼音命名即可。

## 规格建议

- 尺寸：800×800 或等比正方形，透明背景 PNG
- 命名必须小写，与上表 ID 完全一致
