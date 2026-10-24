# Releasing Folio

Folio's downloadable app is a universal macOS bundle, ad-hoc signed for local
builds and signed with a **Developer ID Application** certificate for public
releases.

## 1. Build the universal app

```sh
./Scripts/package_universal.sh
```

This produces `dist/Folio.app` with both `arm64` and `x86_64` slices.

## 2. Sign, notarize, and staple

A Developer ID Application certificate is required. An Apple Development
certificate is not accepted for notarization.

Store notary credentials in the login Keychain once:

```sh
xcrun notarytool store-credentials "folio-notary" \
  --apple-id "your Apple ID" \
  --team-id "your Team ID"
```

The command prompts for an app-specific password, not the Apple ID password.
Keep the credential in the Keychain; never commit it.

Then:

```sh
export DEVELOPER_ID_IDENTITY="Developer ID Application: Your Name (TEAMID)"
./Scripts/sign_notarize.sh
```

The script:

- signs the app with hardened runtime and a secure timestamp;
- submits a temporary zip to Apple's notary service and waits;
- staples the notarization ticket to the app;
- verifies the app with `codesign`, `stapler`, and `spctl`;
- creates `dist/Folio-VERSION-macOS-universal.zip` and prints its SHA-256.

## 3. Publish

Create a new tag and GitHub release, then attach:

- `Folio-VERSION-macOS-universal.zip`
- the screenshots from `docs/screenshots/`

Update the download filename, SHA-256, and release notes. Do not reuse a
previous release tag for a differently signed build; publish a new patch
version instead.

## Notes

A Developer ID signature embeds the certificate identity and team identifier in
the binary, as required for Gatekeeper trust. It does not embed the Apple ID
email or the notary credential. If a build must contain no certificate identity
at all, it cannot be notarized; an ad-hoc build will trigger Gatekeeper warnings
on other Macs.
