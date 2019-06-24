#!/bin/sh

# set -e

if [ -z "${JHBUILD_LIBDIR}" ]
then
  echo "JHBUILD_LIBDIR undefined. Are you running inside jhbuild?"
  exit 2
fi

printf "Determining GIMP version: "

rm -f GIMP_VERSION

GIMP_VERSION="$(gimp --version | sed 's|GNU Image Manipulation Program version ||')"

echo "$GIMP_VERSION"

cat info-2.10.plist.tmpl | sed "s|%VERSION%|${GIMP_VERSION}|g" > info-2.10.plist

echo "Creating bundle"
gtk-mac-bundler gimp-2.10.bundle

BASEDIR=$(dirname "$0")

#  target directory
PACKAGE_DIR="${HOME}/gimp-osx-app"

echo "Removing pathnames from the libraries and binaries"
# fix permission for some libs
find  ${PACKAGE_DIR}/GIMP-2.10.app/Contents/Resources/lib -name '*.dylib' -type f | xargs chmod 755
# getting list of the files to fix
FILES=$(
  find ${PACKAGE_DIR}/GIMP-2.10.app -perm +111 -type f \
   | xargs file \
   | grep ' Mach-O '|awk -F ':' '{print $1}'
)
OLDPATH="${JHBUILD_LIBDIR}/"

for file in $FILES
do
  install_name_tool -id "@rpath/$(basename $file)" $file
  otool -L $file \
   | grep "\t$OLDPATH" \
   | sed "s|${OLDPATH}||" \
   | awk -v fname="$file" -v old_path="$OLDPATH" '{print "install_name_tool -change "old_path $1" @rpath/"$1" "fname}' \
   | bash
done

if [[ "$1" == "debug" ]]; then
  echo "Generating debug symbols"
  find  ${PACKAGE_DIR}/GIMP-2.10.app/ -type f -perm +111 \
     | xargs file \
     | grep ' Mach-O '|awk -F ':' '{print $1}' \
     | xargs -n1 dsymutil
fi

echo "remove @rpath to the libraries"
find  ${PACKAGE_DIR}/GIMP-2.10.app/Contents/Resources/lib/ -mindepth 1 -maxdepth 1 -perm +111 -type f \
   | xargs file \
   | grep ' Mach-O '|awk -F ':' '{print $1}' \
   | xargs -n1 install_name_tool -delete_rpath ${HOME}/gtk/inst/lib

echo "adding @rpath to the binaries"
find  ${PACKAGE_DIR}/GIMP-2.10.app/Contents/MacOS/ -type f -perm +111 \
   | xargs file \
   | grep ' Mach-O '|awk -F ':' '{print $1}' \
   | xargs -n1 install_name_tool -add_rpath @executable_path/../Resources/lib/

echo "adding @rpath to the plugins"
find  ${PACKAGE_DIR}/GIMP-2.10.app/Contents/Resources/lib/gimp/2.0/plug-ins/ -perm +111 -type f \
   | xargs file \
   | grep ' Mach-O '|awk -F ':' '{print $1}' \
   | xargs -n1 install_name_tool -add_rpath @executable_path/../../../

echo "fixing pixmap cache"
sed -i.old 's|@executable_path/../Resources/lib/||' \
    ${PACKAGE_DIR}/GIMP-2.10.app/Contents/Resources/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache

echo "fixing IMM cache"
sed -i.old 's|@executable_path/../Resources/lib/||' \
    ${PACKAGE_DIR}/GIMP-2.10.app/Contents/Resources/etc/gtk-2.0/gtk.immodules

echo "create missing links. should we use wrappers instead?"

pushd ${PACKAGE_DIR}/GIMP-2.10.app/Contents/MacOS
 ln -s gimp-console-2.10 gimp-console
 ln -s gimp-debug-tool-2.0 gimp-debug-tool
 ln -s python python2
popd

echo "copy xdg-email wrapper to the package"
cp xdg-email ${PACKAGE_DIR}/GIMP-2.10.app/Contents/MacOS

echo "Creating pyc files"
python -m compileall -q ${PACKAGE_DIR}/GIMP-2.10.app

echo "Signing libs"

if [ -n "${codesign_subject}" ]
then
  echo "Signing libraries and plugins"
  find  ${PACKAGE_DIR}/GIMP-2.10.app/Contents/Resources/lib/ -type f -perm +111 \
     | xargs file \
     | grep ' Mach-O '|awk -F ':' '{print $1}' \
     | xargs /usr/bin/codesign -s "${codesign_subject}"
  echo "Signing app"
  /usr/bin/codesign -s "${codesign_subject}" --deep ${PACKAGE_DIR}/GIMP-2.10.app
fi

echo "Building DMG"
if [ -z "${CIRCLECI}" ]
then
  DMGNAME="gimp-${GIMP_VERSION}-x86_64.dmg"
else
  DMGNAME="gimp-${GIMP_VERSION}-x86_64-b${CIRCLE_BUILD_NUM}-${CIRCLE_BRANCH}.dmg"
fi

mkdir -p /tmp/artifacts/
rm -f /tmp/tmp.dmg
rm -f "gimp-${GIMP_VERSION}-x86_64.dmg"
hdiutil create /tmp/tmp.dmg -ov -volname "GIMP 2.10 Install" -fs HFS+ -srcfolder "$PACKAGE_DIR/"
hdiutil convert /tmp/tmp.dmg -format UDBZ -o "/tmp/artifacts/${DMGNAME}"

if [ -n "${codesign_subject}" ]
then
  echo "Signing DMG"
  /usr/bin/codesign  -s "${codesign_subject}" "/tmp/artifacts/${DMGNAME}"
fi

echo "Done"
