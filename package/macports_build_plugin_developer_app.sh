#!/bin/bash

# set -e

if [[ $(uname -m) == 'arm64' ]]; then
  build_arm64=true
  echo "*** Build: arm64"
  #  target directory
  export OLD_PACKAGE_DIR="${HOME}/macports-gimp${VGIMP}-osx-app-arm64"
  export PACKAGE_DIR="${OLD_PACKAGE_DIR}-plugin-developer"
  export arch="arm64"
else
  build_arm64=false
  echo "*** Build: x86_64"
  #  target directory
  export OLD_PACKAGE_DIR="${HOME}/macports-gimp${VGIMP}-osx-app-x86_64"
  export PACKAGE_DIR="${OLD_PACKAGE_DIR}-plugin-developer"
  export arch="x86_64"
fi

echo "** Creating developer package"
echo ""
echo "Remove old app: ${PACKAGE_DIR}"
rm -rf "${PACKAGE_DIR}"

echo "Copying app"
mkdir -p ${PACKAGE_DIR}
cp -a ${OLD_PACKAGE_DIR}/GIMP.app ${PACKAGE_DIR}/

echo "copying headers and pkg-config files"
cp -r ${PREFIX}/include ${PACKAGE_DIR}/GIMP.app/Contents/Resources/
# https://github.com/libvips/libvips/issues/909
cp -r ${PREFIX}/lib/glib-2.0 ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib
cp -r ${PREFIX}/lib/pkgconfig ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/

echo "fixing pkg-config files"
find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/lib/pkgconfig -name '*.pc' -type f -exec sed -i '' -e 's@^prefix=.*$@prefix=${pcfiledir}/../..@' -e "s@${PREFIX}@\${prefix}@g" {} \;
find ${PACKAGE_DIR}/GIMP.app/Contents/Resources/Library/Frameworks/Python.framework/Versions/${PYTHON_VERSION}/lib/pkgconfig -name '*.pc' -type f -exec sed -i '' -e 's@^prefix=.*$@prefix=${pcfiledir}/../..@' -e "s@${PREFIX}@\${prefix}@g" {} \;
echo "Done developer bundling"
