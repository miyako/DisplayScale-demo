#!/bin/sh
# Refresh the vendored DisplayScale component and rebuild its macOS CLI.
# Usage: scripts/install-component.sh [--component-src /path/to/DisplayScale]
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SRC="$ROOT/../DisplayScale"
DEST="$ROOT/Components/DisplayScale.4dbase"

while [ $# -gt 0 ]; do
	case "$1" in
		--component-src) SRC="$2"; shift 2 ;;
		-h|--help) sed -n '2,4p' "$0"; exit 0 ;;
		*) echo "unknown argument: $1" >&2; exit 2 ;;
	esac
done

[ -d "$SRC/component/DisplayScale" ] || {
	echo "component sources not found: $SRC/component/DisplayScale" >&2
	echo "pass --component-src pointing at a DisplayScale checkout" >&2
	exit 1
}

command -v clang++ >/dev/null || { echo "clang++ is required" >&2; exit 1; }
command -v rsync >/dev/null || { echo "rsync is required" >&2; exit 1; }

echo "==> copying component sources from $SRC/component/DisplayScale"
rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
rsync -a --exclude 'Project/DerivedData' --exclude 'Libraries' --exclude 'userPreferences.*' --exclude '.DS_Store' "$SRC/component/DisplayScale/" "$DEST/"

echo "==> building macOS CLI (universal arm64+x86_64)"
mkdir -p "$DEST/Resources/bin/macOS"
clang++ -std=c++17 -O2 -mmacosx-version-min=11.0 -arch arm64 -arch x86_64 \
	"$SRC/cli/main.cpp" \
	-framework CoreGraphics -framework CoreFoundation \
	-o "$DEST/Resources/bin/macOS/display-scale"
chmod +x "$DEST/Resources/bin/macOS/display-scale"

echo "==> verifying"
"$DEST/Resources/bin/macOS/display-scale" --version
"$DEST/Resources/bin/macOS/display-scale" monitors || {
	echo "warning: monitors failed (a sleeping display legitimately returns NO_MONITORS)" >&2
}
echo "==> done: $DEST"
