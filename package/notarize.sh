#!/bin/bash

# If EXTENSION is not set, default to an empty string
EXTENSION=${EXTENSION:-""}
DMG_FILE=$(find /tmp/artifacts \( -name "gimp-3.*arm64${EXTENSION}.dmg" -o -name "gimp-3.*x86_64${EXTENSION}.dmg" \) 2>/dev/null)

if [ ! -f "$DMG_FILE" ]; then
  echo "Error: Could not find DMG file to notarize in /tmp/artifacts"
  exit 1
fi

echo "Found DMG file: $DMG_FILE"

# Submit for notarization
echo "Submitting for notarization..."
NOTARY_OUT="$(xcrun notarytool submit ${DMG_FILE} --apple-id ${notarization_login} --team-id ${notarization_teamid} --password ${notarization_password} --wait 2>&1)"

echo "$NOTARY_OUT"

# Extract Request UUID
REQUEST_UUID=$(echo "$NOTARY_OUT" | grep -oE "id: [0-9a-f-]+" | head -n 1 | awk '{print $2}')

if [ -z "$REQUEST_UUID" ]; then
  echo "Failed finding Request UUID in notarytool output"
  exit 1
fi

echo "Request UUID: $REQUEST_UUID"

NOT_STATUS=$(echo "$NOTARY_OUT" | grep status: | awk -F ": " '{print $NF}')

if [[ "$NOT_STATUS" == Accepted* ]]; then
  echo "Notarization succeeded. Showing log"
else
  echo "Notarization failed with status: $NOT_STATUS. Showing log"
fi

xcrun notarytool log --apple-id "${notarization_login}" --team-id "${notarization_teamid}" --password "${notarization_password}" "$REQUEST_UUID"

if [[ "$NOT_STATUS" != Accepted* ]]; then
  exit 1
fi

echo "Stapling the notarization ticket to the DMG..."
xcrun stapler staple -v ${DMG_FILE}

if [ $? -eq 0 ]; then
  echo "Successfully stapled notarization ticket to DMG file"
else
  echo "Failed to staple notarization ticket to DMG file"
  exit 1
fi

echo "Notarization process completed successfully"
