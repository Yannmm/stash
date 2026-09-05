#!/bin/bash

set -euo pipefail

PROJECT="Stash.xcodeproj"
SCHEME="Stash"
CONFIGURATION="GitHub Release"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/github-release"
DERIVED_DATA_DIR="$BUILD_DIR/DerivedData"
DMG_SOURCE="$BUILD_DIR/dmg-source"

cd "$PROJECT_ROOT"

echo "==> Reading version..." >&2

VERSION=$(
    xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -showBuildSettings 2>/dev/null |
    awk -F ' = ' '/MARKETING_VERSION/ { print $2; exit }'
)

if [[ -z "$VERSION" ]]; then
    echo "ERROR: Could not determine MARKETING_VERSION" >&2
    exit 1
fi

APP_NAME="Nustash.app"
DMG_NAME="Nustash-$VERSION.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

echo "    Version: $VERSION" >&2
echo "    Configuration: $CONFIGURATION" >&2

echo "==> Cleaning previous build..." >&2

rm -rf "$BUILD_DIR"
mkdir -p "$DMG_SOURCE"

echo "==> Building Nustash..." >&2

xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA_DIR" \
    build \
    > /dev/null

APP_PATH="$DERIVED_DATA_DIR/Build/Products/$CONFIGURATION/$APP_NAME"

if [[ ! -d "$APP_PATH" ]]; then
    echo "ERROR: App not found:" >&2
    echo "$APP_PATH" >&2
    exit 1
fi

echo "==> Creating DMG..." >&2

cp -R "$APP_PATH" "$DMG_SOURCE/"

#/opt/homebrew/bin/create-dmg \
#    --volname "Nustash" \
#    --app-drop-link 600 200 \
#    --icon "$APP_NAME" 200 200 \
#    --overwrite \
#    "$DMG_PATH" \
#    "$DMG_SOURCE" \
#    > /dev/null

DMG_WINDOW_WIDTH=800
DMG_WINDOW_HEIGHT=450
DMG_ICON_SIZE=128

DMG_APP_X=250
DMG_APP_Y=225

DMG_APPLICATIONS_X=550
DMG_APPLICATIONS_Y=225

/opt/homebrew/bin/create-dmg \
    --volname "Nustash" \
    --window-size "$DMG_WINDOW_WIDTH" "$DMG_WINDOW_HEIGHT" \
    --icon-size "$DMG_ICON_SIZE" \
    --icon "$APP_NAME" "$DMG_APP_X" "$DMG_APP_Y" \
    --app-drop-link "$DMG_APPLICATIONS_X" "$DMG_APPLICATIONS_Y" \
    --hide-extension "$APP_NAME" \
    --overwrite \
    "$DMG_PATH" \
    "$DMG_SOURCE" \
    > /dev/null

if [[ ! -f "$DMG_PATH" ]]; then
    echo "ERROR: DMG was not created:" >&2
    echo "$DMG_PATH" >&2
    exit 1
fi

echo "==> Build complete." >&2
echo "    DMG: $DMG_PATH" >&2

# IMPORTANT:
# stdout contains only the DMG path so callers can do:
#   DMG=$(./scripts/build-github-release.sh)
printf '%s\n' "$DMG_PATH"

