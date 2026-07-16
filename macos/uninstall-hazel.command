#!/bin/bash

set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd -P)"
exec "$ROOT/scripts/restore-dream-skin-macos.sh" --restore-base-theme --uninstall
