#!/bin/bash

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
NODE="${NODE:-/Applications/ChatGPT.app/Contents/Resources/cua_node/bin/node}"
[ -x "$NODE" ] || { printf 'Codex bundled Node.js was not found: %s\n' "$NODE" >&2; exit 1; }

while IFS= read -r file; do /bin/bash -n "$file"; done < <(
  /usr/bin/find "$ROOT" -type f \( -name '*.sh' -o -name '*.command' \) \
    ! -path '*/release/*' -print
)
while IFS= read -r file; do "$NODE" --check "$file" >/dev/null; done < <(
  /usr/bin/find "$ROOT/scripts" "$ROOT/assets" -type f \( -name '*.mjs' -o -name '*.js' \) -print
)

if /usr/bin/grep -R -n -E 'dream-skin-skin|DREAM_SKIN_SKIN|1\.0\.0-rc2' \
  "$ROOT/scripts" "$ROOT/assets" >/dev/null; then
  printf 'Legacy release-candidate identifiers remain in runtime files.\n' >&2
  exit 1
fi
if /usr/bin/grep -R -n -E '(writeFile|rename|copyFile|rm).*app\.asar' "$ROOT/scripts" >/dev/null; then
  printf 'A runtime script appears to mutate app.asar.\n' >&2
  exit 1
fi
if /usr/bin/grep -n -E '/usr/bin/python3|(^|[[:space:]])eval([[:space:]]|$)' \
  "$ROOT/scripts/common-macos.sh" >/dev/null; then
  printf 'The shared macOS runtime must parse state with the bundled Node.js, without python3 or eval.\n' >&2
  exit 1
fi

"$NODE" "$ROOT/scripts/injector.mjs" --check-payload >/dev/null

BUNDLED_PAYLOAD_JSON="$("$NODE" "$ROOT/scripts/injector.mjs" --check-payload)"
"$NODE" -e '
  const fs = require("node:fs");
  const path = require("node:path");
  const [root, payloadJson] = process.argv.slice(1);
  const theme = JSON.parse(fs.readFileSync(path.join(root, "assets/theme.json"), "utf8"));
  const payload = JSON.parse(payloadJson);
  if (theme.name !== "灰泽满 Hazel") process.exit(1);
  if (theme.colors.background.toLowerCase() !== "#f3f2f2") process.exit(1);
  if (theme.colors.accent.toLowerCase() !== "#5c968e") process.exit(1);
  if (theme.colors.secondary.toLowerCase() !== "#d3d3d3") process.exit(1);
  if (theme.colors.highlight.toLowerCase() !== "#d89ba9") process.exit(1);
  if (theme.heroSubtitle !== "灰泽满究竟爱不爱绿冻？早就说过很爱了") process.exit(1);
  if (theme.cornerQuotes.length !== 2 || theme.petSafeArea.minHeight !== 180) process.exit(1);
  if (payload.heroTitle !== theme.heroTitle || payload.cornerQuoteCount !== 2) process.exit(1);
  if (payload.imagePosition !== "right" || payload.petSafeHeight !== 180) process.exit(1);
  if (payload.imageBytes < 1 || payload.stickerBytes < 1) process.exit(1);
  for (const asset of [theme.image, theme.sticker]) {
    if (!fs.statSync(path.join(root, "assets", asset)).isFile()) process.exit(1);
  }
' "$ROOT" "$BUNDLED_PAYLOAD_JSON"

if /usr/bin/grep -n -E '#(E25563|F07A86|F3A8AF|C93D4C|7CFF46|36D7E8|642A8C)' \
  "$ROOT/assets/dream-skin.css" "$ROOT/assets/renderer-inject.js" >/dev/null; then
  printf 'Legacy hard-coded pink/neon palette remains in the renderer payload.\n' >&2
  exit 1
fi
/usr/bin/grep -F -q 'pointer-events: none' "$ROOT/assets/dream-skin.css"
/usr/bin/grep -F -q -- '--dream-skin-pet-safe-height' "$ROOT/assets/dream-skin.css"
for marker in \
  'dream-skin-hero-meta' \
  'dream-skin-hero-sticker' \
  'dream-skin-hero-caption' \
  'dream-skin-native-suggestions-lane' \
  'dream-skin-home-card'; do
  /usr/bin/grep -F -q "$marker" "$ROOT/assets/dream-skin.css"
  /usr/bin/grep -F -q "$marker" "$ROOT/assets/renderer-inject.js"
done
/usr/bin/grep -F -q 'overflow: visible !important' "$ROOT/assets/dream-skin.css"
/usr/bin/grep -F -q '#codex-dream-skin-chrome.dream-skin-home-shell .dream-skin-footer-quote { display: none; }' "$ROOT/assets/dream-skin.css"
/usr/bin/grep -F -q 'top: 82px;' "$ROOT/assets/dream-skin.css"
/usr/bin/grep -F -q 'transform: translate(-50%, -50%) !important;' "$ROOT/assets/dream-skin.css"
if /usr/bin/grep -F -q '.group\/home-suggestions button' "$ROOT/assets/dream-skin.css"; then
  printf 'Home-card styling leaked to secondary suggestion decks.\n' >&2
  exit 1
fi
/usr/bin/grep -F -q 'nativeSuggestionButtons.length === 4' "$ROOT/assets/renderer-inject.js"
/usr/bin/grep -F -q 'button.hasAttribute("aria-labelledby")' "$ROOT/assets/renderer-inject.js"
/usr/bin/grep -F -q 'button.classList.contains("flex-col")' "$ROOT/assets/renderer-inject.js"
/usr/bin/grep -F -q '!button.classList.contains("group/home-suggestion-list-item")' "$ROOT/assets/renderer-inject.js"

TMP="$(/usr/bin/mktemp -d /tmp/codex-dream-skin-tests.XXXXXX)"
trap '/bin/rm -rf "$TMP"' EXIT

RUNTIME_HOME="$TMP/runtime-home"
RUNTIME_STATE_ROOT="$RUNTIME_HOME/Library/Application Support/CodexDreamSkinStudio"
RUNTIME_STATE="$RUNTIME_STATE_ROOT/state.json"
STATE_EVAL_MARKER="$TMP/state-eval-marker"
EXPECTED_BUNDLE="/Applications/Codex \$(touch \"$STATE_EVAL_MARKER\").app"
EXPECTED_EXE="$EXPECTED_BUNDLE/Contents/MacOS/ChatGPT; touch \"$STATE_EVAL_MARKER\""
EXPECTED_VERSION='1.1.2 "nightly"'
EXPECTED_TEAM_ID="TEAM'ID"
/bin/mkdir -p "$RUNTIME_STATE_ROOT"
"$NODE" -e '
  const fs = require("node:fs");
  const [file, codexBundle, codexExe, codexVersion, codexTeamId] = process.argv.slice(1);
  fs.writeFileSync(file, `${JSON.stringify({ codexBundle, codexExe, codexVersion, codexTeamId })}\n`);
' "$RUNTIME_STATE" "$EXPECTED_BUNDLE" "$EXPECTED_EXE" "$EXPECTED_VERSION" "$EXPECTED_TEAM_ID"
/usr/bin/env -u NODE -u NODE_VERSION HOME="$RUNTIME_HOME" /bin/bash -c '
  . "$1/scripts/common-macos.sh"
  ensure_node_runtime
  [ "$CODEX_BUNDLE" = "$2" ]
  [ "$CODEX_EXE" = "$3" ]
  [ "$CODEX_VERSION" = "$4" ]
  [ "$CODEX_TEAM_ID" = "$5" ]
' _ "$ROOT" "$EXPECTED_BUNDLE" "$EXPECTED_EXE" "$EXPECTED_VERSION" "$EXPECTED_TEAM_ID"
[ ! -e "$STATE_EVAL_MARKER" ] || {
  printf 'Runtime state values were evaluated as shell code.\n' >&2
  exit 1
}

/bin/mkdir -p "$TMP/theme"
/bin/cp "$ROOT/assets/hazel-hero.png" "$TMP/theme/background.png"
/bin/cp "$ROOT/assets/hazel-sticker.png" "$TMP/theme/sticker.png"
"$NODE" "$ROOT/scripts/write-theme.mjs" custom --output-dir "$TMP/theme" \
  --image background.png --sticker sticker.png --name '测试主题' \
  --brand-subtitle '测试工作台' --tagline '测试口号' \
  --hero-title '测试标题' --hero-subtitle '测试副标题' --quote 'TEST' \
  --corner-quote '第一句' --corner-quote '第二句' --status-text 'TEST ONLINE' \
  --image-position left --pet-safe-height 180 \
  --accent '#11aa55' --accent-alt '#55bb88' \
  --secondary '#22bbcc' --highlight '#663399' >/dev/null
PAYLOAD_JSON="$("$NODE" "$ROOT/scripts/injector.mjs" --check-payload --theme-dir "$TMP/theme")"
"$NODE" -e '
  const value = JSON.parse(process.argv[1]);
  if (!value.pass || value.themeName !== "测试主题" || value.imageBytes < 1) process.exit(1);
  if (value.heroTitle !== "测试标题" || value.heroSubtitle !== "测试副标题") process.exit(1);
  if (value.cornerQuoteCount !== 2 || value.imagePosition !== "left") process.exit(1);
  if (value.petSafeHeight !== 180 || value.stickerBytes < 1) process.exit(1);
' "$PAYLOAD_JSON"
"$NODE" -e '
  const fs = require("node:fs");
  const theme = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  if (theme.brandSubtitle !== "测试工作台" || theme.statusText !== "TEST ONLINE") process.exit(1);
  if (theme.colors.accentAlt !== "#55bb88" || theme.darkColors.text !== "#f2f4f3") process.exit(1);
' "$TMP/theme/theme.json"
/bin/mkdir -p "$TMP/missing-theme"
if MISSING_THEME_OUTPUT="$(
  "$NODE" "$ROOT/scripts/injector.mjs" --check-payload --theme-dir "$TMP/missing-theme" 2>&1
)"; then
  printf 'Explicit theme directory without theme.json unexpectedly passed.\n' >&2
  exit 1
fi
/usr/bin/printf '%s\n' "$MISSING_THEME_OUTPUT" | /usr/bin/grep -F -q \
  "Explicit theme directory is missing theme.json: $TMP/missing-theme/theme.json"
"$NODE" "$ROOT/scripts/write-theme.mjs" reset-demo --output-dir "$TMP/theme" >/dev/null
[ ! -e "$TMP/theme" ]

CONFIG="$TMP/config.toml"
BACKUP="$TMP/theme-backup.json"
/usr/bin/printf '%s\n' \
  'model = "gpt-5"' \
  '' \
  '[desktop]' \
  'appearanceTheme = "system"' \
  'appearanceDarkCodeThemeId = "vscode-dark"' \
  'keepMe = true' > "$CONFIG"
/bin/cp "$CONFIG" "$TMP/original.toml"
"$NODE" "$ROOT/scripts/theme-config.mjs" install "$CONFIG" "$BACKUP" >/dev/null
/usr/bin/cmp -s "$CONFIG" "$TMP/original.toml"
"$NODE" -e '
  const backup = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
  if (backup.values.appearanceTheme !== `appearanceTheme = "system"`) process.exit(1);
  if (backup.values.appearanceDarkCodeThemeId !== `appearanceDarkCodeThemeId = "vscode-dark"`) process.exit(1);
' "$BACKUP"
"$NODE" "$ROOT/scripts/theme-config.mjs" restore "$CONFIG" "$BACKUP" >/dev/null
/usr/bin/cmp -s "$CONFIG" "$TMP/original.toml"

NO_DESKTOP_CONFIG="$TMP/config-without-desktop.toml"
NO_DESKTOP_BACKUP="$TMP/theme-backup-without-desktop.json"
/usr/bin/printf '%s\n' 'model = "gpt-5"' 'keepMe = true' > "$NO_DESKTOP_CONFIG"
/bin/cp "$NO_DESKTOP_CONFIG" "$TMP/original-without-desktop.toml"
"$NODE" "$ROOT/scripts/theme-config.mjs" install "$NO_DESKTOP_CONFIG" "$NO_DESKTOP_BACKUP" >/dev/null
"$NODE" "$ROOT/scripts/theme-config.mjs" restore "$NO_DESKTOP_CONFIG" "$NO_DESKTOP_BACKUP" >/dev/null
/usr/bin/cmp -s "$NO_DESKTOP_CONFIG" "$TMP/original-without-desktop.toml"

/usr/bin/env -u HOME /bin/bash -c '. "$1/scripts/common-macos.sh"; [ -n "$HOME" ] && [ "$SKIN_VERSION" = "1.2.0-hazel.1" ]' _ "$ROOT"
"$ROOT/scripts/doctor-macos.sh" >/dev/null

printf 'PASS: syntax, payload, runtime-state safety, custom-theme, config round-trips, HOME recovery, signature, and doctor checks.\n'
