# Finder Forge

[English README](./README.en.md)

Finder Forge 用于在 macOS 上安装 Finder 快捷操作 / 服务：

- `New Text File Here`
- `Open in Qoder`
- `Open in Cursor`
- `Open in Code`

这些能力由 Automator `.workflow` 包和共享 shell 脚本实现。安装时会把工作流复制到 `~/Library/Services`，并把辅助脚本复制到 `~/Library/Application Support/FinderForge/helpers`。

![](https://img.alicdn.com/imgextra/i2/O1CN01o3mRJN1CCexUl2EOz_!!6000000000045-2-tps-1136-1272.png)

## 功能说明

- `New Text File Here` 会在当前 Finder 文件夹里创建 `untitled.txt`。
- 如果 `untitled.txt` 已存在，会继续创建 `untitled 2.txt`、`untitled 3.txt`，依次递增。
- 如果只选中了一个文件夹，新文件会创建在这个文件夹里。
- `New Text File Here` 只显示在文件夹场景，不显示在文件场景。
- 新文件创建后会在 Finder 中高亮并选中；如果已授予辅助功能权限，Finder 会尽量直接进入文件名编辑状态。
- 编辑器动作会用指定编辑器打开当前选中的文件或文件夹。
- 如果没有选中任何内容，编辑器动作会打开当前 Finder 文件夹，或者回退到桌面。

## 安装

如果希望通过一行命令安装，并弹出 `Install / Uninstall` 选择：

```sh
curl -fsSL https://raw.githubusercontent.com/linkary/finder-forge/main/bootstrap.sh | bash
```

如果需要无交互执行：

```sh
curl -fsSL https://raw.githubusercontent.com/linkary/finder-forge/main/bootstrap.sh | bash -s -- install
curl -fsSL https://raw.githubusercontent.com/linkary/finder-forge/main/bootstrap.sh | bash -s -- uninstall
```

`bootstrap.sh` 可以直接由 `bash` 执行；它内部会调用 macOS 自带的 `/bin/zsh` 来运行实际安装脚本，因此用户无需额外安装 zsh。

如果是在本地仓库中执行，也可以直接运行：

```sh
./install.sh
```

安装器会：

- 把辅助脚本复制到 `~/Library/Application Support/FinderForge/helpers`
- 始终安装 `New Text File Here`
- 只在本机检测到对应编辑器时安装相关工作流
- 复制完整的 workflow bundle，保留多语言菜单资源
- 重写 workflow 中的脚本路径，使其指向已安装的辅助脚本
- 重建 Finder Forge 管理的 helper 目录，并清理旧版本遗留的受管文件
- 通知 macOS 重新扫描 Services

如果要卸载 Finder Forge 安装的所有内容：

```sh
./install.sh uninstall
```

上面的 `bootstrap.sh` 也支持通过 `uninstall` 动作完成卸载。

重复执行 `install` 是受支持的升级路径。重新安装会刷新 workflow 与 helper，并移除 Finder Forge 管理范围内的旧文件残留。

## 配置

编辑器路径定义在 [helpers/editor_config.sh](/Users/linkary/Codes/Labs/finder-forge/helpers/editor_config.sh)。

当前默认值：

- `Qoder`: `/Applications/Qoder.app`
- `Cursor`: `/Applications/Cursor.app`
- `Visual Studio Code`: `/Applications/Visual Studio Code.app`

如果某个编辑器被移动了位置，请更新 [helpers/editor_config.sh](/Users/linkary/Codes/Labs/finder-forge/helpers/editor_config.sh) 后重新运行 `./install.sh`。

## 本地化

- Finder Forge 自带英文、简体中文、繁体中文的服务菜单文案。
- Finder 会根据当前 macOS 语言显示对应文案；不支持的语言会回退到英文。
- 已通过 Apple Bundle 本地化解析验证 `zh-Hans`、`zh-Hant` 与英文回退行为。

## 中文菜单验证

自动验证命令：

```sh
./scripts/test.sh
./scripts/sweep_rename_delay.sh
./scripts/sweep_rename_delay.sh --outer 0.2,0.3,0.4 --inner 0.05,0.1 --runs 2
swift scripts/verify_localizations.swift
```

手动冒烟验证：

1. 安装 Finder Forge。
2. 将 macOS 语言切换为简体中文或繁体中文，或使用对应语言的系统环境。
3. 打开 Finder，在文件夹上右键，或从“服务”菜单中查看 Finder Forge 条目。
4. 确认 `New Text File Here`、`Open in Qoder`、`Open in Cursor`、`Open in Code` 显示为对应中文菜单。

## 文件重命名体验

- `New Text File Here` 创建文件后会先在 Finder 中高亮并选中该文件。
- `New Text File Here` 会尝试让 Finder 自动进入文件名编辑状态。
- 这个动作依赖 Finder/Services 的实际时序，因此属于 best-effort 行为。
- 如果出现“短暂进入编辑态后又退出”的现象，通常是 Finder 在服务收尾阶段把编辑态打断；最新版本会避免重复发送触发键来减少这种来回切换。
- 如果要优化进入编辑态的速度，请运行 `./scripts/sweep_rename_delay.sh`。它以已安装的 workflow 为基准，不直接调用仓库内 helper，因此更贴近真实用户路径。
- 当前默认值已经根据真实 workflow sweep 收紧到更快的组合：`outer=0.2`、`inner=0.05`。

## Finder 空白区域限制

- 通用 Finder Services / Quick Actions 无法稳定地在 Finder 窗口空白区域提供顶层右键菜单项。
- 这个项目基于 Services，所以 `New Text File Here` 可以在文件夹场景出现，但不能保证作为真正的“空白处右键菜单”出现。
- 如果必须支持空白区域右键动作，实际可行的方向是 Finder Sync Extension 或第三方 Finder 扩展方案。

## 项目结构

- [helpers/finder_context.sh](/Users/linkary/Codes/Labs/finder-forge/helpers/finder_context.sh): 共享的 Finder 上下文解析和 Finder UI 辅助逻辑
- [helpers/editor_config.sh](/Users/linkary/Codes/Labs/finder-forge/helpers/editor_config.sh): 安装与启动共用的编辑器名称和路径配置
- [helpers/create_text_file.sh](/Users/linkary/Codes/Labs/finder-forge/helpers/create_text_file.sh): 新建文本文件动作
- [helpers/open_in_editor.sh](/Users/linkary/Codes/Labs/finder-forge/helpers/open_in_editor.sh): 通用编辑器启动器
- [workflows](/Users/linkary/Codes/Labs/finder-forge/workflows): 导出的 Automator workflow bundles

## 验证

常用命令：

```sh
./scripts/test.sh
./scripts/sweep_rename_delay.sh
./install.sh
./install.sh uninstall
swift scripts/verify_localizations.swift
/System/Library/CoreServices/pbs -read_bundle "$HOME/Library/Services/Open in Cursor.workflow"
```
