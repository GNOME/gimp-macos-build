#!/usr/bin/env bash
#####################################################################
 # macports_install.sh: installs macports                           #
 #                                                                  #
 # Copyright 2022 Lukas Oberhuber <lukaso@gmail.com>                #
 #                                                                  #
 # This program is free software; you can redistribute it and/or    #
 # modify it under the terms of the GNU General Public License as   #
 # published by the Free Software Foundation; either version 2 of   #
 # the License, or (at your option) any later version.              #
 #                                                                  #
 # This program is distributed in the hope that it will be useful,  #
 # but WITHOUT ANY WARRANTY; without even the implied warranty of   #
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the    #
 # GNU General Public License for more details.                     #
 #                                                                  #
 # You should have received a copy of the GNU General Public License#
 # along with this program; if not, contact:                        #
 #                                                                  #
 # Free Software Foundation           Voice:  +1-617-542-5942       #
 # 51 Franklin Street, Fifth Floor    Fax:    +1-617-542-2652       #
 # Boston, MA  02110-1301,  USA       gnu@gnu.org                   #
 ####################################################################

set -e;

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

if [[ $(uname -m) == 'arm64' ]]; then
  build_arm64=true
  echo "*** Build: arm64"
else
  build_arm64=false
  echo "*** Build: x86_64"
fi

function pure_version() {
	echo '0.1'
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
		shift;;
	--homedirgimp2)
		homedirgimp2="true"
		shift;;
	--homedirgimp3)
		homedirgimp3="true"
		shift;;
	-h | --help)
		usage;;
	--version)
		version; exit 0;;
	-*)
		echo "Unknown option $1. Run with --help for help."
		exit 1;;
	esac
done

if [ -n "$homedirgimp2" ]; then
  echo "**Installing MacPorts in home dir macports-gimp2"
  home_dir=true
  PREFIX=$HOME/macports-gimp2
elif [ -n "$homedirgimp3" ]; then
  echo "**Installing MacPorts in home dir macports-gimp3"
  home_dir=true
  PREFIX=$HOME/macports-gimp3
else
  PREFIX=/opt/local
  dosudo=sudo
fi

export PATH=$PREFIX/bin:$PATH
echo "export PREFIX=$PREFIX" > ~/.profile
echo "export dosudo=$dosudo" >> ~/.profile

if [ -n "$circleci" ]; then
  echo "**Installing MacPorts for CircleCI"
  echo "export circleci=\"true\"" >> ~/.profile
fi

if ! which port &> /dev/null; then
  echo "**install MacPorts"

  MACPORTS_INSTALLER=$HOME/macports_installer

  mkdir -p $MACPORTS_INSTALLER
  pushd $MACPORTS_INSTALLER

  if [ -z ${home_dir+x} ]; then
    curl -L -O https://github.com/macports/macports-base/releases/download/v2.8.0/MacPorts-2.8.0-12-Monterey.pkg
    sudo installer -pkg MacPorts-2.8.0-12-Monterey.pkg -target /
  else
    curl -L -O https://github.com/macports/macports-base/releases/download/v2.8.0/MacPorts-2.8.0.tar.bz2
    tar xf MacPorts-2.8.0.tar.bz2
    pushd MacPorts-2.8.0
    ./configure --prefix=$PREFIX --with-applications-dir=$PREFIX/Applications --without-startupitems --with-install-user=${USER} --with-install-group=staff
    make
    make install
    popd
  fi

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

$dosudo cp ${PREFIX}/etc/macports/macports.conf.default ${PREFIX}/etc/macports/macports.conf
$dosudo cp ${PREFIX}/etc/macports/variants.conf.default ${PREFIX}/etc/macports/variants.conf

echo 'buildfromsource always' | $dosudo tee -a ${PREFIX}/etc/macports/macports.conf
if [ "$build_arm64" = true ] ; then
  echo 'macosx_deployment_target 11.0' | $dosudo tee -a ${PREFIX}/etc/macports/macports.conf
  echo 'macosx_sdk_version 11.3' | $dosudo tee -a ${PREFIX}/etc/macports/macports.conf
else
  echo 'macosx_deployment_target 10.12' | $dosudo tee -a ${PREFIX}/etc/macports/macports.conf
  echo 'macosx_sdk_version 10.12' | $dosudo tee -a ${PREFIX}/etc/macports/macports.conf
fi
echo "-x11 +no_x11 +quartz +python27 +no_gnome -gnome -gfortran ${debug}" | $dosudo tee -a ${PREFIX}/etc/macports/variants.conf
printf "file://${PROJECT_DIR}/ports\n$(cat ${PREFIX}/etc/macports/sources.conf.default)\n" | $dosudo tee ${PREFIX}/etc/macports/sources.conf

if [ "$build_arm64" = true ] ; then
    echo "*** Setup 11.3 SDK"
    cd /Library/Developer/CommandLineTools/SDKs
    if [ ! -d "MacOSX11.3.sdk" ]
    then
        sudo curl -L 'https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz' | sudo tar -xzf -
    fi
    echo 'export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX11.3.sdk' >> ~/.profile
    echo 'export MACOSX_DEPLOYMENT_TARGET=11.0' >> ~/.profile
    echo 'export GIMP_ARM64=true' >> ~/.profile
else
    echo "*** Setup 10.12 SDK"
    cd /Library/Developer/CommandLineTools/SDKs
    if [ ! -d "MacOSX10.12.sdk" ]
    then
        sudo curl -L 'https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.12.sdk.tar.xz' | sudo tar -xzf -
    fi
    echo 'export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX10.12.sdk' >> ~/.profile
    echo 'export MACOSX_DEPLOYMENT_TARGET=10.12' >> ~/.profile
fi

source ~/.profile

pushd ~/project/ports
$dosudo portindex
popd

$dosudo port -v selfupdate || true
