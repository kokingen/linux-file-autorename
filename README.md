# linux-file-autorename

让 Linux Mint 的文件管理器 **Caja**（MATE）和 **Nemo**（Cinnamon，含桌面）在复制/移动遇到重名时**不再弹窗**，像 Windows / macOS 那样自动处理：

| 情况 | 原版行为 | 打补丁后 |
|---|---|---|
| 同名文件 | 弹窗问“替换 / 跳过 / 重命名” | 两个都保留，新的自动命名为 `报告（副本）.pdf`、`报告（另一个副本）.pdf`… |
| 同名文件夹 | 弹窗问“合并 / 跳过” | 自动合并，里面重名的文件同样自动改名 |
| 旧文件 | 选错就被覆盖 | **永远不会被覆盖或删除** |

适用于：拖拽、Ctrl+C / Ctrl+V、拖到桌面、剪切移动、跨分区/U 盘复制。

## 已测试环境

- Linux Mint 22.3（Ubuntu 24.04 底座）
- Caja `1.26.3+mint1`，Nemo `6.6.3+zena`
- 自动测试 35 项（复制、移动、批量 300 个文件、多层文件夹合并、跨文件系统、中文/点号文件名等），Caja 与 Nemo 各连续 3 轮全部通过
- 真机图形界面手动验证：拖拽文件、拖拽文件夹、连续粘贴、拖到桌面

## 安装

### 方式一：直接装编译好的 deb（推荐）

从 GitHub Releases 下载 8 个 deb 放进 `release/` 目录，然后一键安装（会同时锁定版本，防止系统更新覆盖）：

```bash
./scripts/install.sh release
```

或者手动安装：

```bash
sudo apt install ./caja_*autorename*.deb ./caja-common_*autorename*.deb \
  ./libcaja-extension1_*autorename*.deb ./gir1.2-caja-2.0_*autorename*.deb
sudo apt install ./nemo_*autorename*.deb ./nemo-data_*autorename*.deb \
  ./libnemo-extension1_*autorename*.deb ./gir1.2-nemo-3.0_*autorename*.deb
caja -q; nemo -q; nohup nemo-desktop >/dev/null 2>&1 &
```

### 方式二：自己从源码编译

```bash
./scripts/build.sh caja     # 或 nemo，或 all
./scripts/install.sh        # 安装 build/ 里生成的 deb
```

`build.sh` 会自动启用源码仓库、安装编译依赖、下载官方源码、打补丁、编译成 deb。

## 临时关闭 / 卸载

- 临时恢复原来的弹窗：启动时加环境变量 `CAJA_NO_AUTORENAME=1` 或 `NEMO_NO_AUTORENAME=1`
- 彻底回到官方版：`./scripts/uninstall.sh`

为防止系统更新把补丁版覆盖回去，`install.sh` 会用 `apt-mark hold` 锁定这几个包；`uninstall.sh` 会解锁。官方出新版本后，重新运行 `build.sh` 即可。

## 原理

补丁只改了一个文件：`caja-file-operations.c` / `nemo-file-operations.c`。

在原本弹出冲突对话框的地方（复制路径 `copy_move_file` 与同分区移动路径 `move_file_prepare`）：

- 目标是同名**文件**：调用文件管理器自带的 `get_unique_target_file()` 生成“（副本）”名字后重试，不覆盖；
- 目标和源都是**文件夹**：等同于用户点了“合并”；
- 额外保险：如果在“合并”模式下 GIO 意外要求删除目标（`WOULD_RECURSE` / `IS_DIRECTORY`），补丁会改为生成新名字，**绝不删除已有内容**。

命名规则和语言跟随系统（中文显示“副本”，英文显示 “copy”）。

## 测试

`tests/` 里是自动测试：一个调用文件管理器内部复制函数的小程序（`test-ar.c` / `test-nemo.c`）加 Bash 测试脚本。需要在已编译好的源码树里构建，并有图形会话（`DISPLAY=:0`）。

```bash
./tests/suite.sh ./test-ar        # Caja
./tests/suite-nemo.sh ./test-nemo # Nemo
```

## 许可

与 Caja、Nemo 相同，GPL-2.0-or-later。

---

**English:** Patches for Caja and Nemo (Linux Mint) that resolve copy/move name conflicts automatically, without a dialog: files are kept side by side with a localized "(copy)" suffix, same-named folders are merged, and existing files are never overwritten or deleted. Set `CAJA_NO_AUTORENAME=1` / `NEMO_NO_AUTORENAME=1` to get the original dialog back.
