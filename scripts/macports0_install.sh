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
PYTHON_VERSION=3.10
# Set automatically
PYTHON_SHORT_VERSION=${PYTHON_VERSION//./}

DEPLOYMENT_TARGET_ARM64='11.0'
SDK_VERSION_ARM64='11.3'
DEPLOYMENT_TARGET_X86_64='11.0'
SDK_VERSION_X86_64='11.3'

if [[ $(uname -m) == 'arm64' ]]; then
  build_arm64=true
  arch='arm64'
  echo "*** Build: arm64"
else
  build_arm64=false
  arch='x86_64'
  echo "*** Build: x86_64"
fi

function pure_version() {
  echo '0.2'
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
  echo "  --homedirgimp2"
  echo "      installs macports to a custom homedir macports-gimp2"
  echo "  --homedirgimp3"
  echo "      installs macports to a custom homedir macports-gimp3"
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
  --homedirgimp2)
    homedirgimp2="true"
    shift
    ;;
  --homedirgimp3)
    homedirgimp3="true"
    shift
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

if [ -n "$homedirgimp2" ]; then
  echo "**Installing MacPorts in home dir macports-gimp2-${arch}"
  home_dir=true
  PREFIX="${HOME}/macports-gimp2-${arch}"
  export VGIMP=2
elif [ -n "$homedirgimp3" ]; then
  echo "**Installing MacPorts in home dir macports-gimp3-${arch}"
  home_dir=true
  PREFIX="${HOME}/macports-gimp3-${arch}"
  export VGIMP=3
else
  echo "**Error: Must choose a homedir"
  exit 1
fi

export PATH=$PREFIX/bin:$PATH
echo "export PREFIX=$PREFIX" >~/.profile-gimp${VGIMP}-${arch}
echo "export PYTHON_VERSION=${PYTHON_VERSION}" >>~/.profile-gimp${VGIMP}-${arch}
echo "export PYTHON_SHORT_VERSION=${PYTHON_SHORT_VERSION}" >>~/.profile-gimp${VGIMP}-${arch}

if [ -n "$circleci" ]; then
  echo "**Installing MacPorts for CircleCI"
  echo "export circleci=\"true\"" >>~/.profile-gimp${VGIMP}-${arch}
fi

if [ ! -f "$PREFIX/bin/port" ] || [ -n "$force" ]; then
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
  ./configure --prefix=$PREFIX --with-applications-dir=$PREFIX/Applications --with-no-root-privileges --without-startupitems --with-install-user=${USER} --with-install-group=staff
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

cp ${PREFIX}/etc/macports/macports.conf.default ${PREFIX}/etc/macports/macports.conf
cp ${PREFIX}/etc/macports/variants.conf.default ${PREFIX}/etc/macports/variants.conf

echo 'buildfromsource always' | tee -a ${PREFIX}/etc/macports/macports.conf
echo 'startupitem_type none' | tee -a ${PREFIX}/etc/macports/macports.conf
echo 'startupitem_install no' | tee -a ${PREFIX}/etc/macports/macports.conf
echo 'startupitem_autostart no' | tee -a ${PREFIX}/etc/macports/macports.conf
if [ "$build_arm64" = true ]; then
  echo 'macosx_deployment_target 11.0' | tee -a ${PREFIX}/etc/macports/macports.conf
  echo 'macosx_sdk_version 11.3' | tee -a ${PREFIX}/etc/macports/macports.conf
else
  echo "macosx_deployment_target ${DEPLOYMENT_TARGET_X86_64}" | tee -a ${PREFIX}/etc/macports/macports.conf
  echo "macosx_sdk_version ${SDK_VERSION_X86_64}" | tee -a ${PREFIX}/etc/macports/macports.conf
  echo "build_arch x86_64" | tee -a ${PREFIX}/etc/macports/macports.conf
fi
echo "-x11 +no_x11 +quartz -python27 +no_gnome -gnome -gfortran -openldap -pinentry_mac ${debug}" | tee -a ${PREFIX}/etc/macports/variants.conf
printf "file://${PROJECT_DIR}/ports\n$(cat ${PREFIX}/etc/macports/sources.conf.default)\n" | tee ${PREFIX}/etc/macports/sources.conf

echo "*** Setup ${SDK_VERSION} SDK"
cd /Library/Developer/CommandLineTools/SDKs
if [ ! -d "MacOSX${SDK_VERSION}.sdk" ]; then
  sudo curl -L "https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX${SDK_VERSION}.sdk.tar.xz" | sudo tar -xzf -
fi
if [ -L "MacOSX${SDK_MAJOR_VERSION}.sdk" ]; then
  sudo rm "MacOSX${SDK_MAJOR_VERSION}.sdk"
fi
sudo ln -s "MacOSX${SDK_VERSION}.sdk" "MacOSX${SDK_MAJOR_VERSION}.sdk"

echo "export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX${SDK_VERSION_X86_64}.sdk" >>~/.profile-gimp${VGIMP}-${arch}
echo "export MACOSX_DEPLOYMENT_TARGET=${DEPLOYMENT_TARGET}" >>~/.profile-gimp${VGIMP}-${arch}
if [ "$build_arm64" = true ]; then
  echo 'export GIMP_ARM64=true' >>~/.profile-gimp${VGIMP}-${arch}
fi

source ~/.profile-gimp${VGIMP}-${arch}

if [ -n "$FIRST_INSTALL" ]; then
  # must do before and after otherwise local portindex fails if this is the first time
  port -v selfupdate || true
fi

pushd ${PROJECT_DIR}/ports
portindex
popd

port -v selfupdate || true
