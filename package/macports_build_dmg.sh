#!/bin/bash

# set -e

if [ -z "$1" ]; then
  ARCH="x86_64"
else
  ARCH="$1"
fi

if [[ "$ARCH" == 'arm64' ]]; then
  build_arm64=true
  echo "*** Build: arm64"
  export arch="arm64"
else
  build_arm64=false
  echo "*** Build: x86_64"
  export arch="x86_64"
fi

# If EXTENSION is not set, default to an empty string
EXTENSION=${EXTENSION:-""}
#  target directory
export PACKAGE_DIR="${HOME}/macports-gimp${VGIMP}-osx-app-${arch}${EXTENSION}"

GIMP_VERSION="$(cat ${PACKAGE_DIR}/GIMP.app/Contents/Resources/.version)"
echo "Gimp version: ${GIMP_VERSION}"

echo "Setup /tmp/artifacts"
mkdir -p /tmp/artifacts/

echo "Signing libs"

if [ -n "${codesign_subject}" ]; then
  echo "Signing libraries and plugins"
  find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/ -type f -perm +111 |
    xargs file |
    grep ' Mach-O ' | awk -F ':' '{print $1}' |
    xargs /usr/bin/codesign -s "${codesign_subject}" \
      --options runtime \
      --entitlements ${HOME}/project/package/gimp-hardening.entitlements
  find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/libexec/ -type f -perm +111 |
    xargs file |
    grep ' Mach-O ' | awk -F ':' '{print $1}' |
    xargs /usr/bin/codesign -s "${codesign_subject}" \
      --options runtime \
      --entitlements ${HOME}/project/package/gimp-hardening.entitlements
  find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/${PYTHON_VERSION}/lib -type f -perm +111 |
    xargs file |
    grep ' Mach-O ' | awk -F ':' '{print $1}' |
    xargs /usr/bin/codesign -s "${codesign_subject}" \
      --options runtime \
      --entitlements ${HOME}/project/package/gimp-hardening.entitlements
  find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/${PYTHON_VERSION}/Resources -type f -perm +111 |
    xargs file |
    grep ' Mach-O ' | awk -F ':' '{print $1}' |
    xargs /usr/bin/codesign -s "${codesign_subject}" \
      --options runtime \
      --entitlements ${HOME}/project/package/gimp-hardening.entitlements
  find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/${PYTHON_VERSION}/bin -type f -perm +111 |
    xargs file |
    grep ' Mach-O ' | awk -F ':' '{print $1}' |
    xargs /usr/bin/codesign -s "${codesign_subject}" \
      --options runtime \
      --entitlements ${HOME}/project/package/gimp-hardening.entitlements
  find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/${PYTHON_VERSION}/Python -type f -perm +111 |
    xargs file |
    grep ' Mach-O ' | awk -F ':' '{print $1}' |
    xargs /usr/bin/codesign -s "${codesign_subject}" \
      --options runtime \
      --entitlements ${HOME}/project/package/gimp-hardening.entitlements
  echo "Signing app"
  /usr/bin/codesign -s "${codesign_subject}" \
    --timestamp \
    --deep \
    --options runtime \
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
  --volname "GIMP 3.0 Install" \
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
