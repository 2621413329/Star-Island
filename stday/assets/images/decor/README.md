# 岛屿装饰图片资源

本目录存放岛屿装饰系统使用的 PNG 资源，由 `lib/island/decor/decor_config.dart` 引用。

## 必需文件（32 项）

```
grass_01.png ~ grass_03.png
flower_01.png ~ flower_03.png
stone_01.png ~ stone_02.png
bush_01.png ~ bush_02.png
tree_small_01.png ~ tree_small_03.png
mushroom_01.png, wood_01.png
butterfly_01.png
tree_large_01.png, tree_large_02.png
cloud_01.png ~ cloud_04.png
flower_field_01.png
bird_01.png ~ bird_03.png
pond_01.png
firefly_01.png
rare_flower_01.png
rainbow_cloud_01.png
seagull_group_01.png
life_tree_01.png
```

## 规格建议（小草 PNG）

Lv1 即可显示的草丛贴图，推荐：

- 尺寸：800×800 px（透明底，主体居中，留足底部锚点）
- 数量：至少 `grass_01.png` ~ `grass_04.png` 四种形态
- 风格：2.5D 治愈系，底部对齐岛面，避免整图铺满画布
- 导入后：Lv1 会自动出现 6 簇随风摆动的小草（`grass_sway` 动画）

若仅有程序绘制小草（无 PNG），岛面仍会通过 Canvas 绘制 **全岛草坪底**（细密小草随风摆动），作为装饰层下方的地面纹理；后续解锁的 PNG 装饰（花朵、树木、建筑等）会叠在草坪之上，互不影响。

在仓库根目录执行（Windows）：

```bat
scripts\sync_decor_from_local.bat
```

或指定源目录：

```powershell
.\scripts\sync_decor_from_local.ps1 -SourceDir "D:\tradition\med\mobile\build\app\outputs\apk\release\2"
```

同步后提交：

```bash
git add stday/assets/images/decor/
git commit -m "assets: 更新岛屿装饰 PNG 素材"
git push
```

## Cloud Agent 导入

若使用 Cursor Cloud Agent，请将素材文件夹拖入工作区 `stday/assets/images/decor_import/`，然后告知 Agent 执行替换。
