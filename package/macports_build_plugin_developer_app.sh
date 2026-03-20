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
export OLD_PACKAGE_DIR="${HOME}/macports-gimp-osx-app-${arch}"
export PACKAGE_DIR="${OLD_PACKAGE_DIR}-plugin-developer"

echo "** Creating developer package"
echo ""
echo "Remove old app: ${PACKAGE_DIR}"
rm -rf "${PACKAGE_DIR}"

echo "Copying app"
mkdir -p ${PACKAGE_DIR}
cp -a ${OLD_PACKAGE_DIR}/GIMP.app ${PACKAGE_DIR}/

echo "copying headers and pkg-config files"
cp -r ${GIMP_PREFIX}/include ${PACKAGE_DIR}/GIMP.app/Contents/Resources/
# https://github.com/libvips/libvips/issues/909
cp -r ${GIMP_PREFIX}/lib/glib-2.0 ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib
cp -r ${GIMP_PREFIX}/lib/pkgconfig ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/

echo "fixing orphaned pkg-config files (graphite2, netpbm, soxr, soxr-lsr)"
PKGCONFIG_DIR="${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/pkgconfig"
for pc in graphite2.pc netpbm.pc soxr.pc soxr-lsr.pc; do
  f="${PKGCONFIG_DIR}/${pc}"
  if [ -f "$f" ]; then
    printf "prefix=\${pcfiledir}/../..\nincludedir=\${prefix}/include\nlibdir=\${prefix}/lib\n\n" | cat - "$f" > /tmp/pc_fix_tmp && mv /tmp/pc_fix_tmp "$f"
    sed -i '' \
      -e "s@-L${GIMP_PREFIX}/lib@-L\${libdir}@g" \
      -e "s@-I${GIMP_PREFIX}/include@-I\${includedir}@g" \
      "$f"
  fi
done

echo "fixing remaining pkg-config files"
# shellcheck disable=SC2016
find "${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/pkgconfig" -name '*.pc' -type f -exec sed -i '' -e 's@^prefix=.*$@prefix=${pcfiledir}/../..@' -e "s@${GIMP_PREFIX}@\${prefix}@g" {} \;
# shellcheck disable=SC2016
find "${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/${PYTHON_VERSION}/lib/pkgconfig" -name '*.pc' -type f -exec sed -i '' -e 's@^prefix=.*$@prefix=${pcfiledir}/../..@' -e "s@${GIMP_PREFIX}@\${prefix}@g" {} \;

echo "Done developer bundling"
