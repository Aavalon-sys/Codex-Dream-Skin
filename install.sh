#!/bin/bash
# 一键安装灰泽满 Hazel 主题（macOS）
#
#   curl -fsSL https://raw.githubusercontent.com/Aavalon-sys/Codex-Dream-Skin/agent/public-hazel-release/install.sh | bash
#
# 透传安装参数（例如保留当前已激活的主题）：
#
#   curl -fsSL .../install.sh | bash -s -- --keep-active-theme
#
# 走 curl 而不是浏览器下载，是因为浏览器会给文件打上 com.apple.quarantine，
# 解压后双击 .command 会被 Gatekeeper 拦成“未识别的开发者”。curl 不打这个标记。

set -euo pipefail

REPO="${HAZEL_REPO:-Aavalon-sys/Codex-Dream-Skin}"
TAG="${HAZEL_TAG:-latest}"

say() { printf 'hazel-install: %s\n' "$*" >&2; }
fail() { say "$*"; exit 1; }

[ "$(uname -s)" = "Darwin" ] || fail "这个脚本只支持 macOS。"

TMP="$(mktemp -d /tmp/hazel-install.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

if [ "$TAG" = "latest" ]; then
  META="https://api.github.com/repos/$REPO/releases/latest"
else
  META="https://api.github.com/repos/$REPO/releases/tags/$TAG"
fi

say "正在查询 $REPO 的发布信息…"
curl -fsSL "$META" -o "$TMP/release.json" || fail "取不到发布信息，确认仓库是公开的、且已发布 $TAG 版本。"

asset_url() {
  grep -o "\"browser_download_url\"[[:space:]]*:[[:space:]]*\"[^\"]*$1\"" "$TMP/release.json" \
    | head -1 | sed 's/.*"\(https[^"]*\)"/\1/'
}

ZIP_URL="$(asset_url '\.zip')"
[ -n "$ZIP_URL" ] || fail "该发布里没有 .zip 资源。"

say "正在下载 ${ZIP_URL##*/}"
curl -fsSL -o "$TMP/skin.zip" "$ZIP_URL" || fail "下载失败。"

SUMS_URL="$(asset_url 'SHA256SUMS\.txt')"
if [ -n "$SUMS_URL" ] && curl -fsSL -o "$TMP/SHA256SUMS.txt" "$SUMS_URL" 2>/dev/null; then
  want="$(/usr/bin/awk '{print $1}' "$TMP/SHA256SUMS.txt" | head -1)"
  got="$(/usr/bin/shasum -a 256 "$TMP/skin.zip" | /usr/bin/awk '{print $1}')"
  [ "$want" = "$got" ] || fail "校验和不匹配（期望 $want，实际 $got），已中止。"
  say "SHA-256 校验通过"
else
  say "该发布未附带 SHA256SUMS.txt，跳过校验"
fi

/usr/bin/ditto -x -k "$TMP/skin.zip" "$TMP/unpacked" || fail "解压失败。"

INSTALLER="$(/usr/bin/find "$TMP/unpacked" -type f -name 'install-dream-skin-macos.sh' | head -1)"
[ -n "$INSTALLER" ] || fail "压缩包里找不到安装脚本。"
/bin/chmod +x "$(dirname "$INSTALLER")"/*.sh 2>/dev/null || true

say "开始安装…"
exec "$INSTALLER" "$@"
