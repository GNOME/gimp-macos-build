#!/bin/bash

echo "Calculating checksum"
# If EXTENSION is not set, default to an empty string
EXTENSION=${EXTENSION:-""}
DMG_FILE=$(find /tmp/artifacts \( -name "gimp-3.1*arm64${EXTENSION}.dmg" -o -name "gimp-3.1*x86_64${EXTENSION}.dmg" \) 2>/dev/null)
shasum -a 256 "${DMG_FILE}" > "${DMG_FILE}.sha256"
echo "Checksum: $(cat "${DMG_FILE}.sha256")"
