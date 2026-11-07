#!/usr/bin/env bash
set -euo pipefail
SRC=$(cd "$(dirname "$0")" && pwd)
ROOT=$(readlink -m "${REPLITDECK_ROOT:-$HOME/.local/opt/replitdeck}")
BIN=${XDG_BIN_HOME:-$HOME/.local/bin}
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
case ${1:-} in --help|-h) echo 'Usage: bash install.sh'; exit 0;; '') ;; *) echo 'Unknown option' >&2; exit 2;; esac
[[ $# == 0 && $(uname -s)-$(uname -m) == Linux-x86_64 ]] || exit 2
case "$ROOT" in /|"$HOME"|"$HOME/.local"|"$HOME/.local/opt"|"$SRC") echo 'Unsafe installation root' >&2; exit 1;; esac
for tool in curl python3 tar ar flock ldd; do command -v "$tool" >/dev/null || { echo "Missing $tool. See docs/INSTALL.md" >&2; exit 1; }; done
if [[ -e $BIN/replitdeck || -L $BIN/replitdeck ]]; then cmp -s "$BIN/replitdeck" "$SRC/replitdeck" || { echo 'Existing unrelated launcher; refusing replacement' >&2; exit 1; }; fi
mkdir -p "$ROOT/integration" "$BIN" "$DATA/applications"
cp -a "$SRC/libexec" "$SRC/share" "$ROOT/integration/"
chmod +x "$ROOT/integration/libexec/"*.sh
REPLITDECK_ROOT="$ROOT" REPLITDECK_SOURCE="$ROOT/integration" bash "$ROOT/integration/libexec/update.sh" --apply
if [[ ! -e $ROOT/libexec && ! -L $ROOT/libexec ]]; then ln -s "$ROOT/current/libexec" "$ROOT/libexec"; fi
install -m755 "$SRC/replitdeck" "$BIN/replitdeck"
python3 - "$SRC/share/replitdeck.desktop" "$DATA/applications/replitdeck.desktop" "$BIN/replitdeck" "$ROOT" <<'PY'
import pathlib,sys,re,json
s=pathlib.Path(sys.argv[1]).read_text()
s=re.sub(r'^Exec=.*$',lambda _: 'Exec='+json.dumps(sys.argv[3])+' %U',s,flags=re.M)
s=re.sub(r'^TryExec=.*$',lambda _: 'TryExec='+sys.argv[3],s,flags=re.M)
s=re.sub(r'^Icon=.*$',lambda _: 'Icon='+sys.argv[4]+'/current/share/replitdeck.png',s,flags=re.M)
pathlib.Path(sys.argv[2]).write_text(s)
PY
if command -v xdg-mime >/dev/null; then
 owner=$(xdg-mime query default x-scheme-handler/replit 2>/dev/null || true)
 case "$owner" in ''|replitdeck.desktop) xdg-mime default replitdeck.desktop x-scheme-handler/replit || true;; esac
fi
command -v update-desktop-database >/dev/null && update-desktop-database "$DATA/applications" || true
echo "Installed ReplitDeck. Run: $BIN/replitdeck"
