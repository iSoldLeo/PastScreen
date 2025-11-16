#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'TXT'
Usage: package_release.sh [APP_PATH] [OUTPUT_DIR]

Defaults:
  APP_PATH  : ~/Desktop/PastScreen/PastScreen.app
  OUTPUT_DIR: ~/Desktop/PastScreen

Exports the app bundle into a Sparkle-ready zip, updates appcast.xml, and prints summary.
TXT
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
cd "$REPO_DIR"

APP_PATH=${1:-"$HOME/Desktop/PastScreen/PastScreen.app"}
OUTPUT_DIR=${2:-"$HOME/Desktop/PastScreen"}
APPCAST_PATH="$REPO_DIR/appcast.xml"

if [[ ! -d "$APP_PATH" ]]; then
  echo "❌ App bundle not found at: $APP_PATH" >&2
  exit 1
fi
if [[ ! -f "$APPCAST_PATH" ]]; then
  echo "❌ appcast.xml introuvable dans $REPO_DIR" >&2
  exit 1
fi

PLIST="$APP_PATH/Contents/Info.plist"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST")

mkdir -p "$OUTPUT_DIR"
ZIP_PATH="$OUTPUT_DIR/PastScreen-$VERSION.zip"
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
SIZE=$(stat -f%z "$ZIP_PATH")

SIGN_TOOL=$(ls -1d "$HOME"/Library/Developer/Xcode/DerivedData/*/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update 2>/dev/null | head -n 1 || true)
if [[ -z "$SIGN_TOOL" || ! -x "$SIGN_TOOL" ]]; then
  echo "❌ Impossible de trouver Sparkle/bin/sign_update. Build/Archive d'abord dans Xcode." >&2
  exit 1
fi

SIGN_OUTPUT=$("$SIGN_TOOL" "$ZIP_PATH")
SIGNATURE=$(echo "$SIGN_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')
LENGTH=$(echo "$SIGN_OUTPUT" | sed -n 's/.*length="\([0-9]*\)".*/\1/p')

if [[ -z "$SIGNATURE" || -z "$LENGTH" ]]; then
  echo "❌ Impossible d'extraire signature/length de sign_update" >&2
  exit 1
fi

URL="https://github.com/augiefra/PastScreen/releases/download/v$VERSION/PastScreen-$VERSION.zip"
perl -0pi -e "s|(        url=\"https://github\.com/augiefra/PastScreen/releases/download/v$VERSION/PastScreen-$VERSION\.zip\"\n        sparkle:edSignature=\")([^\"]*)(\"\n        length=\")([^\"]*)(\"\n        type=\"application/octet-stream\" />)|        url=\"$URL\"\n        sparkle:edSignature=\"$SIGNATURE\"\n        length=\"$LENGTH\"\n        type=\"application/octet-stream\" />|" "$APPCAST_PATH"

cat <<EOF

✅ Archive + appcast prêts
-----------------------------------------
App bundle : $APP_PATH
Version    : $VERSION (build $BUILD)
Zip        : $ZIP_PATH
Taille     : $SIZE
Signature  : $SIGNATURE

appcast.xml mis à jour. Il reste à :
  git add appcast.xml
  git commit -m "release: update appcast for $VERSION"
  git push public main
  Upload PastScreen-$VERSION.zip sur la release GitHub (https://github.com/augiefra/PastScreen/releases/tag/v$VERSION)
EOF
