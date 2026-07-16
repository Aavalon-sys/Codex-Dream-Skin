#!/bin/bash

set -euo pipefail
. "$(cd "$(dirname "$0")" && pwd -P)/common-macos.sh"

PORT=9341
CREATE_LAUNCHERS="true"
LAUNCH_AFTER_INSTALL="true"
IN_PLACE="false"
ACTIVATE_BUNDLED_THEME="true"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --port) PORT="${2:-}"; shift 2 ;;
    --no-launchers) CREATE_LAUNCHERS="false"; shift ;;
    --no-launch) LAUNCH_AFTER_INSTALL="false"; shift ;;
    --keep-active-theme) ACTIVATE_BUNDLED_THEME="false"; shift ;;
    --in-place) IN_PLACE="true"; shift ;;
    *) fail "Unknown installer argument: $1" ;;
  esac
done
case "$PORT" in ''|*[!0-9]*) fail "Invalid port: $PORT" ;; esac
[ "$PORT" -ge 1024 ] && [ "$PORT" -le 65535 ] || fail "Port must be between 1024 and 65535."

create_preinstall_backup() {
  [ -e "$INSTALL_ROOT" ] || [ -e "$THEME_DIR" ] || return 0
  ensure_state_root
  local stamp
  local backup
  stamp="$(/bin/date '+%Y%m%d-%H%M%S')-$$"
  backup="$STATE_ROOT/backups/$stamp"
  /bin/mkdir -p "$backup"
  if [ -d "$INSTALL_ROOT" ]; then
    /usr/bin/rsync -a --exclude 'runtime/' "$INSTALL_ROOT/" "$backup/engine/"
  fi
  if [ -d "$THEME_DIR" ]; then
    /usr/bin/rsync -a "$THEME_DIR/" "$backup/theme/"
  fi
  /usr/bin/printf '%s\n' \
    "createdAt=$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')" \
    "engine=$INSTALL_ROOT" \
    "theme=$THEME_DIR" > "$backup/backup-info.txt"
  /bin/chmod -R go-rwx "$backup"
  printf 'Saved the previous Dream Skin engine/theme at %s.\n' "$backup"
}

seed_bundled_theme() {
  /bin/mkdir -p "$THEME_DIR"
  /bin/chmod 700 "$THEME_DIR"
  "$NODE" -e '
    const fs = require("node:fs");
    const path = require("node:path");
    const [assets, destination] = process.argv.slice(1);
    const config = JSON.parse(fs.readFileSync(path.join(assets, "theme.json"), "utf8"));
    const names = ["theme.json", config.image, config.sticker].filter(Boolean);
    for (const name of names) {
      if (path.basename(name) !== name) throw new Error(`Unsafe bundled asset: ${name}`);
      const source = path.join(assets, name);
      const target = path.join(destination, name);
      const temporary = `${target}.${process.pid}.tmp`;
      fs.copyFileSync(source, temporary);
      fs.chmodSync(temporary, 0o600);
      fs.renameSync(temporary, target);
    }
  ' "$PROJECT_ROOT/assets" "$THEME_DIR"
  printf 'Activated the bundled Hazel theme in %s.\n' "$THEME_DIR"
}

deploy_project() {
  local temporary="$INSTALL_ROOT.installing.$$"
  local previous="$INSTALL_ROOT.previous.$$"
  /bin/rm -rf "$temporary"
  /bin/mkdir -p "$temporary"
  /usr/bin/rsync -a \
    --exclude '.git/' \
    --exclude '.DS_Store' \
    --exclude 'release/' \
    --exclude 'runtime/' \
    "$PROJECT_ROOT/" "$temporary/"
  /bin/chmod 700 "$temporary"/*.command "$temporary"/scripts/*.sh 2>/dev/null || true
  if [ -e "$INSTALL_ROOT" ]; then /bin/mv "$INSTALL_ROOT" "$previous"; fi
  if ! /bin/mv "$temporary" "$INSTALL_ROOT"; then
    [ -e "$previous" ] && /bin/mv "$previous" "$INSTALL_ROOT"
    fail "Could not install the project at $INSTALL_ROOT"
  fi
  /bin/rm -rf "$previous"
}

if [ "$IN_PLACE" = "false" ] && [ "$PROJECT_ROOT" != "$INSTALL_ROOT" ]; then
  create_preinstall_backup
  /bin/mkdir -p "$(dirname "$INSTALL_ROOT")"
  deploy_project
  install_args=(--in-place --port "$PORT")
  [ "$CREATE_LAUNCHERS" = "true" ] || install_args+=(--no-launchers)
  [ "$LAUNCH_AFTER_INSTALL" = "true" ] || install_args+=(--no-launch)
  [ "$ACTIVATE_BUNDLED_THEME" = "true" ] || install_args+=(--keep-active-theme)
  exec "$INSTALL_ROOT/scripts/install-dream-skin-macos.sh" "${install_args[@]}"
fi

discover_codex_app
require_macos_runtime
ensure_state_root
[ -f "$CONFIG_PATH" ] || fail "Codex config not found: $CONFIG_PATH. Launch Codex once, close it, and rerun the installer."
if [ "$ACTIVATE_BUNDLED_THEME" = "true" ] || [ ! -f "$THEME_DIR/theme.json" ]; then
  seed_bundled_theme
fi
"$NODE" "$INJECTOR" --check-payload --theme-dir "$THEME_DIR" >/dev/null
"$NODE" "$SCRIPT_DIR/theme-config.mjs" install "$CONFIG_PATH" "$THEME_BACKUP_PATH"

shell_quote() {
  "$NODE" -e 'process.stdout.write(JSON.stringify(process.argv[1]))' "$1"
}

write_launcher() {
  local target="$1"
  local command="$2"
  if [ -e "$target" ] && ! /usr/bin/grep -q '^# CodexDreamSkinStudio launcher$' "$target" 2>/dev/null; then
    fail "Refusing to overwrite an unrelated Desktop file: $target"
  fi
  /usr/bin/printf '%s\n' \
    '#!/bin/bash' \
    '# CodexDreamSkinStudio launcher' \
    'set -e' \
    "$command" > "$target"
  /bin/chmod 700 "$target"
}

if [ "$CREATE_LAUNCHERS" = "true" ]; then
  /bin/mkdir -p "$HOME/Desktop"
  start_script="$(shell_quote "$SCRIPT_DIR/start-dream-skin-macos.sh")"
  verify_script="$(shell_quote "$SCRIPT_DIR/verify-dream-skin-macos.sh")"
  restore_script="$(shell_quote "$SCRIPT_DIR/restore-dream-skin-macos.sh")"
  screenshot="$(shell_quote "$HOME/Desktop/Codex Dream Skin Verification.png")"
  write_launcher "$HOME/Desktop/Hazel Codex Theme.command" "exec $start_script --port $PORT --prompt-restart"
  write_launcher "$HOME/Desktop/Hazel Codex Theme - Verify.command" "$verify_script --screenshot $screenshot && /usr/bin/open $screenshot"
  write_launcher "$HOME/Desktop/Hazel Codex Theme - Restore.command" "exec $restore_script --restore-base-theme --restart-codex"
fi

printf 'Codex Dream Skin Studio %s installed at %s for Codex %s using its signed Node.js %s.\n' \
  "$SKIN_VERSION" "$PROJECT_ROOT" "$CODEX_VERSION" "$NODE_VERSION"
printf 'Use the Desktop launchers to start, verify, or restore the official appearance.\n'

if [ "$LAUNCH_AFTER_INSTALL" = "true" ]; then
  "$SCRIPT_DIR/start-dream-skin-macos.sh" --port "$PORT" --prompt-restart
fi
