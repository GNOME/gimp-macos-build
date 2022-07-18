#!/bin/sh

# set -e

# if [ -z "${JHBUILD_LIBDIR}" ]
# then
#   echo "JHBUILD_LIBDIR undefined. Are you running inside jhbuild?"
#   exit 2
# fi
PREFIX=$HOME/homebrew
export JHBUILD_PREFIX=${PREFIX}
GTK_MAC_BUNDLER=${HOME}/.local/bin/gtk-mac-bundler

printf "Determining GIMP version: "

$(cd ${PREFIX}/bin/ && ln -sf gimp-2.99 gimp)

GIMP_VERSION="$(gimp-2.99 --version | sed 's|GNU Image Manipulation Program version ||')"
# for gtk-mac-bundler
export GIMP_CELLAR="${PREFIX}/Cellar/gimp3/${GIMP_VERSION}"

echo "$GIMP_VERSION"

cat info-2.99.plist.tmpl | sed "s|%VERSION%|${GIMP_VERSION}|g" > info-2.99.plist

echo "Copying charset.alias"
cp -f "/usr/lib/charset.alias" "${PREFIX}/lib/"

echo "Brew link keg-only formulas"
brew link --force icu4c

echo "Creating bundle"
$GTK_MAC_BUNDLER brew-gimp-2.99.bundle
echo "Done creating bundle"

BASEDIR=$(dirname "$0")

#  target directory
PACKAGE_DIR="${HOME}/brew-gimp299-osx-app"

echo "Remove files in Cellar dir as they are duplicate"
rm -rf ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/Cellar

echo "Removing pathnames from the libraries and binaries"
# fix permission for some libs
find  ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources \( -name '*.dylib' -o -name '*.so' \) -type f | xargs chmod 755
# getting list of the files to fix
FILES=$(
  find ${PACKAGE_DIR}/GIMP-2.99.app -perm +111 -type f \
   | xargs file \
   | grep ' Mach-O '|awk -F ':' '{print $1}'
)

OLDPATH="${PREFIX}/"

# Cellar/babl+something@3.9/0.1.92_5/
# This regex is very fiddly, because of + and @ symbols and multiple regex engines
CELLAR_SUFFIX="Cellar/([@+-_a-zA-Z0-9]+)/[._0-9]+/"
CELLAR="${OLDPATH}${CELLAR_SUFFIX}"

for file in $FILES
do
  id_path=$(echo "$file" | sed -E "s|${PACKAGE_DIR}/GIMP-2.99.app/Contents/(Resources\|MacOS)/||")
  echo "@rpath/"$id_path $file
  install_name_tool -id "@rpath/"$id_path $file
  otool -L $file \
   | grep -E "\t${CELLAR}" \
   | gawk -v fname="$file" -v cellar="${CELLAR}" \
     '{print "install_name_tool -change "$1" @rpath/"gensub(cellar, "opt/\\1/", "1", $1)" "fname}' \
   | bash
  otool -L $file \
   | grep "\t$OLDPATH" \
   | sed "s|${OLDPATH}||" \
   | awk -v fname="$file" -v old_path="$OLDPATH" '{print "install_name_tool -change "old_path $1" @rpath/"$1" "fname}' \
   | bash
done

echo "remove @rpath from the libraries"
find  ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources -mindepth 1 -maxdepth 1 -perm +111 -type f \
   | xargs file \
   | grep ' Mach-O '|awk -F ':' '{print $1}' \
   | xargs -n1 install_name_tool -delete_rpath ${PREFIX}

echo "adding @rpath to the binaries (incl special ghostscript 9.56 fix)"
find  ${PACKAGE_DIR}/GIMP-2.99.app/Contents/MacOS -type f -perm +111 \
   | xargs file \
   | grep ' Mach-O ' |awk -F ':' '{print $1}' \
   | xargs -n1 install_name_tool -add_rpath @executable_path/../Resources/ -change libgs.dylib.9.56 @rpath/libgs.dylib.9.56

echo "adding @rpath to the plugins (incl special ghostscript 9.56 fix)"
find  ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/lib/gimp/2.99/plug-ins/ -perm +111 -type f \
   | xargs file \
   | grep ' Mach-O '|awk -F ':' '{print $1}' \
   | xargs -n1 install_name_tool -add_rpath @executable_path/../../../../../ -change libgs.dylib.9.56 @rpath/libgs.dylib.9.56

echo "removing build path from the .gir files"
find  ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/share/gir-1.0/*.gir \
   -exec sed -i '' "s|${OLDPATH}||g" {} +

echo "removing previous rpath from the .gir files (in case it's there)"
find  ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/share/gir-1.0/*.gir \
   -exec sed -i '' "s|@rpath/||g" {} +

echo "adding @rpath to the .gir files"
find ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/share/gir-1.0/*.gir \
   -exec sed -i '' 's|[a-z0-9/\._-]*.dylib|@rpath/&|g' {} +

echo "generating .typelib files with @rpath"
find ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/share/gir-1.0/*.gir | while IFS= read -r pathname; do
    base=$(basename "$pathname")
    g-ir-compiler --includedir=${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/share/gir-1.0 ${pathname} -o ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/lib/girepository-1.0/${base/.gir/.typelib}
done

echo "fixing pixmap cache"
sed -i.old 's|@executable_path/../Resources/||' \
    ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache

echo "fixing IMM cache"
sed -i.old 's|@executable_path/../Resources/||' \
    ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/etc/gtk-3.0/gtk.immodules

if [[ "$1" == "debug" ]]; then
  echo "Generating debug symbols"
  find  ${PACKAGE_DIR}/GIMP-2.99.app/ -type f -perm +111 \
     | xargs file \
     | grep ' Mach-O '|awk -F ':' '{print $1}' \
     | xargs -n1 dsymutil
fi

echo "create missing links. should we use wrappers instead?"

pushd ${PACKAGE_DIR}/GIMP-2.99.app/Contents/MacOS
 ln -s gimp-console-2.99 gimp-console
 ln -s gimp-debug-tool-2.99 gimp-debug-tool
 ln -s python3.9 python
 ln -s python3.9 python3
popd

echo "copy xdg-email wrapper to the package"
mkdir -p ${PACKAGE_DIR}/GIMP-2.99.app/Contents/MacOS
cp xdg-email ${PACKAGE_DIR}/GIMP-2.99.app/Contents/MacOS

echo "Creating pyc files"
python3.9 -m compileall -q ${PACKAGE_DIR}/GIMP-2.99.app

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
  DMGNAME="gimp-${GIMP_VERSION}-x86_64.dmg"
else
  DMGNAME="gimp-${GIMP_VERSION}-x86_64-b${CIRCLE_BUILD_NUM}-${CIRCLE_BRANCH////-}.dmg"
fi

mkdir -p /tmp/artifacts/
rm -f /tmp/tmp.dmg
rm -f "/tmp/artifacts/gimp-${GIMP_VERSION}-x86_64.dmg"

cd create-dmg

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

echo "Done"
