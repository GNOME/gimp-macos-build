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

echo "fixing pkg-config files"
find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/pkgconfig -name '*.pc' -type f -exec sed -i '' -e 's@^prefix=.*$@prefix=${pcfiledir}/../..@' -e "s@${GIMP_PREFIX}@\${GIMP_PREFIX}@g" {} \;
find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/${PYTHON_VERSION}/lib/pkgconfig -name '*.pc' -type f -exec sed -i '' -e 's@^prefix=.*$@prefix=${pcfiledir}/../..@' -e "s@${GIMP_PREFIX}@\${GIMP_PREFIX}@g" {} \;
echo "Done developer bundling"
