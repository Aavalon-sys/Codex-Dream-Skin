#!/bin/bash
# One-line installer for the Hazel build of Codex Dream Skin (macOS):
#
#   curl -fsSL https://raw.githubusercontent.com/Aavalon-sys/Codex-Dream-Skin/main/install.sh | bash
#
# Fetches the latest release DMG, checks it against SHA256SUMS.txt, copies
# Codex Dream Skin.app into Applications and runs the engine installer bundled
# inside it, the same one the app runs on first launch. curl downloads carry no
# quarantine flag, so Gatekeeper does not stop the unsigned app the way it does
# after a browser download. Arguments are passed on to the engine installer.
set -euo pipefail

REPO="Aavalon-sys/Codex-Dream-Skin"
APP_NAME="Codex Dream Skin.app"

say() { printf '%s\n' "$*" >&2; }
fail() { say "安装失败：$*"; exit 1; }

[ "$(uname -s)" = "Darwin" ] || fail "仅支持 macOS。Windows 请到 Releases 下载 Setup.exe。"

say "查询最新版本…"
tag="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
  | sed -n 's/^[[:space:]]*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 || true)"
if [ -z "$tag" ]; then
  # The API is rate limited per IP; the releases/latest redirect is not.
  tag="$(curl -fsSI "https://github.com/$REPO/releases/latest" 2>/dev/null \
    | tr -d '\r' | sed -n 's#^[Ll]ocation:.*/releases/tag/\(.*\)$#\1#p' | head -n 1 || true)"
fi
printf '%s' "$tag" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$' || fail "无法确定最新版本（得到：${tag:-空}）。"
version="${tag#v}"
dmg="CodexDreamSkin-v$version.dmg"
base="https://github.com/$REPO/releases/download/$tag"

work="$(mktemp -d "${TMPDIR:-/tmp}/codex-dream-skin-install.XXXXXX")"
mount_point="$work/mount"
cleanup() {
  [ ! -d "$mount_point" ] || hdiutil detach -quiet "$mount_point" >/dev/null 2>&1 || true
  rm -rf "$work"
}
trap cleanup EXIT

say "下载 $dmg…"
curl -fL --retry 3 --progress-bar -o "$work/$dmg" "$base/$dmg"
curl -fsSL --retry 3 -o "$work/SHA256SUMS.txt" "$base/SHA256SUMS.txt"
expected="$(awk -v f="$dmg" '$2 == f || $2 == "*" f { print $1; exit }' "$work/SHA256SUMS.txt")"
actual="$(shasum -a 256 "$work/$dmg" | awk '{ print $1 }')"
[ -n "$expected" ] && [ "$expected" = "$actual" ] || fail "SHA-256 校验不通过，已停止。"
say "SHA-256 校验通过。"

if [ "${CODEX_DREAM_SKIN_INSTALL_DRY_RUN:-}" = "1" ]; then
  say "试运行：已下载并校验 $dmg，未做任何安装。"
  exit 0
fi

# The engine installer refuses to run while ChatGPT/Codex is open, because it
# rewrites config.toml. Ask the app to quit the normal way; never force it.
codex_running() {
  [ "$(osascript -e 'application id "com.openai.codex" is running' 2>/dev/null)" = "true" ]
}
if codex_running; then
  say "正在退出 ChatGPT / Codex（安装后会自动带皮肤重新打开）…"
  osascript -e 'tell application id "com.openai.codex" to quit' >/dev/null 2>&1 || true
  for _ in $(seq 1 30); do
    codex_running || break
    sleep 1
  done
  ! codex_running || fail "ChatGPT / Codex 没有退出。请手动退出后重新运行这条命令。"
fi

mkdir -p "$mount_point"
hdiutil attach -readonly -nobrowse -quiet -mountpoint "$mount_point" "$work/$dmg"
[ -d "$mount_point/$APP_NAME" ] || fail "安装包里没有 $APP_NAME。"

dest="/Applications"
[ -w "$dest" ] || { dest="$HOME/Applications"; mkdir -p "$dest"; }
if pgrep -f "$APP_NAME/Contents/MacOS/" >/dev/null 2>&1; then
  osascript -e 'tell application "Codex Dream Skin" to quit' >/dev/null 2>&1 || true
  sleep 2
fi
say "安装 $APP_NAME 到 $dest…"
rm -rf "$dest/$APP_NAME"
ditto "$mount_point/$APP_NAME" "$dest/$APP_NAME"
hdiutil detach -quiet "$mount_point" >/dev/null 2>&1 || true

engine_installer="$dest/$APP_NAME/Contents/Resources/engine/scripts/install-dream-skin-macos.sh"
[ -x "$engine_installer" ] || fail "找不到引擎安装器：$engine_installer"
say "部署主题引擎…"
if [ "$#" -gt 0 ]; then
  "$engine_installer" "$@"
else
  "$engine_installer" --no-launchers
fi

open "$dest/$APP_NAME" >/dev/null 2>&1 || true
say "完成：灰泽满 Hazel v$version 已安装。菜单栏右上角的 Dream Skin 图标可以启动、暂停、换主题或还原。"
