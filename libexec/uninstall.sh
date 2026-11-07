#!/usr/bin/env bash
set -euo pipefail
case ${1:-} in --help|-h) echo 'Usage: uninstall.sh [--purge]'; exit 0;; ''|--purge) ;; *) echo 'Unknown option' >&2; exit 2;; esac
[[ $# -le 1 ]] || exit 2
ROOT=$(readlink -m "${REPLITDECK_ROOT:-$HOME/.local/opt/replitdeck}")
BIN=${XDG_BIN_HOME:-$HOME/.local/bin}
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
case "$ROOT" in /|"$HOME"|"$HOME/.local"|"$HOME/.local/opt") echo 'Unsafe root' >&2; exit 1;; esac
[[ -f "$ROOT/current/resources/app/package.json" ]] || { echo 'Installation not found' >&2; exit 1; }
node -e 'if(require(process.argv[1]).name!==process.argv[2])process.exit(1)' "$ROOT/current/resources/app/package.json" '@replit/desktop'
MATCH=$(printf '%s\n' "$ROOT" | sed 's/[][\\.^$*+?(){}|]/\\&/g')
if pgrep -u "$(id -u)" -f "^$MATCH/(app|versions/[^/]+)/replitdeck( |$)" >/dev/null; then echo 'Close the app before uninstalling' >&2; exit 1; fi
rm -f "$DATA/applications/replitdeck.desktop"
if cmp -s "$BIN/replitdeck" "$ROOT/current/libexec/launcher"; then rm -f "$BIN/replitdeck"; fi
rm -rf "$ROOT"
if [[ ${1:-} == --purge ]]; then rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/Replit"; fi
command -v update-desktop-database >/dev/null && update-desktop-database "$DATA/applications" || true
echo 'ReplitDeck removed; ordinary uninstall preserves the account profile.'
