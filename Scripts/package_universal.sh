#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ARM_SCRATCH="$ROOT/.build-arm64"
X86_SCRATCH="$ROOT/.build-x86_64"
DIST="$ROOT/dist"
APP="$DIST/Folio.app"

swift build -c release --triple arm64-apple-macosx14.0 --scratch-path "$ARM_SCRATCH"
swift build -c release --triple x86_64-apple-macosx14.0 --scratch-path "$X86_SCRATCH"

ARM_BIN="$ARM_SCRATCH/out/Products/Release/Folio"
X86_BIN="$X86_SCRATCH/out/Products/Release/Folio"

[[ -f "$ARM_BIN" ]] || { echo "Missing arm64 build at $ARM_BIN" >&2; exit 1; }
[[ -f "$X86_BIN" ]] || { echo "Missing x86_64 build at $X86_BIN" >&2; exit 1; }

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create "$ARM_BIN" "$X86_BIN" -output "$APP/Contents/MacOS/Folio"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

# Ad-hoc sign only so the bundle can be launched while testing. The release
# signing script replaces this signature with a Developer ID signature.
codesign --force --sign - "$APP"
lipo -info "$APP/Contents/MacOS/Folio"
echo "Universally built: $APP"
