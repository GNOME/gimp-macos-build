#!/bin/bash

DMG_FILE=$(find /tmp/artifacts/ -name "gimp-2.10*.dmg")

# Submit for notarization
NOTARY_OUT="$(xcrun notarytool submit ${DMG_FILE} --apple-id ${notarization_login} --team-id ${notarization_teamid} --password ${notarization_password} --wait 2>&1)"

echo "$NOTARY_OUT"

# Extract Request UUID
SUBMISSION_ID=$(echo "$NOTARY_OUT" | grep -oE "id: [0-9a-f-]+" | awk '{print $2}')

if [ -z "$SUBMISSION_ID" ]; then
  echo "Failed finding Request UUID in notarytool output"
  exit 1
fi

echo "Submission ID: $SUBMISSION_ID"

NOT_STATUS=$(echo "$NOTARY_OUT" | grep status: | awk -F ": " '{print $NF}')

if [[ "$NOT_STATUS" == Accepted* ]]; then
  echo "Notarization succeeded. Showing log"
else
  echo "Notarization failed with status: $NOT_STATUS. Showing log"
fi

xcrun notarytool log --apple-id ${notarization_login} --team-id ${notarization_teamid} --password ${notarization_password}

if [[ "$NOT_STATUS" != Accepted* ]]; then
  exit 1
fi

xcrun stapler staple -v ${DMG_FILE}
