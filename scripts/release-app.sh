#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="CannedFruits"
VERSION="${VERSION:-v0.2n}"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
RELEASE_DIR="$DIST_DIR/release"
STAGING_DIR="$DIST_DIR/dmg-staging"

cd "$ROOT_DIR"

"$ROOT_DIR/scripts/package-app.sh"

rm -rf "$RELEASE_DIR" "$STAGING_DIR"
mkdir -p "$RELEASE_DIR" "$STAGING_DIR"

ditto -c -k --keepParent "$APP_DIR" "$RELEASE_DIR/$APP_NAME-$VERSION-macOS.zip"

cp -R "$APP_DIR" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"
hdiutil create \
  -volname "$APP_NAME $VERSION" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$RELEASE_DIR/$APP_NAME-$VERSION.dmg"

(
  cd "$RELEASE_DIR"
  shasum -a 256 "$APP_NAME-$VERSION.dmg" "$APP_NAME-$VERSION-macOS.zip" > SHA256SUMS.txt
)

rm -rf "$STAGING_DIR"

echo "Release assets:"
ls -lh "$RELEASE_DIR"
