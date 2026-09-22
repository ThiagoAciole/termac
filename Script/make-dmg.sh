#!/usr/bin/env bash
# Build, sign and package Termac into dist/Termac-<version>.dmg.
#
# The DMG layout mirrors the release volume: Termac.app + /Applications
# symlink, so drag-to-Applications works. The app is signed with the stable
# "Termac Self-Signed" identity (docs/SIGNING.md); without it the app ships
# ad-hoc and Gatekeeper reports it as damaged after a quarantined download.
#
# Usage: ./Script/make-dmg.sh [--skip-build]
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
IDENTITY="Termac Self-Signed"
DERIVED="$ROOT/build-dmg-derived"
APP_NAME="Termac.app"
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

if ! security find-identity -p codesigning 2>/dev/null | grep -q "$IDENTITY"; then
  echo "error: identity '$IDENTITY' not found in the login keychain." >&2
  echo "Run ./Script/setup-signing.sh once to create it (docs/SIGNING.md)." >&2
  exit 1
fi

if [[ "${1:-}" != "--skip-build" ]]; then
  echo "==> Building Release"
  xcodebuild -project Termac.xcodeproj -scheme Termac \
    -configuration Release -destination 'platform=macOS' \
    -derivedDataPath "$DERIVED" build -quiet
fi

BUILT="$DERIVED/Build/Products/Release/$APP_NAME"
if [[ ! -d "$BUILT" ]]; then
  echo "error: $BUILT not found — build first (drop --skip-build)." >&2
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$BUILT/Contents/Info.plist")"

echo "==> Signing with '$IDENTITY'"
codesign --force --deep --sign "$IDENTITY" "$BUILT" >/dev/null 2>&1
codesign --verify --strict "$BUILT"

echo "==> Assembling DMG layout (v$VERSION)"
rm -rf "$STAGING/Volume"
mkdir -p "$STAGING/Volume"
cp -R "$BUILT" "$STAGING/Volume/$APP_NAME"
ln -s /Applications "$STAGING/Volume/Applications"

echo "==> Creating dist/Termac-$VERSION.dmg"
mkdir -p dist
hdiutil create -volname "Termac" -srcfolder "$STAGING/Volume" \
  -ov -format UDZO "dist/Termac-$VERSION.dmg" >/dev/null

echo "==> Verifying"
MOUNT="$(mktemp -d)"
hdiutil attach "dist/Termac-$VERSION.dmg" -mountpoint "$MOUNT" -nobrowse -readonly -quiet
codesign --verify --strict "$MOUNT/$APP_NAME"
hdiutil detach "$MOUNT" -quiet
rm -rf "$MOUNT"

echo
echo "Done: dist/Termac-$VERSION.dmg"
echo "Self-signed DMGs still trip Gatekeeper on download. Manual installs:"
echo "  xattr -cr /Applications/$APP_NAME   (or right-click → Open)"
