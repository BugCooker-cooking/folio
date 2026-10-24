#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${APP_PATH:-$ROOT/dist/Folio.app}"
VERSION="${VERSION:-1.0.0}"
DMG="${DMG_PATH:-$ROOT/dist/Folio-${VERSION}-macOS-universal.dmg}"
STAGING="${TMPDIR:-/tmp}/Folio-dmg-$$"
IDENTITY="${DEVELOPER_ID_IDENTITY:-}"
PROFILE="${NOTARY_PROFILE:-folio-notary}"

if [[ ! -d "$APP" ]]; then
    echo "Missing app bundle: $APP" >&2
    echo "Run ./Scripts/package_universal.sh and ./Scripts/sign_notarize.sh first." >&2
    exit 1
fi

if [[ -z "$IDENTITY" ]]; then
    echo "Set DEVELOPER_ID_IDENTITY before signing the DMG." >&2
    exit 1
fi

rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
ditto "$APP" "$STAGING/Folio.app"
ln -s /Applications "$STAGING/Applications"

hdiutil create \
    -volname "Folio" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "$DMG" >/dev/null

codesign --force --timestamp --sign "$IDENTITY" "$DMG"
codesign --verify --verbose=2 "$DMG"
hdiutil verify "$DMG"

xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"
spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG"

shasum -a 256 "$DMG"
echo "Signed and notarized disk image: $DMG"
