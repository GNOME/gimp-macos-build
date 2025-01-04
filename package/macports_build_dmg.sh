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

#  target directory
export PACKAGE_DIR="${HOME}/macports-gimp${VGIMP}-osx-app-${arch}"

GIMP_VERSION="$(cat ${PACKAGE_DIR}/GIMP.app/Contents/Resources/.version)"
rm ${PACKAGE_DIR}/GIMP.app/Contents/Resources/.version

echo "Gimp version: ${GIMP_VERSION}"

echo "Move background out of app before signing"
mkdir -p /tmp/artifacts/
mv "${PACKAGE_DIR}/GIMP.app/Contents/Resources/gimp-dmg.png" /tmp/artifacts/gimp-dmg.png

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
  DMGNAME="gimp-${GIMP_VERSION}-${arch}.dmg"
else
  DMGNAME="gimp-${GIMP_VERSION}-${arch}-b${CIRCLE_BUILD_NUM}-${CIRCLE_BRANCH////-}.dmg"
fi

rm -f /tmp/tmp.dmg
rm -f "/tmp/artifacts/gimp-${GIMP_VERSION}-${arch}.dmg"

cd create-dmg

./create-dmg \
  --volname "GIMP 3.0 Install" \
  --background "/tmp/artifacts/gimp-dmg.png" \
  --window-pos 1 1 \
  --icon "GIMP.app" 192 352 \
  --window-size 640 535 \
  --icon-size 110 \
  --icon "Applications" 110 110 \
  --hide-extension "Applications" \
  --app-drop-link 448 352 \
  --format ULFO \
  --disk-image-size 1200 \
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
