#!/bin/sh

# set -e

if [[ $(uname -m) == 'arm64' ]]; then
  build_arm64=true
  echo "*** Build: arm64"
  PREFIX=$HOME/homebrew
  #  target directory
  export PACKAGE_DIR="${HOME}/brew-gimp299-osx-app"
else
  build_arm64=false
  echo "*** Build: x86_64"
  PREFIX=$HOME/homebrew_x86_64
  #  target directory
  export PACKAGE_DIR="${HOME}/brew-gimp299-osx-app-x86_64"
fi
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

echo "Remove files in Cellar dir as they are duplicate"
rm -rf ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/Cellar

echo "Copy python files"
rm -rf "${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/Frameworks/"
cp -r "${PREFIX}/Frameworks" "${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/"

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
FRAMEWORKS="${OLDPATH}Cellar/.*/Frameworks/"

for file in $FILES
do
  id_path=$(echo "$file" | sed -E "s|${PACKAGE_DIR}/GIMP-2.99.app/Contents/(Resources\|MacOS)/||")
  install_name_tool -id "@rpath/"$id_path $file
  otool -L $file \
   | grep -E "\t$FRAMEWORKS" \
   | gawk -v fname="$file" -v frameworks="${FRAMEWORKS}" \
     '{print "install_name_tool -change "$1" @rpath/Frameworks/"gensub(frameworks, "\\1", "1", $1)" "fname}' \
   | bash
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
find  ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources -mindepth 1 -perm +111 -type f \
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

echo "adding @rpath to python app"
install_name_tool -add_rpath @executable_path/../../../../../../../../ \
  ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/Frameworks/Python.framework/Versions/3.9/Resources/Python.app/Contents/MacOS/Python
install_name_tool -add_rpath @executable_path/../../../../ \
  ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/Frameworks/Python.framework/Versions/3.9/Python

echo "removing build path from the .gir files"
find  ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/share/gir-1.0/*.gir \
   -exec sed -i '' "s|${OLDPATH}||g" {} +

echo "removing previous rpath from the .gir files (in case it's there)"
find  ${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/share/gir-1.0/*.gir \
   -exec sed -i '' "s|@rpath/||g" {} +

echo "adding @rpath to the .gir files"
SEDDIR="${PACKAGE_DIR}/GIMP-2.99.app/Contents/Resources/share/gir-1.0/"
sed -i '' 's|\(libappstream-glib.8.dylib\)|@rpath/opt/appstream-glib/lib/\1|g' ${SEDDIR}/AppStreamGlib-1.0.gir
sed -i '' 's|\(libatk-1.0.0.dylib\)|@rpath/opt/atk/lib/\1|g' ${SEDDIR}/Atk-1.0.gir
sed -i '' 's|\(libbabl-0.1.0.dylib\)|@rpath/opt/babl/lib/\1|g' ${SEDDIR}/Babl-0.1.gir
sed -i '' 's|\(libgexiv2.2.dylib\)|@rpath/opt/gexiv2/lib/\1|g' ${SEDDIR}/GExiv2-0.10.gir
sed -i '' 's|\(libgirepository-1.0.1.dylib\)|@rpath/opt/gobject-introspection/lib/\1|g' ${SEDDIR}/GIRepository-2.0.gir
sed -i '' 's|/Users/lukasoberhuber/homebrew/\(opt/glib/lib/libgobject-2.0.0.dylib\)|@rpath/\1|g' ${SEDDIR}/GL-1.0.gir
sed -i '' 's|/Users/lukasoberhuber/homebrew/\(opt/glib/lib/libglib-2.0.0.dylib\)|@rpath/\1|g' ${SEDDIR}/GLib-2.0.gir
sed -i '' 's|/Users/lukasoberhuber/homebrew/\(opt/glib/lib/libgmodule-2.0.0.dylib\)|@rpath/\1|g' ${SEDDIR}/GModule-2.0.gir
sed -i '' 's|\(/Users/lukasoberhuber/homebrew/\(opt/glib/lib/libgobject-2.0.0.dylib\)\)|@rpath/\1|g' ${SEDDIR}/GObject-2.0.gir
sed -i '' 's|\(libgdk-3.0.dylib\)|@rpath/opt/gtk+3-fixed/lib/\1|g' ${SEDDIR}/Gdk-3.0.gir
sed -i '' 's|\(libgdk_pixbuf-2.0.0.dylib\)|@rpath/opt/gdk-pixbuf/lib/\1|g' ${SEDDIR}/GdkPixbuf-2.0.gir
sed -i '' 's|\(libgdk_pixbuf-2.0.0.dylib\)|@rpath/opt/gdk-pixbuf/lib/\1|g' ${SEDDIR}/GdkPixdata-2.0.gir
sed -i '' 's|\(libgegl-0.4.0.dylib\)|@rpath/opt/gegl-full/lib/\1|g' ${SEDDIR}/Gegl-0.4.gir
sed -i '' 's|\(libgimp-3.0.0.dylib\)|@rpath/opt/gimp3/lib/\1|g' ${SEDDIR}/Gimp-3.0.gir
sed -i '' 's|\(libgimpbase-3.0.0.dylib\)|@rpath/opt/gimp3/lib/\1|g' ${SEDDIR}/Gimp-3.0.gir
sed -i '' 's|\(libgimpcolor-3.0.0.dylib\)|@rpath/opt/gimp3/lib/\1|g' ${SEDDIR}/Gimp-3.0.gir
sed -i '' 's|\(libgimpconfig-3.0.0.dylib\)|@rpath/opt/gimp3/lib/\1|g' ${SEDDIR}/Gimp-3.0.gir
sed -i '' 's|\(libgimpmath-3.0.0.dylib\)|@rpath/opt/gimp3/lib/\1|g' ${SEDDIR}/Gimp-3.0.gir
sed -i '' 's|\(libgimpmodule-3.0.0.dylib\)|@rpath/opt/gimp3/lib/\1|g' ${SEDDIR}/Gimp-3.0.gir
sed -i '' 's|\(libgimpui-3.0.0.dylib\)|@rpath/opt/gimp3/lib/\1|g' ${SEDDIR}/GimpUi-3.0.gir
sed -i '' 's|\(libgimpwidgets-3.0.0.dylib\)|@rpath/opt/gimp3/lib/\1|g' ${SEDDIR}/GimpUi-3.0.gir
sed -i '' 's|/Users/lukasoberhuber/homebrew/\(opt/glib/lib/libgio-2.0.0.dylib\)|@rpath/\1|g' ${SEDDIR}/Gio-2.0.gir
sed -i '' 's|\(libgtk-3.0.dylib\)|@rpath/opt/gtk+3-fixed/lib/\1|g' ${SEDDIR}/Gtk-3.0.gir
sed -i '' 's|\Users/lukasoberhuber/homebrew/Cellar/\(gtk-mac-integration-full\)/3.0.1\(/lib/libgtkmacintegration-gtk3.4.dylib\)|@rpath/opt/\1\2|g' ${SEDDIR}/GtkosxApplication-1.0.gir
sed -i '' 's|\(libharfbuzz-gobject.0.dylib\)|@rpath/lib/\1|g' ${SEDDIR}/HarfBuzz-0.0.gir
sed -i '' 's|\(libjson-glib-1.0.0.dylib\)|@rpath/opt/json-glib/lib/\1|g' ${SEDDIR}/Json-1.0.gir
sed -i '' 's|\(libpango-1.0.0.dylib\)|@rpath/opt/pango/lib/\1|g' ${SEDDIR}/Pango-1.0.gir
sed -i '' 's|\(libpangocairo-1.0.0.dylib\)|@rpath/opt/pango/lib/\1|g' ${SEDDIR}/PangoCairo-1.0.gir
sed -i '' 's|\(libpangoft2-1.0.0.dylib\)|@rpath/opt/pango/lib/\1|g' ${SEDDIR}/PangoFT2-1.0.gir
sed -i '' 's|\(libpangoft2-1.0.0.dylib\)|@rpath/opt/pango/lib/\1|g' ${SEDDIR}/PangoFc-1.0.gir
sed -i '' 's|\(libpangoft2-1.0.0.dylib\)|@rpath/opt/pango/lib/\1|g' ${SEDDIR}/PangoOT-1.0.gir
sed -i '' 's|\(libpoppler-glib.8.dylib\)|@rpath/opt/poppler-slim/lib/\1|g' ${SEDDIR}/Poppler-0.18.gir
sed -i '' 's|\(libpoppler.122.dylib\)|@rpath/opt/poppler-slim/lib/\1|g' ${SEDDIR}/Poppler-0.18.gir
sed -i '' 's|/Users/lukasoberhuber/homebrew/Cellar/\(librsvg\)/2.54.4\(/lib/librsvg-2.2.dylib\)|@rpath/opt/\1\2|g' ${SEDDIR}/Rsvg-2.0.gir
sed -i '' 's|\(libcairo-gobject.2.dylib\)|@rpath/opt/cairo/lib/\1|g' ${SEDDIR}/cairo-1.0.gir

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
