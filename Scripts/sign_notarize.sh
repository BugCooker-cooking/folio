#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${APP_PATH:-$ROOT/dist/Folio.app}"
VERSION="${VERSION:-1.0.0}"
OUT="${OUT_ZIP:-$ROOT/dist/Folio-${VERSION}-macOS-universal.zip}"
NOTARY_ZIP="${TMPDIR:-/tmp}/Folio-notarize-$$.zip"
IDENTITY="${DEVELOPER_ID_IDENTITY:-}"
PROFILE="${NOTARY_PROFILE:-folio-notary}"

if [[ ! -d "$APP" ]]; then
    echo "Missing app bundle: $APP" >&2
    echo "Run ./Scripts/package_universal.sh first." >&2
    exit 1
fi

if [[ -z "$IDENTITY" ]]; then
    echo "Set DEVELOPER_ID_IDENTITY to a Developer ID Application identity:" >&2
    echo '  export DEVELOPER_ID_IDENTITY="Developer ID Application: ... (TEAMID)"' >&2
    exit 1
fi

lipo -info "$APP/Contents/MacOS/Folio"

codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

rm -f "$NOTARY_ZIP" "$OUT"
ditto -c -k --keepParent "$APP" "$NOTARY_ZIP"

xcrun notarytool submit "$NOTARY_ZIP" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
spctl --assess --type execute --verbose=2 "$APP"

ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUT"
shasum -a 256 "$OUT"
echo "Signed and notarized release: $OUT"
