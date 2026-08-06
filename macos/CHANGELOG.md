# Changelog

## 1.4.0-hazel.1 — 2026-08-05

- Restore the skin on Codex 26.727, which dropped the `main-surface` class from `<main>`: the renderer detection no longer requires it, and the stylesheet anchors to a `dream-skin-shell-main` marker applied to whichever content surface is resolved.
- Identify the Codex renderer by its app shell alone. Requiring a composer or `[role="main"]` on top of that made every re-injection fail while a route lacking both was open, such as the scheduled-tasks list.
- Resolve the content surface inner-first, so the chrome overlay tracks the content column instead of the full-window wrapper that Codex 26.727 introduced.
- Fill the panels' rounded-corner notches with a flat base tone painted above both panels, so the exposed slivers no longer show the decorative page tint at full strength.
- Round the content surface's bottom-left corner to match its top-left, restoring the rounded rectangle facing the sidebar.
- Keep the brand block clear of the macOS traffic lights and the app's own top-left controls when the sidebar is collapsed.
- Track the sidebar's collapse animation from a single CSS variable, with the corner fills moved by transform and the overlay geometry derived in CSS, bringing dropped frames back down to the unskinned baseline.
- Let the scheduled-tasks search header show the artwork behind it instead of covering it with an opaque surface and fade strip. Scope that rule to the header's own surface class so it stops tinting the chat composer's square wrapper, whose corners showed as a box around the rounded input.
- Hold the chat surface fully opaque until the artwork begins. Fading `--ds-bg` over a `--ds-bg` base changes nothing visually, but the near-1 alphas still rounded to a unit per band, banding the empty half into faint vertical stripes.
- Re-tint the fades that ramp to the app's own surface colour. They still ramped to white, which in light mode landed as a bright block with hard edges above the composer — 12 levels away from the skin's background, now 1.

## 1.3.0-hazel.2 — 2026-07-25

- Support the refactored Codex 26.721 new-task page while preserving the legacy four-card home layout.
- Replace brittle positional `:first-child` selectors with semantic runtime markers for the hero, suggestion area, project selector, and composer.
- Keep the new personalized suggestion rows fully readable, including their native icons and text.
- Remove the enclosing suggestion panel so changing suggestion counts and long copy flow naturally without a fixed-looking box.
- Rebalance the hero and composer zones so the character art, quote, sticker, project selector, and input remain visible at desktop and narrow window widths.
- Update live verification to recognize both the new suggestion-list layout and the previous four-card action deck.
- Add regression checks for both home structures and reject a return to positional home-page selectors.

## 1.2.0-hazel.2 — 2026-07-17

- Keep the four native home action cards visible, centered, and independently styled.
- Preserve text in secondary suggestion lists by excluding list items from home-card styling.
- Move the Hazel-and-jelly sticker and character-setting caption into the left side of the hero.
- Reposition the corner quote away from the character art and vertically center the online status in the title bar.
- Discover valid Codex installations stored in `/Applications/Utilities` during verification and hot reapply.
- Separate portable release checks from the optional host doctor, and reject archives containing builder-specific paths.
- Treat stale or inactive live-theme state as informational unless the doctor is called with `--require-live`.
- Add regression checks for the updated home-card DOM classification and scoped CSS selectors.

## 1.2.0-hazel.1 — 2026-07-16

- Add the Hazel-specific light gray and mint visual system with a dark fallback.
- Add optional hero copy, multiple corner quotes, image position, sticker, and pet-safe-area theme fields.
- Seed and back up the bundled theme during installation; add Hazel launch, verify, and restore entries.
- Add official-source provenance, manqu-safe decoration boundaries, and Hazel payload regression tests.

## 1.1.2 — 2026-07-16

### 修复

- 修正内置主题引用了未随仓库发布的背景文件，恢复使用 bundled abstract demo 素材
- 更新主题配置往返测试：安装只备份外观键，不再错误断言强制切换深色模式
- 恢复原本没有 `[desktop]` 配置段的用户设置时，不再额外写入空段
- 热切换读取运行状态时复用 Codex 内置 Node.js，不再依赖系统 `python3` 或执行 `eval`
- 显式传入的 `--theme-dir` 缺少 `theme.json` 时立即报错，不再静默回退到内置 demo 主题

---

## 1.1.1 — 2026-07-16

### 修复

- 不再用 `launchctl submit` 托管带调试口的 Codex：退出 SwiftBar / 关掉 Codex 后不应再被 launchd 自动拉起
- 暂停与完全恢复时清理 `com.openai.codex-dream-skin-studio.app` 作业

---

## 1.1.0 — 2026-07-16

### 新增

- SwiftBar 菜单栏入口（`Install Menu Bar.command`）：应用 / 暂停 / 换图 / 切换已保存主题 / 从图片文件夹加载 / 完全恢复
- 主题库（`themes/`）与图片投放目录（`images/`）动态加载，不再把 README 图库合成图当背景素材
- 按 Codex 应用浅色 / 深色自动切换皮肤壳（`data-dream-shell`）

### 改进

- CDP 已就绪时热切换主题（重启 injector + 短时注入），换图更快
- 注入校验放宽（项目选择器等可选），避免误杀已生效皮肤
- 注入守护优先 `nohup`；暂停状态与路径大小写下停止逻辑更稳
- 安装时不再强制 `appearanceTheme=dark`，只备份桌面外观相关键，便于恢复与自动适配

### 视觉

- 以原版暗色 portal CSS 为结构底，叠加 light 壳与更薄横幅遮罩，减轻「换图看不清」
- 示例纯横幅：`docs/images/banner-arina-hashimoto-pure-no-ui.png`（无人机 UI 合成）

### 说明

- `docs/images/gallery/` 仅为效果预览，不要当 `theme` 背景导入

---

## 1.0.0 — 2026-07-15

- 发布 macOS 通用主题制作器，而不是固定角色皮肤。
- 加入 Finder 选图、自动 JPEG 转换、主题命名和高级配色参数。
- 主页使用独立横幅，任务页使用背景与磨砂层，完整保留原生交互。
- 改为复用并验证 Codex 官方签名 Node.js，不再附带大型运行时或依赖全局 Node。
- 增加独立安装目录、桌面启动/定制/验证/恢复入口。
- 增加官方签名、CDP 端口归属、PID 身份、刷新重注入和真实 DOM 自检。
- 增加原子配置备份、精确恢复、静态测试、安装恢复循环和发布打包脚本。
- 清理固定角色内部命名；传送门主题仅作为可替换示例素材。
- 开源树：示例横幅改为无角色抽象几何图；验收截图不入库；补充 NOTICE / README 商标与安全边界说明。
