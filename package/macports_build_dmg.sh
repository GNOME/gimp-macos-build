#!/bin/bash

# set -e

if [ -z "$1" ]; then
  ARCH="x86_64"
else
  ARCH="$1"
fi

if [[ "$ARCH" == 'arm64' ]]; then
  build_arm64=true
  export arch="arm64"
else
  build_arm64=false
  export arch="x86_64"
fi
echo "*** Build: $arch"

# If EXTENSION is not set, default to an empty string
EXTENSION=${EXTENSION:-""}
#  target directory
export PACKAGE_DIR="${HOME}/macports-gimp-osx-app-${arch}${EXTENSION}"

GIMP_VERSION="$(cat ${PACKAGE_DIR}/GIMP.app/Contents/Resources/.version)"
echo "Gimp version: ${GIMP_VERSION}"

echo "Setup /tmp/artifacts"
mkdir -p /tmp/artifacts/

# Create a temporary python.coderequirement with proper signing values
create_coderequirement_file() {
  local req_file="${HOME}/project/package/python.coderequirement"

  if [ -n "${notarization_teamid}" ]; then
    cat > "$req_file" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>signing-identifier</key>
    <string>org.gimp.gimp</string>
    <key>team-identifier</key>
    <string>${notarization_teamid}</string>
</dict>
</plist>
EOF
    echo "Created python.coderequirement file with proper signing values"
  else
    echo "Warning: Could not determine team identifier for coderequirement"
  fi
}

echo "Signing libs"

if [ -n "${codesign_subject}" ]; then
  echo "Signing libraries and plugins"
  find "${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/" \
    -type f -perm +111 \
    ! -path "*/DWARF/*" ! -path "*/.dSYM/*" |
    xargs file | grep ' Mach-O ' | awk -F ':' '{print $1}' |
    xargs /usr/bin/codesign -s "${codesign_subject}" \
      --options runtime \
      --entitlements "${HOME}/project/package/gimp-hardening.entitlements"

  find "${PACKAGE_DIR}/GIMP.app/Contents/Resources/libexec/" \
    -type f -perm +111 \
    ! -path "*/DWARF/*" ! -path "*/.dSYM/*" |
    xargs file | grep ' Mach-O ' | awk -F ':' '{print $1}' |
    xargs /usr/bin/codesign -s "${codesign_subject}" \
      --options runtime \
      --entitlements "${HOME}/project/package/gimp-hardening.entitlements"

  echo "Securing Python"

  find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/${PYTHON_VERSION}/lib -type f -perm +111 |
    xargs file |
    grep ' Mach-O ' | awk -F ':' '{print $1}' |
    xargs /usr/bin/codesign -s "${codesign_subject}" \
      --options runtime \
      --entitlements ${HOME}/project/package/gimp-hardening.entitlements

  # Create a secure python.coderequirement file with real values
  create_coderequirement_file

  find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/${PYTHON_VERSION}/Resources -type f -perm +111 |
    xargs file | grep 'Mach-O' | awk -F ':' '{print $1}' |
    while read -r bin; do
      /usr/bin/codesign -s "${codesign_subject}" \
        --options runtime \
        --timestamp \
        --launch-constraint-parent "${HOME}/project/package/python.coderequirement" \
        "$bin"
    done


  find "${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/${PYTHON_VERSION}/bin" -type f -perm +111 |
    xargs file | grep 'Mach-O' | awk -F ':' '{print $1}' |
    while read -r bin; do
      /usr/bin/codesign -s "${codesign_subject}" \
        --options runtime \
        --timestamp \
        --launch-constraint-parent "${HOME}/project/package/python.coderequirement" \
        "$bin"
    done

  for bin in \
    "${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/${PYTHON_VERSION}/Python" \
    "${PACKAGE_DIR}/GIMP.app/Contents/MacOS/python${PYTHON_VERSION}" \
    "${PACKAGE_DIR}/GIMP.app/Contents/MacOS/xdg-email"; do
    if [ -f "$bin" ]; then
      echo "Signing $bin with launch constraint"
      /usr/bin/codesign -s "${codesign_subject}" \
        --options runtime \
        --timestamp \
        --launch-constraint-parent "${HOME}/project/package/python.coderequirement" \
        "$bin"
    fi
  done

  rm -f "${HOME}/project/package/python.coderequirement"

  echo "Signing app"
  /usr/bin/codesign -s "${codesign_subject}" \
    --timestamp \
    --deep \
    --options runtime \
    --preserve-metadata=requirements \
    --entitlements ${HOME}/project/package/gimp-hardening.entitlements \
    ${PACKAGE_DIR}/GIMP.app
fi

echo "Building DMG"
if [ -z "${CIRCLECI}" ]; then
  DMGNAME="gimp-${GIMP_VERSION}-${arch}${EXTENSION}.dmg"
else
  DMGNAME="gimp-${GIMP_VERSION}-b${CIRCLE_BUILD_NUM}-${CIRCLE_BRANCH////-}-${arch}${EXTENSION}.dmg"
fi

rm -f /tmp/tmp.dmg
echo "***Deleting /tmp/artifacts/${DMGNAME}"
rm -f "/tmp/artifacts/${DMGNAME}"
echo "***Deleting /tmp/artifacts/rw.${DMGNAME}.sparseimage"
rm -f "/tmp/artifacts/rw.${DMGNAME}.sparseimage"

cd create-dmg

./create-dmg \
  --volname "GIMP ${GIMP_VERSION} Install" \
  --background "${PACKAGE_DIR}/GIMP.app/Contents/Resources/gimp-dmg.png" \
  --window-pos 1 1 \
  --icon "GIMP.app" 192 352 \
  --window-size 640 535 \
  --icon-size 110 \
  --icon "Applications" 110 110 \
  --hide-extension "Applications" \
  --app-drop-link 448 352 \
  --format ULFO \
  --disk-image-size 1500 \
  --hdiutil-verbose \
  "/tmp/artifacts/${DMGNAME}" \
  "$PACKAGE_DIR/"
rm -f /tmp/artifacts/rw.*.dmg
rm -f /tmp/artifacts/gimp-dmg.png
cd ..

if [ -n "${codesign_subject}" ]; then
  echo "Signing DMG"
  /usr/bin/codesign -s "${codesign_subject}" "/tmp/artifacts/${DMGNAME}"
fi

echo "Done Creating DMG"
