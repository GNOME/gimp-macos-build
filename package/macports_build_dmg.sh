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
  #  target directory
  export PACKAGE_DIR="${HOME}/macports-gimp${VGIMP}-osx-app"
  export arch="arm64"
else
  build_arm64=false
  echo "*** Build: x86_64"
  #  target directory
  export PACKAGE_DIR="${HOME}/macports-gimp${VGIMP}-osx-app-x86_64"
  export arch="x86_64"
fi

GIMP_VERSION="$(cat ${PACKAGE_DIR}/GIMP.app/Contents/Resources/.version)"
rm ${PACKAGE_DIR}/GIMP.app/Contents/Resources/.version

echo "Gimp version: ${GIMP_VERSION}"

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
  find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/3.10/lib -type f -perm +111 |
    xargs file |
    grep ' Mach-O ' | awk -F ':' '{print $1}' |
    xargs /usr/bin/codesign -s "${codesign_subject}" \
      --options runtime \
      --entitlements ${HOME}/project/package/gimp-hardening.entitlements
  find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/3.10/Resources -type f -perm +111 |
    xargs file |
    grep ' Mach-O ' | awk -F ':' '{print $1}' |
    xargs /usr/bin/codesign -s "${codesign_subject}" \
      --options runtime \
      --entitlements ${HOME}/project/package/gimp-hardening.entitlements
  find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/3.10/bin -type f -perm +111 |
    xargs file |
    grep ' Mach-O ' | awk -F ':' '{print $1}' |
    xargs /usr/bin/codesign -s "${codesign_subject}" \
      --options runtime \
      --entitlements ${HOME}/project/package/gimp-hardening.entitlements
  find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/3.10/Python -type f -perm +111 |
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

mkdir -p /tmp/artifacts/
rm -f /tmp/tmp.dmg
rm -f "/tmp/artifacts/gimp-${GIMP_VERSION}-${arch}.dmg"

cd create-dmg

./create-dmg \
  --volname "GIMP 2.99 Install" \
  --background "../gimp-dmg.png" \
  --window-pos 1 1 \
  --icon "GIMP.app" 190 360 \
  --window-size 640 535 \
  --icon-size 110 \
  --icon "Applications" 110 110 \
  --hide-extension "Applications" \
  --app-drop-link 450 360 \
  --format ULFO \
  --disk-image-size 1000 \
  --hdiutil-verbose \
  "/tmp/artifacts/${DMGNAME}" \
  "$PACKAGE_DIR/"
rm -f /tmp/artifacts/rw.*.dmg
cd ..

if [ -n "${codesign_subject}" ]; then
  echo "Signing DMG"
  /usr/bin/codesign -s "${codesign_subject}" "/tmp/artifacts/${DMGNAME}"
fi

echo "Done Creating DMG"
