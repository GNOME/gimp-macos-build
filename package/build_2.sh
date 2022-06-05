#!/bin/sh

# set -e

if [ -z "${JHBUILD_LIBDIR}" ]
then
  echo "JHBUILD_LIBDIR undefined. Are you running inside jhbuild?"
  exit 2
fi

if [ -z "$1" ]; then
  ARCH="x86_64"
else
  ARCH="$1"
fi

#  target directory
PACKAGE_DIR="${HOME}/gimp299-osx-app"

GIMP_VERSION="$(cat ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/.version)"
rm ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/.version

echo "Gimp version: ${GIMP_VERSION}"
echo "Signing libs"

if [ -n "${codesign_subject}" ]
then
  echo "Signing libraries and plugins"
  find  ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/lib/ -type f -perm +111 \
     | xargs file \
     | grep ' Mach-O '|awk -F ':' '{print $1}' \
     | xargs /usr/bin/codesign -s "${codesign_subject}" \
         --options runtime \
         --entitlements ${HOME}/project/package/gimp-hardening.entitlements
  echo "Signing app"
  /usr/bin/codesign -s "${codesign_subject}" \
    --timestamp \
    --deep \
    --options runtime \
    --entitlements ${HOME}/project/package/gimp-hardening.entitlements \
    ${PACKAGE_DIR}/GIMP-2.99.app
fi

echo "Building DMG"
if [ -z "${CIRCLECI}" ]
then
  DMGNAME="gimp-${GIMP_VERSION}-${ARCH}.dmg"
else
  DMGNAME="gimp-${GIMP_VERSION}-${ARCH}-b${CIRCLE_BUILD_NUM}-${CIRCLE_BRANCH////-}.dmg"
fi

mkdir -p /tmp/artifacts/
rm -f /tmp/tmp.dmg
rm -f "/tmp/artifacts/gimp-${GIMP_VERSION}-${ARCH}.dmg"

cd create-dmg

# --skip-jenkins doesn't try to do applescript formatting
./create-dmg \
  --volname "GIMP 2.99 Install" \
  --background "../gimp-dmg.png" \
  --window-pos 1 1 \
  --icon "GIMP-2.99.app" 190 360 \
  --window-size 640 480 \
  --icon-size 110 \
  --icon "Applications" 110 110 \
  --hide-extension "Applications" \
  --app-drop-link 450 360 \
  --format UDBZ \
  --hdiutil-verbose \
  "/tmp/artifacts/${DMGNAME}" \
  "$PACKAGE_DIR/"
rm -f /tmp/artifacts/rw.*.dmg
cd ..

if [ -n "${codesign_subject}" ]
then
  echo "Signing DMG"
  /usr/bin/codesign  -s "${codesign_subject}" "/tmp/artifacts/${DMGNAME}"
fi

echo "Done Creating DMG"
