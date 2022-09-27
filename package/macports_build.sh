#!/bin/sh

# set -e

PREFIX=/opt/local
if [[ $(uname -m) == 'arm64' ]]; then
  build_arm64=true
  echo "*** Build: arm64"
  #  target directory
  export PACKAGE_DIR="${HOME}/macports-gimp299-osx-app"
  export arch="arm64"
else
  build_arm64=false
  echo "*** Build: x86_64"
  #  target directory
  export PACKAGE_DIR="${HOME}/macports-gimp299-osx-app-x86_64"
  export arch="x86_64"
fi
export JHBUILD_PREFIX=${PREFIX}
GTK_MAC_BUNDLER=${HOME}/.local/bin/gtk-mac-bundler

printf "Determining GIMP version: "

GIMP_VERSION="$(${PREFIX}/bin/gimp --version 2>/dev/null | grep 'GNU Image Manipulation Program version' | sed 's|GNU Image Manipulation Program version ||')"
# for gtk-mac-bundler

echo "$GIMP_VERSION"

cat info.plist.tmpl | sed "s|%VERSION%|${GIMP_VERSION}|g" > info.plist

echo "Copying charset.alias"
sudo cp -f "/usr/lib/charset.alias" "${PREFIX}/lib/"

echo "Creating bundle"
$GTK_MAC_BUNDLER macports-gimp.bundle
echo "Done creating bundle"

BASEDIR=$(dirname "$0")

echo "Link 'Resources' into python framework 'Resources'"
pushd "${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/3.10/Resources/Python.app/Contents/Resources/"
  for resources in etc gimp.icns lib share xcf.icns ;
  do
ln -s "../../../../../../../../../${resources}" \
      "${resources}"
  done
popd

echo "Removing pathnames from the libraries and binaries"
# fix permission for some libs
find  ${PACKAGE_DIR}/GIMP.app/Contents/Resources \( -name '*.dylib' -o -name '*.so' \) -type f | xargs chmod 755
# getting list of the files to fix
FILES=$(
  find ${PACKAGE_DIR}/GIMP.app -perm +111 -type f \
   | xargs file \
   | grep ' Mach-O '|awk -F ':' '{print $1}'
)

OLDPATH="${PREFIX}/"

for file in $FILES
do
  id_path=$(echo "$file" | sed -E "s|${PACKAGE_DIR}/GIMP.app/Contents/(Resources\|MacOS)/||")
  install_name_tool -id "@rpath/"$id_path $file
  otool -L $file \
   | grep "\t$OLDPATH" \
   | sed "s|${OLDPATH}||" \
   | awk -v fname="$file" -v old_path="$OLDPATH" '{print "install_name_tool -change "old_path $1" @rpath/"$1" "fname}' \
   | bash
done

echo "adding @rpath to the binaries (incl special ghostscript 9.56 fix)"
find  ${PACKAGE_DIR}/GIMP.app/Contents/MacOS -type f -perm +111 \
   | xargs file \
   | grep ' Mach-O ' |awk -F ':' '{print $1}' \
   | xargs -n1 install_name_tool -add_rpath @executable_path/../Resources/ -change libgs.dylib.9.56 @rpath/libgs.dylib.9.56

echo "adding @rpath to the plugins (incl special ghostscript 9.56 fix)"
find  ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/gimp/2.99/plug-ins/ -perm +111 -type f \
   | xargs file \
   | grep ' Mach-O '|awk -F ':' '{print $1}' \
   | xargs -n1 install_name_tool -add_rpath @executable_path/../../../../../ -change libgs.dylib.9.56 @rpath/libgs.dylib.9.56

echo "adding @rpath to the extensions (incl special ghostscript 9.56 fix)"
find  ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/gimp/2.99/extensions/ -perm +111 -type f \
   | xargs file \
   | grep ' Mach-O '|awk -F ':' '{print $1}' \
   | xargs -n1 install_name_tool -add_rpath @executable_path/../../../../../ -change libgs.dylib.9.56 @rpath/libgs.dylib.9.56

echo "adding @rpath to python app"
install_name_tool -add_rpath @loader_path/../../../../../../../../../ \
  ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/3.10/Resources/Python.app/Contents/MacOS/Python
install_name_tool -add_rpath @loader_path/../../../../../ \
  ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/3.10/Python

echo "removing build path from the .gir files"
find  ${PACKAGE_DIR}/GIMP.app/Contents/Resources/share/gir-1.0/*.gir \
   -exec sed -i '' "s|${OLDPATH}||g" {} +

echo "removing previous rpath from the .gir files (in case it's there)"
find  ${PACKAGE_DIR}/GIMP.app/Contents/Resources/share/gir-1.0/*.gir \
   -exec sed -i '' "s|@rpath/||g" {} +

echo "adding @rpath to the .gir files"
find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/share/gir-1.0/*.gir \
   -exec sed -i '' 's|[a-z0-9/\._-]*.dylib|@rpath/&|g' {} +

echo "generating .typelib files with @rpath"
find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/share/gir-1.0/*.gir | while IFS= read -r pathname; do
    base=$(basename "$pathname")
    g-ir-compiler --includedir=${PACKAGE_DIR}/GIMP.app/Contents/Resources/share/gir-1.0 ${pathname} -o ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/girepository-1.0/${base/.gir/.typelib}
done

echo "fixing pixmap cache"
sed -i.old 's|@executable_path/../Resources/||' \
    ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
# Works around gdk-pixbuf loader bug for release builds only https://gitlab.gnome.org/GNOME/gdk-pixbuf/-/issues/217
mkdir -p "${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/gimp/2.99/plug-ins/Resources/lib"
pushd ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/gimp/2.99/plug-ins/Resources/lib
  ln -s ../../../../../gdk-pixbuf-2.0 gdk-pixbuf-2.0
popd

echo "fixing IMM cache"
sed -i.old 's|@executable_path/../Resources/||' \
    ${PACKAGE_DIR}/GIMP.app/Contents/Resources/etc/gtk-3.0/gtk.immodules

if [[ "$1" == "debug" ]]; then
  echo "Generating debug symbols"
  find  ${PACKAGE_DIR}/GIMP.app/ -type f -perm +111 \
     | xargs file \
     | grep ' Mach-O '|awk -F ':' '{print $1}' \
     | xargs -n1 dsymutil
fi

echo "create missing links. should we use wrappers instead?"

pushd ${PACKAGE_DIR}/GIMP.app/Contents/MacOS
  ln -s gimp-console-2.99 gimp-console
  ln -s gimp-debug-tool-2.99 gimp-debug-tool
  ln -s python3.10 python
  ln -s python3.10 python3
popd

echo "copy xdg-email wrapper to the package"
mkdir -p ${PACKAGE_DIR}/GIMP.app/Contents/MacOS
cp xdg-email ${PACKAGE_DIR}/GIMP.app/Contents/MacOS

echo "Creating pyc files"
python3.10 -m compileall -q ${PACKAGE_DIR}/GIMP.app

echo "Fix adhoc signing (M1 Macs)"
for file in $FILES
do
   error_message=$(/usr/bin/codesign -v "$file" 2>&1)
   if [[ "${error_message}" == *"invalid signature"* ]]
   then
     /usr/bin/codesign --sign - --force --preserve-metadata=entitlements,requirements,flags,runtime "$file"
   fi
done

echo "Signing libs"

if [ -n "${codesign_subject}" ]
then
  echo "Signing libraries and plugins"
  find  ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/ -type f -perm +111 \
     | xargs file \
     | grep ' Mach-O '|awk -F ':' '{print $1}' \
     | xargs /usr/bin/codesign -s "${codesign_subject}" \
         --options runtime \
         --entitlements ${HOME}/project/package/gimp-hardening.entitlements
  find  ${PACKAGE_DIR}/GIMP.app/Contents/Resources/libexec/ -type f -perm +111 \
     | xargs file \
     | grep ' Mach-O '|awk -F ':' '{print $1}' \
     | xargs /usr/bin/codesign -s "${codesign_subject}" \
         --options runtime \
         --entitlements ${HOME}/project/package/gimp-hardening.entitlements
  find  ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/3.10/lib -type f -perm +111 \
     | xargs file \
     | grep ' Mach-O '|awk -F ':' '{print $1}' \
     | xargs /usr/bin/codesign -s "${codesign_subject}" \
         --options runtime \
         --entitlements ${HOME}/project/package/gimp-hardening.entitlements
  find  ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/3.10/Resources -type f -perm +111 \
     | xargs file \
     | grep ' Mach-O '|awk -F ':' '{print $1}' \
     | xargs /usr/bin/codesign -s "${codesign_subject}" \
         --options runtime \
         --entitlements ${HOME}/project/package/gimp-hardening.entitlements
  find  ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/3.10/bin -type f -perm +111 \
     | xargs file \
     | grep ' Mach-O '|awk -F ':' '{print $1}' \
     | xargs /usr/bin/codesign -s "${codesign_subject}" \
         --options runtime \
         --entitlements ${HOME}/project/package/gimp-hardening.entitlements
  find  ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/3.10/Python -type f -perm +111 \
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
    ${PACKAGE_DIR}/GIMP.app
fi

echo "Building DMG"
if [ -z "${CIRCLECI}" ]
then
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

echo "Done"
