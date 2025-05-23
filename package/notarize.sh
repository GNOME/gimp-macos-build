#!/bin/bash

# If EXTENSION is not set, default to an empty string
EXTENSION=${EXTENSION:-""}
DMG_FILE=$(find /tmp/artifacts \( -name "gimp-3.1*arm64${EXTENSION}.dmg" -o -name "gimp-3.1*x86_64${EXTENSION}.dmg" \) 2>/dev/null)

# Validate inputs before proceeding
if [ -z "$DMG_FILE" ]; then
  echo "Error: Could not find DMG file to notarize in /tmp/artifacts"
  exit 1
fi

echo "Found DMG file: $DMG_FILE"

# Validate notarization credentials
if [ -z "$notarization_login" ]; then
  echo "Error: notarization_login environment variable is not set"
  exit 1
fi

if [ -z "$notarization_teamid" ]; then
  echo "Error: notarization_teamid environment variable is not set"
  exit 1
fi

if [ -z "$notarization_password" ]; then
  echo "Error: notarization_password environment variable is not set"
  exit 1
fi

# Print team ID for diagnosis (masked for security)
TEAM_ID_LENGTH=${#notarization_teamid}
if [ $TEAM_ID_LENGTH -gt 0 ]; then
  FIRST_CHAR="${notarization_teamid:0:1}"
  LAST_CHAR="${notarization_teamid: -1}"
  echo "Using Team ID: ${FIRST_CHAR}****${LAST_CHAR} (${TEAM_ID_LENGTH} characters)"
else
  echo "Warning: Team ID appears to be empty"
fi

# Print Apple ID for diagnosis (also masked for security)
APPLE_ID_LENGTH=${#notarization_login}
if [ $APPLE_ID_LENGTH -gt 0 ]; then
  # If it's an email, get the part before @ and mask most of it
  if [[ "$notarization_login" == *"@"* ]]; then
    USERNAME="${notarization_login%@*}"
    DOMAIN="${notarization_login#*@}"

    USERNAME_LENGTH=${#USERNAME}
    if [ $USERNAME_LENGTH -gt 2 ]; then
      MASKED_USERNAME="${USERNAME:0:1}****${USERNAME: -1}"
    else
      MASKED_USERNAME="****"
    fi

    echo "Using Apple ID: ${MASKED_USERNAME}@${DOMAIN} (${APPLE_ID_LENGTH} characters)"
  else
    # Not an email, just mask the middle
    FIRST_CHAR="${notarization_login:0:1}"
    LAST_CHAR="${notarization_login: -1}"
    echo "Using Apple ID: ${FIRST_CHAR}****${LAST_CHAR} (${APPLE_ID_LENGTH} characters)"
  fi
else
  echo "Warning: Apple ID appears to be empty"
fi

echo "Checking notarization credentials..."
xcrun altool --list-certified-teams \
  -u "$notarization_login" \
  -p "$notarization_password"

echo "Submitting for notarization..."
NOTARY_OUT="$(xcrun notarytool submit "${DMG_FILE}" --apple-id "${notarization_login}" --team-id "${notarization_teamid}" --password "${notarization_password}" --wait 2>&1)"

echo "$NOTARY_OUT"

# Extract Request UUID
REQUEST_UUID=$(echo "$NOTARY_OUT" | grep -oE "id: [0-9a-f-]+" | head -n 1 | awk '{print $2}')

if [ -z "$REQUEST_UUID" ]; then
  echo "Failed finding Request UUID in notarytool output"

  # Check for specific error messages that might indicate team ID issues
  if echo "$NOTARY_OUT" | grep -q "HTTP status code: 403"; then
    echo "ERROR: Authorization failed - Team ID issue detected."
    echo "Please verify:"
    echo "1. Your Apple Developer membership is active and not expired"
    echo "2. The Apple ID is correctly associated with the Team ID"
    echo "3. The Team ID value is correct (currently ${TEAM_ID_LENGTH} characters)"
    echo "4. You have the necessary permissions within the team"
  fi

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

xcrun stapler staple -v ${DMG_FILE}
