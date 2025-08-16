#!/bin/bash

# set -e

arch=$(uname -m)
if [ "$arch" = 'arm64' ]; then
  build_arm64=true
else
  build_arm64=false
fi
echo "*** Build: $arch"

#  target directory
export PACKAGE_DIR="${HOME}/macports-gimp-osx-app-${arch}"
export JHBUILD_PREFIX=${GIMP_PREFIX}
GTK_MAC_BUNDLER=${HOME}/.local/bin/gtk-mac-bundler

echo "Remove old app: ${PACKAGE_DIR}"
rm -rf "${PACKAGE_DIR}"

printf "Determining GIMP version: "
eval $(sed -n 's/^#define  *\([^ ]*\)  *\(.*\) *$/export \1=\2/p' $(echo ${GIMP_PREFIX}/var/macports/build/_Users_$(whoami)_project_ports_graphics_gimp-official/gimp-official/work/build/config.h))
echo "$GIMP_VERSION"
sed -e "s|%GIMP_VERSION%|${GIMP_VERSION}|g" -e "s|%GIMP_MUTEX_VERSION%|${GIMP_MUTEX_VERSION}|g" info.plist.tmpl > info.plist


echo "Copying charset.alias"
# It's totally unclear if this file matters at all, or what should be in it.
# This version was pulled from pkg-config-0.29.2/glib/glib/libcharset/charset.alias
if [ -w "${GIMP_PREFIX}/lib/" ]; then
  cp -f charset.alias "${GIMP_PREFIX}/lib/"
else
  sudo cp -f charset.alias "${GIMP_PREFIX}/lib/"
fi

echo "Creating bundle"
$GTK_MAC_BUNDLER macports-gimp.bundle
if [ ! -f ${PACKAGE_DIR}/GIMP.app/Contents/MacOS/gimp ]; then
  echo "ERROR: Bundling failed, ${PACKAGE_DIR}/GIMP.app/Contents/MacOS/gimp not found"
  exit 1
fi
echo "Done creating bundle"

echo "Store GIMP version in bundle (for later use)"
echo "$GIMP_VERSION" > ${PACKAGE_DIR}/GIMP.app/Contents/Resources/.version

echo "Link 'Resources' into python ${PYTHON_VERSION} framework 'Resources'"
if [ ! -d "${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/${PYTHON_VERSION}/Resources/Python.app/Contents/Resources" ]; then
  # Avoids creating very awkward link in the wrong place
  echo "***Error: Python framework not found"
  exit 1
fi
pushd "${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/${PYTHON_VERSION}/Resources/Python.app/Contents/Resources/" || exit 1
  for resources in etc gimp.icns lib share fileicon-xcf.icns ;
  do
    ln -s "../../../../../../../../../${resources}" \
      "${resources}"
  done
popd

echo "Removing pathnames from the libraries and binaries"
# fix permission for some libs
find ${PACKAGE_DIR}/GIMP.app/Contents/Resources \( -name '*.dylib' -o -name '*.so' \) -type f | xargs chmod 755

# Remove LC_RPATH from libraries and executables. MacPorts adds an LC_RPATH statement to all `dylibs` and `so`
# binaries, which should not have them set (and it messes up notarization).
delete_rpaths() {
  for rpath in $(otool -l "$1" | awk "/ path / { print \$2 }")
  do
    echo "Deleting LC_RPATH $rpath from file $1"
    install_name_tool -delete_rpath "$rpath" "$1"
  done
}
export -f delete_rpaths
find ${PACKAGE_DIR}/GIMP.app/Contents/Resources \( -name "*.dylib" -o -name "*.so" \) -type f -exec bash -c 'delete_rpaths "$0"' {} \;
find ${PACKAGE_DIR}/GIMP.app/Contents/MacOS -type f -perm +111 -exec bash -c 'delete_rpaths "$0"' {} \;
find ${PACKAGE_DIR}/GIMP.app/Contents/Resources -type f -perm +111 -exec bash -c 'delete_rpaths "$0"' {} \;

# getting list of the files to fix
FILES=$(
  find ${PACKAGE_DIR}/GIMP.app -perm +111 -type f \
   | xargs file \
   | grep ' Mach-O '|awk -F ':' '{print $1}'
)

OLDPATH="${GIMP_PREFIX}/"

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

# Long list of -change are due to not building gcc from source
# due to a bug. See https://trac.macports.org/ticket/65573
echo "adding @rpath to the binaries (incl special ghostscript 9.56 fix)"
find  ${PACKAGE_DIR}/GIMP.app/Contents/MacOS -type f -perm +111 \
   | xargs file \
   | grep ' Mach-O ' |awk -F ':' '{print $1}' \
   | xargs -n1 install_name_tool -add_rpath @executable_path/../Resources/ \
       -change @rpath/libgfortran.5.dylib @rpath/lib/libgcc/libgfortran.5.dylib \
       -change @rpath/libgfortran.dylib   @rpath/lib/libgcc/libgfortran.dylib \
       -change @rpath/libquadmath.0.dylib @rpath/lib/libgcc/libquadmath.0.dylib \
       -change @rpath/libquadmath.dylib   @rpath/lib/libgcc/libquadmath.dylib \
       -change @rpath/libstdc++.6.dylib   @rpath/lib/libgcc/libstdc++.6.dylib \
       -change @rpath/libstdc++.dylib     @rpath/lib/libgcc/libstdc++.dylib \
       -change @rpath/libgcc_s.1.1.dylib  @rpath/lib/libgcc/libgcc_s.1.1.dylib \
       -change @rpath//libasan.8.dylib    @rpath/lib/libgcc/libasan.8.dylib \
       -change @rpath/libasan.dylib       @rpath/lib/libgcc/libasan.dylib \
       -change @rpath/libatomic.1.dylib   @rpath/lib/libgcc/libatomic.1.dylib \
       -change @rpath/libatomic.dylib     @rpath/lib/libgcc/libatomic.dylib \
       -change @rpath/libgcc_s.1.dylib    @rpath/lib/libgcc/libgcc_s.1.dylib \
       -change @rpath/libgcc_s.dylib      @rpath/lib/libgcc/libgcc_s.dylib \
       -change @rpath/libgomp.1.dylib     @rpath/lib/libgcc/libgomp.1.dylib \
       -change @rpath/libgomp.dylib       @rpath/lib/libgcc/libgomp.dylib \
       -change @rpath/libitm.1.dylib      @rpath/lib/libgcc/libitm.1.dylib \
       -change @rpath/libitm.dylib        @rpath/lib/libgcc/libitm.dylib \
       -change @rpath/libobjc-gnu.4.dylib @rpath/lib/libgcc/libobjc-gnu.4.dylib \
       -change @rpath/libobjc-gnu.dylib   @rpath/lib/libgcc/libobjc-gnu.dylib \
       -change @rpath/libssp.0.dylib      @rpath/lib/libgcc/libssp.0.dylib \
       -change @rpath/libssp.dylib        @rpath/lib/libgcc/libssp.dylib \
       -change @rpath/libubsan.1.dylib    @rpath/lib/libgcc/libubsan.1.dylib \
       -change @rpath/libubsan.dylib      @rpath/lib/libgcc/libubsan.dylib

echo "adding @rpath to the plugins (incl special ghostscript 9.56 fix)"
find  ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/gimp/${GIMP_PKGCONFIG_VERSION}/plug-ins/ -perm +111 -type f \
   | xargs file \
   | grep ' Mach-O '|awk -F ':' '{print $1}' \
   | xargs -n1 install_name_tool -add_rpath @executable_path/../../../../../ \
       -change @rpath/libgfortran.5.dylib @rpath/lib/libgcc/libgfortran.5.dylib \
       -change @rpath/libgfortran.dylib   @rpath/lib/libgcc/libgfortran.dylib \
       -change @rpath/libquadmath.0.dylib @rpath/lib/libgcc/libquadmath.0.dylib \
       -change @rpath/libquadmath.dylib   @rpath/lib/libgcc/libquadmath.dylib \
       -change @rpath/libstdc++.6.dylib   @rpath/lib/libgcc/libstdc++.6.dylib \
       -change @rpath/libstdc++.dylib     @rpath/lib/libgcc/libstdc++.dylib \
       -change @rpath/libgcc_s.1.1.dylib  @rpath/lib/libgcc/libgcc_s.1.1.dylib \
       -change @rpath//libasan.8.dylib    @rpath/lib/libgcc/libasan.8.dylib \
       -change @rpath/libasan.dylib       @rpath/lib/libgcc/libasan.dylib \
       -change @rpath/libatomic.1.dylib   @rpath/lib/libgcc/libatomic.1.dylib \
       -change @rpath/libatomic.dylib     @rpath/lib/libgcc/libatomic.dylib \
       -change @rpath/libgcc_s.1.dylib    @rpath/lib/libgcc/libgcc_s.1.dylib \
       -change @rpath/libgcc_s.dylib      @rpath/lib/libgcc/libgcc_s.dylib \
       -change @rpath/libgomp.1.dylib     @rpath/lib/libgcc/libgomp.1.dylib \
       -change @rpath/libgomp.dylib       @rpath/lib/libgcc/libgomp.dylib \
       -change @rpath/libitm.1.dylib      @rpath/lib/libgcc/libitm.1.dylib \
       -change @rpath/libitm.dylib        @rpath/lib/libgcc/libitm.dylib \
       -change @rpath/libobjc-gnu.4.dylib @rpath/lib/libgcc/libobjc-gnu.4.dylib \
       -change @rpath/libobjc-gnu.dylib   @rpath/lib/libgcc/libobjc-gnu.dylib \
       -change @rpath/libssp.0.dylib      @rpath/lib/libgcc/libssp.0.dylib \
       -change @rpath/libssp.dylib        @rpath/lib/libgcc/libssp.dylib \
       -change @rpath/libubsan.1.dylib    @rpath/lib/libgcc/libubsan.1.dylib \
       -change @rpath/libubsan.dylib      @rpath/lib/libgcc/libubsan.dylib

echo "adding @rpath to the extensions (incl special ghostscript 9.56 fix)"
find  ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/gimp/${GIMP_PKGCONFIG_VERSION}/extensions/ -perm +111 -type f \
   | xargs file \
   | grep ' Mach-O '|awk -F ':' '{print $1}' \
   | xargs -n1 install_name_tool -add_rpath @executable_path/../../../../../ \
       -change @rpath/libgfortran.5.dylib @rpath/lib/libgcc/libgfortran.5.dylib \
       -change @rpath/libgfortran.dylib   @rpath/lib/libgcc/libgfortran.dylib \
       -change @rpath/libquadmath.0.dylib @rpath/lib/libgcc/libquadmath.0.dylib \
       -change @rpath/libquadmath.dylib   @rpath/lib/libgcc/libquadmath.dylib \
       -change @rpath/libstdc++.6.dylib   @rpath/lib/libgcc/libstdc++.6.dylib \
       -change @rpath/libstdc++.dylib     @rpath/lib/libgcc/libstdc++.dylib \
       -change @rpath/libgcc_s.1.1.dylib  @rpath/lib/libgcc/libgcc_s.1.1.dylib \
       -change @rpath//libasan.8.dylib    @rpath/lib/libgcc/libasan.8.dylib \
       -change @rpath/libasan.dylib       @rpath/lib/libgcc/libasan.dylib \
       -change @rpath/libatomic.1.dylib   @rpath/lib/libgcc/libatomic.1.dylib \
       -change @rpath/libatomic.dylib     @rpath/lib/libgcc/libatomic.dylib \
       -change @rpath/libgcc_s.1.dylib    @rpath/lib/libgcc/libgcc_s.1.dylib \
       -change @rpath/libgcc_s.dylib      @rpath/lib/libgcc/libgcc_s.dylib \
       -change @rpath/libgomp.1.dylib     @rpath/lib/libgcc/libgomp.1.dylib \
       -change @rpath/libgomp.dylib       @rpath/lib/libgcc/libgomp.dylib \
       -change @rpath/libitm.1.dylib      @rpath/lib/libgcc/libitm.1.dylib \
       -change @rpath/libitm.dylib        @rpath/lib/libgcc/libitm.dylib \
       -change @rpath/libobjc-gnu.4.dylib @rpath/lib/libgcc/libobjc-gnu.4.dylib \
       -change @rpath/libobjc-gnu.dylib   @rpath/lib/libgcc/libobjc-gnu.dylib \
       -change @rpath/libssp.0.dylib      @rpath/lib/libgcc/libssp.0.dylib \
       -change @rpath/libssp.dylib        @rpath/lib/libgcc/libssp.dylib \
       -change @rpath/libubsan.1.dylib    @rpath/lib/libgcc/libubsan.1.dylib \
       -change @rpath/libubsan.dylib      @rpath/lib/libgcc/libubsan.dylib

echo "adding @rpath to libgcc dylibs"
find  ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/ -perm +111 -type f \
   | xargs file \
   | grep ' Mach-O '|awk -F ':' '{print $1}' \
   | xargs -n1 install_name_tool \
       -change @rpath/libgfortran.5.dylib @rpath/lib/libgcc/libgfortran.5.dylib \
       -change @rpath/libgfortran.dylib   @rpath/lib/libgcc/libgfortran.dylib \
       -change @rpath/libquadmath.0.dylib @rpath/lib/libgcc/libquadmath.0.dylib \
       -change @rpath/libquadmath.dylib   @rpath/lib/libgcc/libquadmath.dylib \
       -change @rpath/libstdc++.6.dylib   @rpath/lib/libgcc/libstdc++.6.dylib \
       -change @rpath/libstdc++.dylib     @rpath/lib/libgcc/libstdc++.dylib \
       -change @rpath/libgcc_s.1.1.dylib  @rpath/lib/libgcc/libgcc_s.1.1.dylib \
       -change @rpath//libasan.8.dylib    @rpath/lib/libgcc/libasan.8.dylib \
       -change @rpath/libasan.dylib       @rpath/lib/libgcc/libasan.dylib \
       -change @rpath/libatomic.1.dylib   @rpath/lib/libgcc/libatomic.1.dylib \
       -change @rpath/libatomic.dylib     @rpath/lib/libgcc/libatomic.dylib \
       -change @rpath/libgcc_s.1.dylib    @rpath/lib/libgcc/libgcc_s.1.dylib \
       -change @rpath/libgcc_s.dylib      @rpath/lib/libgcc/libgcc_s.dylib \
       -change @rpath/libgomp.1.dylib     @rpath/lib/libgcc/libgomp.1.dylib \
       -change @rpath/libgomp.dylib       @rpath/lib/libgcc/libgomp.dylib \
       -change @rpath/libitm.1.dylib      @rpath/lib/libgcc/libitm.1.dylib \
       -change @rpath/libitm.dylib        @rpath/lib/libgcc/libitm.dylib \
       -change @rpath/libobjc-gnu.4.dylib @rpath/lib/libgcc/libobjc-gnu.4.dylib \
       -change @rpath/libobjc-gnu.dylib   @rpath/lib/libgcc/libobjc-gnu.dylib \
       -change @rpath/libssp.0.dylib      @rpath/lib/libgcc/libssp.0.dylib \
       -change @rpath/libssp.dylib        @rpath/lib/libgcc/libssp.dylib \
       -change @rpath/libubsan.1.dylib    @rpath/lib/libgcc/libubsan.1.dylib \
       -change @rpath/libubsan.dylib      @rpath/lib/libgcc/libubsan.dylib

echo "adding @rpath to python app"
install_name_tool -add_rpath @loader_path/../../../../../../../../../ \
  ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/${PYTHON_VERSION}/Resources/Python.app/Contents/MacOS/Python
install_name_tool -add_rpath @loader_path/../../../../../ \
  ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/${PYTHON_VERSION}/Python

echo "removing build path from the .gir files: special case Poppler"
# Needed because for some reason this package puts in the build directory
find  ${PACKAGE_DIR}/GIMP.app/Contents/Resources/share/gir-1.0/Poppler*.gir \
   -exec sed -i '' "s|[A-Za-z0-9/\._-]*build/\(libpoppler[A-Za-z0-9/\._-]*\.dylib\)|lib/\1|g" {} +

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

echo "fixing symlinks (only 1 level down -- any more can't handle the copy) -- this is for plugin developers to match pkg-config files"
find ${GIMP_PREFIX}/lib/ \( -name "*.dylib" -o -name "*.so" \) -type l -maxdepth 1 -exec cp -a -n {} ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/ \;
# These two have absolute paths so break the package
rm -f ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/libcrypto.3.dylib
rm -f ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/libssl.3.dylib

echo "remove not connected symlinks"
find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/ -type l -exec test ! -e {} \; -delete

echo "fixing pixmap cache"
sed -i.old 's|@executable_path/../Resources/||' \
    ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
# Works around gdk-pixbuf loader bug for release builds only https://gitlab.gnome.org/GNOME/gdk-pixbuf/-/issues/217
mkdir -p "${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/gimp/${GIMP_PKGCONFIG_VERSION}/plug-ins/Resources/lib"
pushd ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/gimp/${GIMP_PKGCONFIG_VERSION}/plug-ins/Resources/lib || exit 1
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

pushd ${PACKAGE_DIR}/GIMP.app/Contents/MacOS || exit 1
  ln -s gimp-console-${GIMP_APP_VERSION} gimp-console
  ln -s gimp-debug-tool-${GIMP_APP_VERSION} gimp-debug-tool
  ln -s python${PYTHON_VERSION} python
  ln -s python${PYTHON_VERSION} python3
popd

echo "copy xdg-email wrapper to the package"
mkdir -p ${PACKAGE_DIR}/GIMP.app/Contents/MacOS
cp xdg-email ${PACKAGE_DIR}/GIMP.app/Contents/MacOS

echo "Copy SSL configuration for Python"
cp sitecustomize.py "${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/${PYTHON_VERSION}/lib/python${PYTHON_VERSION}/site-packages/"

echo "Creating pyc files"
"python${PYTHON_VERSION}" -m compileall -q "${PACKAGE_DIR}/GIMP.app"

echo "trimming optimized pyc from macports"
find ${PACKAGE_DIR}/GIMP.app -name '*opt-[12].pyc' -delete

echo "trimming out unused gettext files"
find -E ${PACKAGE_DIR}/GIMP.app -iregex '.*/(coreutils|git|gettext-tools|make)\.mo' -delete

echo "symlinking all the dupes"
jdupes -r -l ${PACKAGE_DIR}/GIMP.app

echo "Fix adhoc signing (M1 Macs)"
for file in $FILES
do
   error_message=$(/usr/bin/codesign -v "$file" 2>&1)
   if [[ "${error_message}" == *"invalid signature"* ]]
   then
     /usr/bin/codesign --sign - --force --preserve-metadata=entitlements,requirements,flags,runtime "$file"
   fi
done

echo "Done bundling"
