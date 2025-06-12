#!/usr/bin/env bash
#####################################################################
# macports_install.sh: installs macports                            #
#                                                                   #
# Copyright 2022 Lukas Oberhuber <lukaso@gmail.com>                 #
#                                                                   #
# This program is free software; you can redistribute it and/or     #
# modify it under the terms of the GNU General Public License as    #
# published by the Free Software Foundation; either version 2 of    #
# the License, or (at your option) any later version.               #
#                                                                   #
# This program is distributed in the hope that it will be useful,   #
# but WITHOUT ANY WARRANTY; without even the implied warranty of    #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the     #
# GNU General Public License for more details.                      #
#                                                                   #
# You should have received a copy of the GNU General Public License #
# along with this program; if not, contact:                         #
#                                                                   #
# Free Software Foundation           Voice:  +1-617-542-5942        #
# 51 Franklin Street, Fifth Floor    Fax:    +1-617-542-2652        #
# Boston, MA  02110-1301,  USA       gnu@gnu.org                    #
#####################################################################

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MACPORTS_VERSION=2.10.5

# Change to update python version across build
# check `ports/graphics/gimp3/Portfile` to make sure this python version is
# added to the `supported_py_versions` list or the build will fail
# Keep consistent with version in 
# - `ports/graphics/gegl/Portfile`
# - `ports/devel/glib2/Portfile`
# make sure to exclude other python version later in this script
PYTHON_VERSION=3.10
# Set automatically
PYTHON_SHORT_VERSION=${PYTHON_VERSION//./}

DEPLOYMENT_TARGET_ARM64='11.0'
SDK_VERSION_ARM64='11.3'
DEPLOYMENT_TARGET_X86_64='11.0'
SDK_VERSION_X86_64='11.3'

arch=$(uname -m)
if [ "$arch" = 'arm64' ]; then
  build_arm64=true
else
  build_arm64=false
fi
echo "*** Build: $arch"

function pure_version() {
  echo '0.3'
}

function version() {
  echo "macports0_install.sh $(pure_version)"
}

function usage() {
  version
  echo ""
  echo "Builds macports."
  echo "Usage:  $(basename $0) [options]"
  echo ""
  echo "Builds Gimp dependencies."
  echo "Options:"
  echo "  --circleci"
  echo "      settings for circleci instead of local"
  echo "  --force"
  echo "      force install (useful after upgrading macos)"
  echo "  --dirgimp"
  echo "      installs macports builds to a custom prefix"
  echo "  --version         show tool version number"
  echo "  -h, --help        display this help"
  exit 0
}

while test "${1:0:1}" = "-"; do
  case $1 in
  --circleci)
    circleci="true"
    shift
    ;;
  --force)
    force="true"
    shift
    ;;
  --dirgimp)
    GIMP_PREFIX="$2"
    shift 2
    ;;
  -h | --help)
    usage
    ;;
  --version)
    version
    exit 0
    ;;
  -*)
    echo "Unknown option $1. Run with --help for help."
    exit 1
    ;;
  esac
done

if [ "$build_arm64" = true ]; then
  SDK_VERSION=$SDK_VERSION_ARM64
  SDK_MAJOR_VERSION=$(echo $SDK_VERSION_ARM64 | cut -d. -f1)
  DEPLOYMENT_TARGET=$DEPLOYMENT_TARGET_ARM64
else
  SDK_VERSION=$SDK_VERSION_X86_64
  SDK_MAJOR_VERSION=$(echo $SDK_VERSION_X86_64 | cut -d. -f1)
  DEPLOYMENT_TARGET=$DEPLOYMENT_TARGET_X86_64
fi

if [ -z "$GIMP_PREFIX" ]; then
  export GIMP_PREFIX=${HOME}/macports-gimp3-${arch}
fi
echo "**Installing MacPorts in $GIMP_PREFIX"
export PATH=$GIMP_PREFIX/bin:$PATH
if [ -n "$dirgimp" ]; then
  echo "export GIMP_PREFIX=${GIMP_PREFIX}" >~/.profile-gimp-${arch}
else
  # empty file
  echo "" >~/.profile-gimp-${arch}
fi

echo "export PYTHON_VERSION=${PYTHON_VERSION}" >>~/.profile-gimp-${arch}
echo "export PYTHON_SHORT_VERSION=${PYTHON_SHORT_VERSION}" >>~/.profile-gimp-${arch}

if [ -n "$circleci" ]; then
  echo "**Installing MacPorts for CircleCI"
  echo "export circleci=\"true\"" >>~/.profile-gimp-${arch}
fi

if [ ! -f "$GIMP_PREFIX/bin/port" ] || [ -n "$force" ]; then
  # Must install MacPorts to get both user and command
  FIRST_INSTALL=true
fi

if [ -n "$FIRST_INSTALL" ]; then
  echo "**install MacPorts"

  MACPORTS_INSTALLER=$HOME/macports_installer

  mkdir -p $MACPORTS_INSTALLER
  pushd $MACPORTS_INSTALLER

  curl -L -O https://github.com/macports/macports-base/releases/download/v${MACPORTS_VERSION}/MacPorts-${MACPORTS_VERSION}.tar.bz2
  tar xf MacPorts-${MACPORTS_VERSION}.tar.bz2
  pushd MacPorts-${MACPORTS_VERSION}
  ./configure --prefix=$GIMP_PREFIX --with-applications-dir=$GIMP_PREFIX/Applications --with-no-root-privileges --without-startupitems --with-install-user=${USER} --with-install-group=staff
  make
  make install
  popd

  popd

  rm -rf $MACPORTS_INSTALLER
fi

echo "***Setting up MacPorts build defaults"
# set default build options for macports
if [ -n "$circleci" ]; then
  debug="+debugoptimized"
else
  debug="+debug"
fi

cp ${GIMP_PREFIX}/etc/macports/macports.conf.default ${GIMP_PREFIX}/etc/macports/macports.conf
cp ${GIMP_PREFIX}/etc/macports/variants.conf.default ${GIMP_PREFIX}/etc/macports/variants.conf

echo 'buildfromsource always' | tee -a ${GIMP_PREFIX}/etc/macports/macports.conf
echo 'startupitem_type none' | tee -a ${GIMP_PREFIX}/etc/macports/macports.conf
echo 'startupitem_install no' | tee -a ${GIMP_PREFIX}/etc/macports/macports.conf
echo 'startupitem_autostart no' | tee -a ${GIMP_PREFIX}/etc/macports/macports.conf
# stops macports from having two ports and not knowing which to activate, which breaks the build
echo 'uninstall_inactive yes' | tee -a ${GIMP_PREFIX}/etc/macports/macports.conf
if [ "$build_arm64" = true ]; then
  echo 'macosx_deployment_target 11.0' | tee -a ${GIMP_PREFIX}/etc/macports/macports.conf
  echo 'macosx_sdk_version 11.3' | tee -a ${GIMP_PREFIX}/etc/macports/macports.conf
else
  echo "macosx_deployment_target ${DEPLOYMENT_TARGET_X86_64}" | tee -a ${GIMP_PREFIX}/etc/macports/macports.conf
  echo "macosx_sdk_version ${SDK_VERSION_X86_64}" | tee -a ${GIMP_PREFIX}/etc/macports/macports.conf
  echo "build_arch x86_64" | tee -a ${GIMP_PREFIX}/etc/macports/macports.conf
fi
echo "-x11 +no_x11 +quartz -python27 +no_gnome -gnome -gfortran -openldap -pinentry_mac ${debug} +python${PYTHON_SHORT_VERSION} -python311 -python312 -python313" | tee -a ${GIMP_PREFIX}/etc/macports/variants.conf
printf "file://${PROJECT_DIR}/ports\n$(cat ${GIMP_PREFIX}/etc/macports/sources.conf.default)\n" | tee ${GIMP_PREFIX}/etc/macports/sources.conf

echo "*** Setup ${SDK_VERSION} SDK"
cd /Library/Developer/CommandLineTools/SDKs
if [ ! -d "MacOSX${SDK_VERSION}.sdk" ]; then
  sudo curl -L "https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX${SDK_VERSION}.sdk.tar.xz" | sudo tar -xzf -
fi
if [ -L "MacOSX${SDK_MAJOR_VERSION}.sdk" ]; then
  sudo rm "MacOSX${SDK_MAJOR_VERSION}.sdk"
fi
sudo ln -s "MacOSX${SDK_VERSION}.sdk" "MacOSX${SDK_MAJOR_VERSION}.sdk"

echo "export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX${SDK_VERSION_X86_64}.sdk" >>~/.profile-gimp-${arch}
echo "export MACOSX_DEPLOYMENT_TARGET=${DEPLOYMENT_TARGET}" >>~/.profile-gimp-${arch}
if [ "$build_arm64" = true ]; then
  echo 'export GIMP_ARM64=true' >>~/.profile-gimp-${arch}
fi

# shellcheck disable=SC1090
source "${HOME}/.profile-gimp-${arch}"

if [ -n "$FIRST_INSTALL" ]; then
  # must do before and after otherwise local portindex fails if this is the first time
  port -v -N selfupdate || true
fi

pushd "${PROJECT_DIR}/ports"
portindex
popd

port -v -N selfupdate || true
