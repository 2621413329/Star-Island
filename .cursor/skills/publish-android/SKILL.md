---
name: publish-android
description: >-
  打包成长小岛 Android release APK，并发布到 https://lcxxingyu.fun/download。
  用户说发布安卓、打包发布安卓、更新安卓安装包、build_release_android，
  或要求把 APK 放到下载页时使用。
---

# 发布安卓安装包

用户指明发布安卓时，按下面流水线做完。不要改成别的打包参数，不要提交 git。

## 固定信息

| 项 | 值 |
|---|---|
| 本地工程 | 仓库根目录下的 `stday` |
| 版本 | `stday/pubspec.yaml` 的 `version: X.Y.Z+N`，对外版本用 `X.Y.Z` |
| 构建命令 | `flutter pub get`，然后 `flutter build apk --release --dart-define=API_BASE_URL=https://api.lcxxingyu.fun` |
| 产物 | `stday/build/app/outputs/flutter-apk/app-release.apk` |
| Flutter | 不在 PATH 时用 `C:\Users\123456\flutter\bin\flutter.bat` |
| 镜像 | `PUB_HOSTED_URL=https://pub.flutter-io.cn`，`FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn` |
| 服务器 | `root@39.106.134.222`，端口 `22` |
| 密钥 | `C:\Users\123456\Downloads\dream.pem`。只接受 `root`，不要用 `dream` |
| 前端源码 | `/home/dream/stweb/staweb` |
| 网站根目录 | `/usr/share/nginx/html/staweb`（Nginx 实际对外目录） |
| 下载页 | `https://lcxxingyu.fun/download` |
| 安装包文件名 | `星屿X.Y.Z.apk` |
| 清单名称 | `成长小岛 Android 版` |

不要直接运行 `stday/build_release_android.bat`。它末尾有 `pause`，会一直等待按键。执行与它相同的两条 Flutter 命令即可。

服务器没有 Node.js。不要执行 `npm install`、`npm run build`，也不要运行 `update.sh`（脚本无效，且路径指向不存在的 `/root/stweb`）。下载页运行时读取 `/downloads/manifest.json`，换包和清单就会生效。

## 1. 打包

在 `stday` 目录设置上面的两个镜像环境变量后构建。`pub.dev` 直连会卡住；卡住就停掉进程，带镜像重来。

记下产物字节数，后面用来核对上传结果。

## 2. 准备密钥

Windows 自带 OpenSSH 不能加载 `BEGIN RSA PRIVATE KEY`。先转换成 OpenSSH 格式：

```bash
python scripts/prepare_ssh_key.py "C:\Users\123456\Downloads\dream.pem" "%TEMP%\star-island-deploy\id_openssh"
```

然后收紧 ACL，只保留当前用户读取：

```powershell
icacls $out /inheritance:r
icacls $out /grant:r "${env:USERNAME}:(R)"
```

连接：

```bash
ssh -i <转换后的密钥> -p 22 -o IdentitiesOnly=yes -o BatchMode=yes root@39.106.134.222
```

详细输出里身份文件必须是 `type 0`。发布结束后删除转换出的密钥文件，不要把密钥内容写进回复、日志或仓库。

## 3. 上传并发布

PowerShell 传给 `ssh` 的远程命令会丢掉双引号。不要在远程命令里写带引号的脚本。把本技能的 `scripts/publish_apk.py` 和 APK 用 `scp` 上传，再执行不带嵌套引号的命令。

```bash
scp -i <密钥> -P 22 -o IdentitiesOnly=yes app-release.apk root@39.106.134.222:/tmp/xingyu.apk
scp -i <密钥> -P 22 -o IdentitiesOnly=yes scripts/publish_apk.py root@39.106.134.222:/tmp/publish_apk.py
ssh -i <密钥> -p 22 -o IdentitiesOnly=yes -o BatchMode=yes root@39.106.134.222 python3 /tmp/publish_apk.py /tmp/xingyu.apk X.Y.Z <本地字节数>
```

脚本会把安装包、`downloads.config.json`、`manifest.json` 写到这三处，并删除这些目录里的其它 `.apk`：

- `/home/dream/stweb/staweb/public/downloads`（属主 `dream:dream`）
- `/home/dream/stweb/staweb/dist/downloads`（属主 `dream:dream`）
- `/usr/share/nginx/html/staweb/downloads`（属主 `nginx:nginx`）

字节数不一致时脚本会失败，不要继续对外宣称已发布。成功后删除 `/tmp/publish_apk.py`。

## 4. 验收

全部满足才算完成：

1. `https://lcxxingyu.fun/downloads/manifest.json` 的 `version`、`filename`、`sizeBytes` 与本次构建一致。
2. `https://lcxxingyu.fun/downloads/星屿X.Y.Z.apk` 返回 200，`Content-Length` 等于本地 APK 字节数。
3. 打开 `https://lcxxingyu.fun/download`，页面显示 `vX.Y.Z`，下载链接指向该 APK。

回复用户时说明版本、下载页地址，以及页面上看到的版本和文件名。
