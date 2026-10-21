<div align="center">

# 灰泽满 Hazel · Codex 主题

给 Codex / ChatGPT 桌面端换上灰泽满的皮肤，macOS 与 Windows 都能用。<br>
以她的代表色 `#D3D3D3` 为底，绿冻色作交互强调，配官方立绘与语录。

<sub>非官方项目 · 与 OpenAI 无关 · 基于 <a href="https://github.com/Fei-Away/Codex-Dream-Skin">Codex Dream Skin</a></sub>

</div>

---

## 视觉效果如下：

Codex 首页，深色与浅色跟随应用自动切换：

<div align="center">
  <img src="docs/images/hazel/codex-home-dark.png" width="49%" alt="Codex 首页 深色">
  <img src="docs/images/hazel/codex-home-light.png" width="49%" alt="Codex 首页 浅色">
</div>

切到 ChatGPT 侧同样生效，聊天与工作模式都覆盖：

<div align="center">
  <img src="docs/images/hazel/chatgpt-chat-light.png" width="49%" alt="ChatGPT 聊天 浅色">
  <img src="docs/images/hazel/chatgpt-work-dark.png" width="49%" alt="ChatGPT 工作 深色">
</div>

---

## 一键安装

**macOS** 在终端运行：

```bash
curl -fsSL https://raw.githubusercontent.com/Aavalon-sys/Codex-Dream-Skin/main/install.sh | bash
```

会自动下载最新版并校验，装好后 Codex 带着灰泽满主题重新打开。已经在用的主题会保留。

也可以在 [Releases](https://github.com/Aavalon-sys/Codex-Dream-Skin/releases/latest) 下载 `CodexDreamSkin-vX.Y.Z.dmg` 手动安装，首次打开需要在「系统设置 → 隐私与安全性」里放行，见[安装说明](docs/install-macos.md)。

**Windows** 在 [Releases](https://github.com/Aavalon-sys/Codex-Dream-Skin/releases/latest) 下载 `CodexDreamSkin-Setup-vX.Y.Z.exe` 运行。

装好后：

| 平台 | 入口 | 作用 |
| --- | --- | --- |
| macOS | 菜单栏右上角的 Dream Skin 图标 | 启动、暂停、换主题、调背景透明度、恢复原状 |
| Windows | 开始菜单 / 桌面的 Codex Dream Skin，或托盘图标 | 同上 |

---

## 主题内容

**配色**取自角色本身：代表色 `#D3D3D3` 浅灰做基底，粉丝名「绿冻」对应的 `#5C968E` 作强调色，
点缀色来自立绘上风纪袖章的樱桃红。深色与浅色两套色板独立调过，跟随 Codex 的外观设置自动切换。

**文案**：

- 主卡片 —— 灰泽满 Hazel
- 副标题 —— 灰泽满究竟爱不爱绿冻？早就说过很爱了
- 语录 —— 又怎么了我的大绿冻……
- 标题栏 —— 🩶 灰泽满 Hazel · 绿冻工作台

这些都在 `macos/assets/theme.json` 里，改完重新应用即可，不用碰 CSS。

**界面**：Codex 首页的主卡片带立绘和 Q 版贴纸，窗口变矮时自动收缩；ChatGPT 首页、聊天、工作页右侧是半透明立绘，底部渐隐；
Windows 侧栏与内容区采用直角边框，顶部品牌字避开菜单；聊天区上下渐隐统一底色，窗口变窄时自动隐藏品牌字。

---

## 卸载

**macOS**：菜单栏图标里选「恢复原状并卸载…」，或运行

```bash
~/.codex/codex-dream-skin-studio/Restore\ Codex\ Dream\ Skin.command
```

**Windows**：在系统设置的「应用」里卸载 Codex Dream Skin，卸载前会先还原 Codex 的官方外观。

---

## 素材版权

**立绘与贴纸来自灰泽满的官方发布内容，版权归原作者与角色相关方所有，不在本项目的 MIT 许可范围内。**

本仓库的 MIT 许可只覆盖**软件代码**（脚本、CSS、注入器）。它不授予：

- 角色立绘、形象、周边图像的任何权利
- OpenAI / Codex / ChatGPT 的商标、产品名与外观
- 官方应用二进制

个人使用之外的任何再分发或商用，需要自行取得相应授权。权利方如需下架，请提 issue，会尽快处理。

详见 [`macos/NOTICE.md`](macos/NOTICE.md)。

---

## 致谢

上游项目 [Fei-Away/Codex-Dream-Skin](https://github.com/Fei-Away/Codex-Dream-Skin)
——注入器、安装流程、主题契约都出自那里，这个 fork 只是在它之上做了一套灰泽满配色与版式。

角色：**灰泽满 Hazel**（VirtuaReal 二十七期）·
[B 站](https://space.bilibili.com/1298779265) ·
[萌娘百科](https://zh.moegirl.org.cn/灰泽满)
