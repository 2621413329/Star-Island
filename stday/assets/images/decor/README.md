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

## 从本机同步素材

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
