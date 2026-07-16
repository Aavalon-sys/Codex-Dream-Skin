# 灰泽满 Hazel × Codex 主题

个人本机使用的 macOS Codex Desktop 主题。它以应援灰 `#D3D3D3` 为基底、以“绿冻”色 `#5C968E` 为交互强调色，使用官方动态中的灰泽满立绘，并保留 Codex 的原生侧栏、项目选择器、建议卡片、任务内容和输入框。

主题基于 Codex Dream Skin Studio 的本地回环 CDP 注入方案，不修改 `Codex.app`、`app.asar` 或应用签名。

## 安装

双击 `install-hazel.command`。安装器会：

1. 验证官方 Codex 应用、签名及其内置 Node.js。
2. 备份已有 Dream Skin 引擎和主题。
3. 安装到 `~/.codex/codex-dream-skin-studio`。
4. 将 Hazel 主题写入 `~/Library/Application Support/CodexDreamSkinStudio/theme`。
5. 若 Codex 已在运行，通过系统对话框询问是否重启后应用。

也可以只安装、不启动：

```bash
./scripts/install-dream-skin-macos.sh --no-launch
```

桌面会生成：

- `Hazel Codex Theme.command`：启动或重新应用主题。
- `Hazel Codex Theme - Verify.command`：检查注入状态并保存验收截图。
- `Hazel Codex Theme - Restore.command`：恢复官方外观并正常重启 Codex。

## manqu 宠物

主题不打包或替换 manqu。装饰层均不可点击，并在窗口底部保留 180px 的无主题装饰活动带；manqu 仍由 Codex 的 Pets 设置独立启用。

## 卸载和恢复

双击 `uninstall-hazel.command`。如果主题当前通过已验证的本地 CDP 端点运行，它会在不关闭 Codex 的情况下移除注入；如果无法安全验证运行中的 Codex，脚本会停止并要求显式重启授权。

完整恢复入口：

```bash
./scripts/restore-dream-skin-macos.sh --restore-base-theme --restart-codex --uninstall
```

## 开发与打包

```bash
npm test
./scripts/build-client-release.sh "/path/to/灰泽满-Hazel-Codex-macOS.zip"
```

颜色、语录和图片出处见 [references/asset-sources.md](references/asset-sources.md)。角色素材只用于个人本机主题，不应随源码公开再分发或用于商业用途。

本项目为非官方个性化工具，与 OpenAI、灰泽满或 VirtuaReal 无隶属、赞助或背书关系。
