#!/bin/bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <dmg-path>" >&2
    exit 1
fi

DMG_PATH="$1"

if [[ ! -f "$DMG_PATH" ]]; then
    echo "ERROR: DMG not found:" >&2
    echo "$DMG_PATH" >&2
    exit 1
fi

if [[ "${DMG_PATH##*.}" != "dmg" ]]; then
    echo "ERROR: File does not have a .dmg extension:" >&2
    echo "$DMG_PATH" >&2
    exit 1
fi

DMG_NAME="$(basename "$DMG_PATH")"

# Expected format:
#   Nustash-3.1.1.dmg
#
# Extract the version from the filename.
VERSION="${DMG_NAME#Nustash-}"
VERSION="${VERSION%.dmg}"

if [[ -z "$VERSION" || "$VERSION" == "$DMG_NAME" ]]; then
    echo "ERROR: Could not determine version from DMG filename:" >&2
    echo "$DMG_NAME" >&2
    echo "Expected format: Nustash-3.1.1.dmg" >&2
    exit 1
fi

TAG="v$VERSION"

echo "==> GitHub Release" >&2
echo "    Version: $VERSION" >&2
echo "    Tag:     $TAG" >&2
echo "    DMG:     $DMG_PATH" >&2

echo >&2
echo "==> Checking GitHub authentication..." >&2

gh auth status >&2

echo >&2
echo "==> Creating GitHub Release..." >&2

if gh release view "$TAG" >/dev/null 2>&1; then
    echo "==> Release $TAG already exists" >&2
    echo "==> Replacing DMG..." >&2

    gh release upload "$TAG" "$DMG_PATH" --clobber
else
    echo "==> Creating GitHub Release..." >&2

    gh release create "$TAG" \
        "$DMG_PATH" \
        --generate-notes \
        --title "Nustash $VERSION"
fi

echo >&2
echo "========================================" >&2
echo "GitHub Release created successfully!" >&2
echo "========================================" >&2
echo "Version: $VERSION" >&2
echo "DMG:     $DMG_PATH" >&2
