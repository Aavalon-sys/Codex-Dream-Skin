#!/bin/bash

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
VERSION="$(/usr/bin/tr -d '[:space:]' < "$ROOT/VERSION")"
OUTPUT="${1:-$HOME/Desktop/灰泽满 Hazel × Codex 主题.zip}"
TMP="$(/usr/bin/mktemp -d /tmp/hazel-codex-theme.XXXXXX)"
CLIENT_ROOT="$TMP/灰泽满 Hazel × Codex 主题"
ENGINE="$CLIENT_ROOT/.codex-dream-skin-studio"
trap '/bin/rm -rf "$TMP"' EXIT

"$ROOT/tests/run-tests.sh"
/bin/mkdir -p "$ENGINE"
/usr/bin/rsync -a \
  --exclude '.git/' \
  --exclude '.DS_Store' \
  --exclude 'release/' \
  --exclude 'runtime/' \
  "$ROOT/" "$ENGINE/"

/usr/bin/printf '%s\n' \
  '#!/bin/bash' \
  'set -euo pipefail' \
  'ROOT="$(cd "$(dirname "$0")" && pwd -P)"' \
  'exec "$ROOT/.codex-dream-skin-studio/scripts/install-dream-skin-macos.sh"' \
  > "$CLIENT_ROOT/安装灰泽满主题.command"

/usr/bin/printf '%s\n' \
  '#!/bin/bash' \
  'set -euo pipefail' \
  'ENGINE="$HOME/.codex/codex-dream-skin-studio"' \
  'if [ ! -x "$ENGINE/uninstall-hazel.command" ]; then' \
  '  /usr/bin/osascript -e '\''display alert "没有找到已安装的灰泽满主题。" as warning'\'' >/dev/null' \
  '  exit 1' \
  'fi' \
  'exec "$ENGINE/uninstall-hazel.command"' \
  > "$CLIENT_ROOT/卸载灰泽满主题.command"

/bin/cp "$ROOT/README.md" "$CLIENT_ROOT/使用说明.md"
/bin/cp "$ROOT/references/asset-sources.md" "$CLIENT_ROOT/素材来源与使用边界.md"
/bin/chmod 755 "$CLIENT_ROOT/安装灰泽满主题.command" "$CLIENT_ROOT/卸载灰泽满主题.command"
/bin/chmod 755 "$ENGINE"/*.command "$ENGINE"/scripts/*.sh "$ENGINE"/tests/*.sh
/usr/bin/xattr -cr "$CLIENT_ROOT"
/usr/bin/find "$CLIENT_ROOT" -type f \( -name '.DS_Store' -o -name '._*' \) -delete
/bin/mkdir -p "$(dirname "$OUTPUT")"
/bin/rm -f "$OUTPUT"
COPYFILE_DISABLE=1 /usr/bin/ditto -c -k --keepParent --norsrc --noextattr "$CLIENT_ROOT" "$OUTPUT"
SHA256="$(/usr/bin/shasum -a 256 "$OUTPUT" | /usr/bin/awk '{print $1}')"
/usr/bin/printf 'Created %s\nVersion %s\nSHA-256 %s\n' "$OUTPUT" "$VERSION" "$SHA256"
